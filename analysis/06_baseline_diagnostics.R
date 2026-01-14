#!/usr/bin/env Rscript

# Summarize dataset + baseline fit diagnostics and save outputs to results/.

suppressPackageStartupMessages({
  library(yaml)
})

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required. Install it first.")
}
if (!requireNamespace("posterior", quietly = TRUE)) {
  stop("Package 'posterior' is required. Install it first.")
}

cfg <- yaml::read_yaml("analysis/config.yml")

processed_dir <- cfg$paths$processed_dir
results_dir <- cfg$paths$results_dir

clauses_path <- file.path(processed_dir, "oanc-clauses.rds")
fit_path <- file.path(results_dir, "baseline_fit", "baseline_fit.rds")

if (!file.exists(clauses_path)) {
  stop("Missing input: ", clauses_path, "\nRun analysis/03_extract_clauses.R first.")
}

if (!dir.exists(results_dir)) {
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

DT <- data.table::as.data.table(readRDS(clauses_path))
DT <- DT[!is.na(that_overt)]

# Data summaries
summary_overall <- data.table::data.table(
  n_tokens = nrow(DT),
  that_rate = mean(DT$that_overt)
)

summary_lengths <- data.table::data.table(
  clause_len_mean = mean(DT$clause_len_tokens, na.rm = TRUE),
  clause_len_median = median(DT$clause_len_tokens, na.rm = TRUE),
  clause_len_p10 = quantile(DT$clause_len_tokens, 0.10, na.rm = TRUE),
  clause_len_p90 = quantile(DT$clause_len_tokens, 0.90, na.rm = TRUE),
  distance_mean = mean(DT$distance_tokens, na.rm = TRUE),
  distance_median = median(DT$distance_tokens, na.rm = TRUE),
  distance_p10 = quantile(DT$distance_tokens, 0.10, na.rm = TRUE),
  distance_p90 = quantile(DT$distance_tokens, 0.90, na.rm = TRUE)
)

summary_register <- DT[!is.na(register), .(
  n = .N,
  that_rate = mean(that_overt)
), by = register][order(-n)]

summary_lemma <- DT[!is.na(head_lemma), .(
  n = .N,
  that_rate = mean(that_overt)
), by = head_lemma][order(-n)]

summary_lemma <- summary_lemma[1:min(.N, 30)]

write.csv(summary_overall, file.path(results_dir, "data_summary_overall.csv"), row.names = FALSE)
write.csv(summary_lengths, file.path(results_dir, "data_summary_lengths.csv"), row.names = FALSE)
write.csv(summary_register, file.path(results_dir, "data_summary_by_register.csv"), row.names = FALSE)
write.csv(summary_lemma, file.path(results_dir, "data_summary_top_lemmas.csv"), row.names = FALSE)

# Fit diagnostics + PPC
if (file.exists(fit_path)) {
  fit <- readRDS(fit_path)

  # Parameter summary
  param_summary <- fit$summary(c("alpha", "beta_len", "beta_dist", "sigma_lemma", "sigma_reg"))
  write.csv(param_summary, file.path(results_dir, "baseline_param_summary.csv"), row.names = FALSE)

  # Diagnostics
  diag <- fit$diagnostic_summary()
  write.csv(diag, file.path(results_dir, "baseline_diagnostics.csv"), row.names = FALSE)

  # Posterior predictive check (overall + by register for top 5)
  draws <- fit$draws(c("alpha", "beta_len", "beta_dist", "alpha_lemma", "alpha_reg"), format = "draws_matrix")

  # Match scaling used in model
  DT_valid <- DT[!is.na(head_lemma) & !is.na(register) &
                   !is.na(clause_len_tokens) & !is.na(distance_tokens)]
  if (nrow(DT_valid) > 5000) {
    set.seed(cfg$model$seed %||% 123)
    DT_valid <- DT_valid[sample(.N, 5000)]
  }

  DT_valid[, length_std := scale(clause_len_tokens)[, 1]]
  DT_valid[, distance_std := scale(distance_tokens)[, 1]]
  DT_valid[, lemma_id := as.integer(factor(head_lemma))]
  DT_valid[, reg_id := as.integer(factor(register))]

  # Build lookup for alpha_lemma and alpha_reg columns
  lemma_cols <- paste0("alpha_lemma[", seq_len(max(DT_valid$lemma_id)), "]")
  reg_cols <- paste0("alpha_reg[", seq_len(max(DT_valid$reg_id)), "]")

  alpha <- draws[, "alpha"]
  beta_len <- draws[, "beta_len"]
  beta_dist <- draws[, "beta_dist"]
  alpha_lemma <- draws[, lemma_cols, drop = FALSE]
  alpha_reg <- draws[, reg_cols, drop = FALSE]

  n_draws <- nrow(draws)

  # Overall PPC
  eta <- matrix(alpha, nrow = n_draws, ncol = nrow(DT_valid)) +
    alpha_lemma[, DT_valid$lemma_id, drop = FALSE] +
    alpha_reg[, DT_valid$reg_id, drop = FALSE] +
    (beta_len %*% t(DT_valid$length_std)) +
    (beta_dist %*% t(DT_valid$distance_std))

  pred_rate <- rowMeans(plogis(eta))
  obs_rate <- mean(DT_valid$that_overt)

  ppc_overall <- data.table::data.table(
    draw = seq_len(n_draws),
    pred_rate = pred_rate,
    obs_rate = obs_rate
  )
  write.csv(ppc_overall, file.path(results_dir, "ppc_overall.csv"), row.names = FALSE)

  # By-register PPC for top 5 registers
  top_regs <- summary_register$register[1:min(5, nrow(summary_register))]
  ppc_by_reg <- list()
  for (reg in top_regs) {
    idx <- which(DT_valid$register == reg)
    if (length(idx) == 0) next
    pred_reg <- rowMeans(plogis(eta[, idx, drop = FALSE]))
    obs_reg <- mean(DT_valid$that_overt[idx])
    ppc_by_reg[[reg]] <- data.table::data.table(
      register = reg,
      draw = seq_len(n_draws),
      pred_rate = pred_reg,
      obs_rate = obs_reg
    )
  }
  if (length(ppc_by_reg) > 0) {
    ppc_by_reg <- data.table::rbindlist(ppc_by_reg)
    write.csv(ppc_by_reg, file.path(results_dir, "ppc_by_register.csv"), row.names = FALSE)
  }
}

message("Diagnostics written to results/.")
