#!/usr/bin/env Rscript

# Basic setup: directories + package checks

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

ensure_dir(cfg$paths$raw_oanc_dir)
ensure_dir(cfg$paths$processed_dir)
ensure_dir(cfg$paths$results_dir)

message("Setup complete.")
