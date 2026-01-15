#!/usr/bin/env Rscript

# Fit a baseline multilevel logistic model with CmdStanR.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")

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

in_path <- file.path(cfg$paths$processed_dir, "oanc-clauses.rds")
if (!file.exists(in_path)) {
  stop("Missing input: ", in_path, "\nRun analysis/03_extract_clauses.R first.")
}

`%||%` <- function(x, y) if (is.null(x)) y else x
set.seed(cfg$model$seed %||% 123)

DT <- data.table::as.data.table(readRDS(in_path))
DT <- DT[!is.na(that_overt) & !is.na(head_lemma) & !is.na(register)]
DT <- DT[!is.na(clause_len_tokens) & !is.na(distance_tokens)]
if (!"extraposed" %in% names(DT)) {
  stop("Missing extraposition flag. Run analysis/03b_add_extraposition.R first.")
}

sample_n <- cfg$model$baseline_sample_n %||% 20000
if (nrow(DT) > sample_n) {
  DT <- DT[sample(.N, sample_n)]
}

DT[, length_std := scale(clause_len_tokens)[, 1]]
DT[, distance_std := scale(distance_tokens)[, 1]]

DT[, lemma_id := as.integer(factor(head_lemma))]
DT[, reg_id := as.integer(factor(register))]

fit_dir <- file.path(cfg$paths$results_dir, "baseline_fit")
if (!dir.exists(fit_dir)) dir.create(fit_dir, recursive = TRUE, showWarnings = FALSE)
saveRDS(DT, file.path(fit_dir, "baseline_data.rds"))

stan_data <- list(
  N = nrow(DT),
  y = as.integer(DT$that_overt),
  length_std = DT$length_std,
  distance_std = DT$distance_std,
  extraposed = as.numeric(DT$extraposed),
  J_lemma = max(DT$lemma_id),
  J_reg = max(DT$reg_id),
  lemma_id = DT$lemma_id,
  reg_id = DT$reg_id
)

model_path <- "stan/baseline_that.stan"

mod <- cmdstanr::cmdstan_model(model_path)
fit <- mod$sample(
  data = stan_data,
  chains = 2,
  parallel_chains = 2,
  iter_warmup = 500,
  iter_sampling = 500,
  adapt_delta = 0.95,
  refresh = 100
)

fit$save_object(file.path(fit_dir, "baseline_fit.rds"))
csv_dir <- file.path(fit_dir, "csv")
if (!dir.exists(csv_dir)) dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(fit$output_files(), csv_dir, overwrite = TRUE)
message("Baseline fit saved to: ", fit_dir)
