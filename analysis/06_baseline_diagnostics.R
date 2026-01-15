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
  param_summary <- fit$summary(c(
    "alpha_reg",
    "beta_len",
    "beta_dist",
    "beta_extrap",
    "sigma_lemma",
    "sigma_len_reg",
    "sigma_dist_reg"
  ))
  write.csv(param_summary, file.path(results_dir, "baseline_param_summary.csv"), row.names = FALSE)

  # Diagnostics
  diag <- fit$diagnostic_summary()
  write.csv(diag, file.path(results_dir, "baseline_diagnostics.csv"), row.names = FALSE)

  # Posterior predictive check (overall + by register for top 5)
  draws <- fit$draws(
    c("alpha_reg", "beta_len", "beta_dist", "beta_extrap", "alpha_lemma", "beta_len_reg", "beta_dist_reg"),
    format = "draws_matrix"
  )

  # Prefer the exact fit sample if available (keeps lemma/register IDs aligned).
  fit_data_path <- file.path(results_dir, "baseline_fit", "baseline_data.rds")
  if (file.exists(fit_data_path)) {
    DT_valid <- data.table::as.data.table(readRDS(fit_data_path))
  } else {
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
  }

  # Build lookup for alpha_lemma and alpha_reg columns
  lemma_cols <- paste0("alpha_lemma[", seq_len(max(DT_valid$lemma_id)), "]")
  reg_cols <- paste0("alpha_reg[", seq_len(max(DT_valid$reg_id)), "]")
  len_reg_cols <- paste0("beta_len_reg[", seq_len(max(DT_valid$reg_id)), "]")
  dist_reg_cols <- paste0("beta_dist_reg[", seq_len(max(DT_valid$reg_id)), "]")

  beta_len <- draws[, "beta_len"]
  beta_dist <- draws[, "beta_dist"]
  beta_extrap <- draws[, "beta_extrap"]
  alpha_lemma <- draws[, lemma_cols, drop = FALSE]
  alpha_reg <- draws[, reg_cols, drop = FALSE]
  beta_len_reg <- draws[, len_reg_cols, drop = FALSE]
  beta_dist_reg <- draws[, dist_reg_cols, drop = FALSE]

  n_draws <- nrow(draws)
  n_obs <- nrow(DT_valid)

  # Overall PPC
  len_mat <- matrix(DT_valid$length_std, nrow = n_draws, ncol = n_obs, byrow = TRUE)
  dist_mat <- matrix(DT_valid$distance_std, nrow = n_draws, ncol = n_obs, byrow = TRUE)
  len_slope <- matrix(beta_len, nrow = n_draws, ncol = n_obs) +
    beta_len_reg[, DT_valid$reg_id, drop = FALSE]
  dist_slope <- matrix(beta_dist, nrow = n_draws, ncol = n_obs) +
    beta_dist_reg[, DT_valid$reg_id, drop = FALSE]
  extrap_mat <- matrix(DT_valid$extraposed, nrow = n_draws, ncol = n_obs, byrow = TRUE)
  eta <- alpha_reg[, DT_valid$reg_id, drop = FALSE] +
    alpha_lemma[, DT_valid$lemma_id, drop = FALSE] +
    (len_slope * len_mat) +
    (dist_slope * dist_mat) +
    (matrix(beta_extrap, nrow = n_draws, ncol = n_obs) * extrap_mat)

  probs <- plogis(eta)
  pred_rate <- rowMeans(probs)
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

  # Document-level PPC (observed vs posterior predictive)
  if ("doc_id" %in% names(DT_valid)) {
    doc_index <- as.integer(factor(DT_valid$doc_id))
    doc_map <- DT_valid[, .(
      doc_id = doc_id[1],
      register = register[1],
      n_tokens = .N,
      obs_rate = mean(that_overt)
    ), by = doc_index][order(doc_index)]

    doc_sizes <- doc_map$n_tokens
    n_docs <- nrow(doc_map)
    doc_rates_pred <- matrix(NA_real_, nrow = n_draws, ncol = n_docs)

    set.seed((cfg$model$seed %||% 123) + 1)
    for (d in seq_len(n_draws)) {
      y_rep <- runif(n_obs) < probs[d, ]
      counts <- rowsum(as.numeric(y_rep), doc_index, reorder = FALSE)
      doc_rates_pred[d, ] <- counts / doc_sizes
    }

    saveRDS(
      list(
        obs = doc_map[, .(doc_id, register, n_tokens, obs_rate)],
        pred = doc_rates_pred,
        doc_map = doc_map[, .(doc_id, register, n_tokens)]
      ),
      file.path(results_dir, "ppc_doc_rates.rds")
    )
  }
}

message("Diagnostics written to results/.")
