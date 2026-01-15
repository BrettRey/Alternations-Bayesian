#!/usr/bin/env Rscript

# Out-of-sample evaluation with document-level holdout.

suppressPackageStartupMessages({
  library(yaml)
})

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required. Install it first.")
}

if (!requireNamespace("cmdstanr", quietly = TRUE)) {
  install.packages(
    "cmdstanr",
    repos = c("https://mc-stan.org/r-packages/", getOption("repos"))
  )
}

library(cmdstanr)

if (is.null(cmdstanr::cmdstan_version(error_on_NA = FALSE))) {
  message("CmdStan not found; installing...")
  cmdstanr::install_cmdstan()
}

cfg <- yaml::read_yaml("analysis/config.yml")
`%||%` <- function(x, y) if (is.null(x)) y else x

set.seed(cfg$model$seed %||% 123)

in_path <- file.path(cfg$paths$processed_dir, "oanc-clauses.rds")
if (!file.exists(in_path)) {
  stop("Missing input: ", in_path, "\nRun analysis/03_extract_clauses.R first.")
}

DT <- data.table::as.data.table(readRDS(in_path))
DT <- DT[!is.na(that_overt) & !is.na(head_lemma) & !is.na(register) &
           !is.na(clause_len_tokens) & !is.na(distance_tokens) & !is.na(doc_id)]
if (!"extraposed" %in% names(DT)) {
  stop("Missing extraposition flag. Run analysis/03b_add_extraposition.R first.")
}

if (nrow(DT) == 0) {
  stop("No valid tokens after filtering; cannot run out-of-sample evaluation.")
}

# Resolve document-level register (use most frequent label if needed).
doc_reg <- DT[, .N, by = .(doc_id, register)]
doc_reg <- doc_reg[order(-N)]
doc_reg <- doc_reg[, .SD[1], by = doc_id]

holdout_frac <- cfg$model$oos_doc_holdout_frac %||% 0.2
if (holdout_frac <= 0 || holdout_frac >= 1) {
  stop("model.oos_doc_holdout_frac must be in (0, 1).")
}

# Stratified document split by register.
test_docs <- doc_reg[, {
  docs <- doc_id
  n_test <- max(1, floor(length(docs) * holdout_frac))
  list(doc_id = sample(docs, n_test))
}, by = register]$doc_id

train_docs <- setdiff(doc_reg$doc_id, test_docs)

train <- DT[doc_id %in% train_docs]
test <- DT[doc_id %in% test_docs]

# Optional token subsampling for speed.
train_n <- cfg$model$oos_train_n %||% cfg$model$baseline_sample_n %||% 20000
if (nrow(train) > train_n) {
  set.seed(cfg$model$seed %||% 123)
  train <- train[sample(.N, train_n)]
}

test_n <- cfg$model$oos_test_n %||% max(5000, floor(train_n * 0.25))
if (nrow(test) > test_n) {
  set.seed(cfg$model$seed %||% 123)
  test <- test[sample(.N, test_n)]
}

# Standardize using training statistics.
len_mu <- mean(train$clause_len_tokens)
len_sd <- stats::sd(train$clause_len_tokens)
if (is.na(len_sd) || len_sd == 0) len_sd <- 1
dist_mu <- mean(train$distance_tokens)
dist_sd <- stats::sd(train$distance_tokens)
if (is.na(dist_sd) || dist_sd == 0) dist_sd <- 1

train[, length_std := (clause_len_tokens - len_mu) / len_sd]
train[, distance_std := (distance_tokens - dist_mu) / dist_sd]
test[, length_std := (clause_len_tokens - len_mu) / len_sd]
test[, distance_std := (distance_tokens - dist_mu) / dist_sd]

# Factor levels from training set.
lemma_levels <- sort(unique(train$head_lemma))
reg_levels <- sort(unique(train$register))

train[, lemma_id := match(head_lemma, lemma_levels)]
train[, reg_id := match(register, reg_levels)]
test[, lemma_id := match(head_lemma, lemma_levels)]
test[, reg_id := match(register, reg_levels)]

dropped_lemma <- sum(is.na(test$lemma_id))
dropped_reg <- sum(is.na(test$reg_id))
test <- test[!is.na(lemma_id) & !is.na(reg_id)]

results_dir <- cfg$paths$results_dir
fit_dir <- file.path(results_dir, "oos_fit")
if (!dir.exists(fit_dir)) dir.create(fit_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  data.table::data.table(
    doc_id = doc_reg$doc_id,
    register = doc_reg$register,
    split = ifelse(doc_reg$doc_id %in% test_docs, "test", "train")
  ),
  file.path(fit_dir, "oos_doc_split.csv"),
  row.names = FALSE
)

saveRDS(train, file.path(fit_dir, "oos_train_data.rds"))
saveRDS(test, file.path(fit_dir, "oos_test_data.rds"))

summary <- data.table::data.table(
  n_docs_total = nrow(doc_reg),
  n_docs_train = length(unique(train_docs)),
  n_docs_test = length(unique(test_docs)),
  n_tokens_train = nrow(train),
  n_tokens_test = nrow(test),
  dropped_test_lemmas = dropped_lemma,
  dropped_test_registers = dropped_reg
)
write.csv(summary, file.path(results_dir, "oos_summary.csv"), row.names = FALSE)

by_reg <- data.table::rbindlist(list(
  train[, .(n = .N, that_rate = mean(that_overt)), by = register][, split := "train"],
  test[, .(n = .N, that_rate = mean(that_overt)), by = register][, split := "test"]
))
write.csv(by_reg, file.path(results_dir, "oos_by_register.csv"), row.names = FALSE)

stan_data <- list(
  N = nrow(train),
  y = as.integer(train$that_overt),
  length_std = train$length_std,
  distance_std = train$distance_std,
  extraposed = as.numeric(train$extraposed),
  J_lemma = length(lemma_levels),
  J_reg = length(reg_levels),
  lemma_id = train$lemma_id,
  reg_id = train$reg_id
)

model_path <- "stan/baseline_that.stan"
mod <- cmdstanr::cmdstan_model(model_path)
fit <- mod$sample(
  data = stan_data,
  chains = 2,
  parallel_chains = 2,
  iter_warmup = cfg$model$oos_iter_warmup %||% 500,
  iter_sampling = cfg$model$oos_iter_sampling %||% 500,
  adapt_delta = cfg$model$oos_adapt_delta %||% 0.95,
  refresh = 100
)

fit$save_object(file.path(fit_dir, "oos_fit.rds"))
csv_dir <- file.path(fit_dir, "csv")
if (!dir.exists(csv_dir)) dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(fit$output_files(), csv_dir, overwrite = TRUE)

draws <- fit$draws(
  c("alpha_reg", "beta_len", "beta_dist", "beta_extrap", "alpha_lemma", "beta_len_reg", "beta_dist_reg"),
  format = "draws_matrix"
)

lemma_cols <- paste0("alpha_lemma[", seq_len(max(train$lemma_id)), "]")
reg_cols <- paste0("alpha_reg[", seq_len(max(train$reg_id)), "]")
len_reg_cols <- paste0("beta_len_reg[", seq_len(max(train$reg_id)), "]")
dist_reg_cols <- paste0("beta_dist_reg[", seq_len(max(train$reg_id)), "]")

alpha_reg <- draws[, reg_cols, drop = FALSE]
alpha_lemma <- draws[, lemma_cols, drop = FALSE]
beta_len <- draws[, "beta_len"]
beta_dist <- draws[, "beta_dist"]
beta_extrap <- draws[, "beta_extrap"]
beta_len_reg <- draws[, len_reg_cols, drop = FALSE]
beta_dist_reg <- draws[, dist_reg_cols, drop = FALSE]

n_draws <- nrow(draws)
n_test <- nrow(test)

len_mat <- matrix(test$length_std, nrow = n_draws, ncol = n_test, byrow = TRUE)
dist_mat <- matrix(test$distance_std, nrow = n_draws, ncol = n_test, byrow = TRUE)
len_slope <- matrix(beta_len, nrow = n_draws, ncol = n_test) +
  beta_len_reg[, test$reg_id, drop = FALSE]
dist_slope <- matrix(beta_dist, nrow = n_draws, ncol = n_test) +
  beta_dist_reg[, test$reg_id, drop = FALSE]

extrap_mat <- matrix(test$extraposed, nrow = n_draws, ncol = n_test, byrow = TRUE)
eta <- alpha_reg[, test$reg_id, drop = FALSE] +
  alpha_lemma[, test$lemma_id, drop = FALSE] +
  (len_slope * len_mat) +
  (dist_slope * dist_mat) +
  (matrix(beta_extrap, nrow = n_draws, ncol = n_test) * extrap_mat)

probs <- plogis(eta)

# OOS PPC: overall + by register.
ppc_overall <- data.table::data.table(
  draw = seq_len(n_draws),
  pred_rate = rowMeans(probs),
  obs_rate = mean(test$that_overt)
)
write.csv(ppc_overall, file.path(results_dir, "oos_ppc_overall.csv"), row.names = FALSE)

regs <- sort(unique(test$register))
ppc_by_reg <- list()
for (reg in regs) {
  idx <- which(test$register == reg)
  if (length(idx) == 0) next
  ppc_by_reg[[reg]] <- data.table::data.table(
    register = reg,
    draw = seq_len(n_draws),
    pred_rate = rowMeans(probs[, idx, drop = FALSE]),
    obs_rate = mean(test$that_overt[idx])
  )
}
if (length(ppc_by_reg) > 0) {
  ppc_by_reg <- data.table::rbindlist(ppc_by_reg)
  write.csv(ppc_by_reg, file.path(results_dir, "oos_ppc_by_register.csv"), row.names = FALSE)
}

# Document-level PPC (observed vs posterior predictive) on test set.
if ("doc_id" %in% names(test)) {
  doc_index <- as.integer(factor(test$doc_id))
  doc_map <- test[, .(
    doc_id = doc_id[1],
    register = register[1],
    n_tokens = .N,
    obs_rate = mean(that_overt)
  ), by = doc_index][order(doc_index)]

  doc_sizes <- doc_map$n_tokens
  n_docs <- nrow(doc_map)
  doc_rates_pred <- matrix(NA_real_, nrow = n_draws, ncol = n_docs)

  set.seed((cfg$model$seed %||% 123) + 2)
  for (d in seq_len(n_draws)) {
    y_rep <- runif(n_test) < probs[d, ]
    counts <- rowsum(as.numeric(y_rep), doc_index, reorder = FALSE)
    doc_rates_pred[d, ] <- counts / doc_sizes
  }

  saveRDS(
    list(
      obs = doc_map[, .(doc_id, register, n_tokens, obs_rate)],
      pred = doc_rates_pred,
      doc_map = doc_map[, .(doc_id, register, n_tokens)]
    ),
    file.path(results_dir, "oos_ppc_doc_rates.rds")
  )
}

# Out-of-sample log predictive density.
probs <- pmin(pmax(probs, 1e-9), 1 - 1e-9)
y <- test$that_overt
log_lik <- y * log(probs) + (1 - y) * log1p(-probs)

log_mean_exp <- function(x) {
  m <- max(x)
  m + log(mean(exp(x - m)))
}

lpd <- apply(log_lik, 2, log_mean_exp)
elpd_sum <- sum(lpd)
elpd_mean <- mean(lpd)

elpd <- data.table::data.table(
  n_test = n_test,
  elpd_sum = elpd_sum,
  elpd_mean = elpd_mean,
  n_draws = n_draws,
  dropped_test_lemmas = dropped_lemma,
  dropped_test_registers = dropped_reg
)
write.csv(elpd, file.path(results_dir, "oos_elpd.csv"), row.names = FALSE)

message("Out-of-sample evaluation written to results/.")
