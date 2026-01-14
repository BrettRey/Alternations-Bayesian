#!/usr/bin/env Rscript

# Compute perplexity for candidate LMs on a sample of OANC documents.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")

in_path <- file.path(cfg$paths$processed_dir, "oanc-docs.parquet")
cache_dir <- "analysis/cache"
if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required to read parquet. Install it first.")
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Install it first.")
}

if (!file.exists(in_path)) {
  stop("Missing input: ", in_path, "\nRun analysis/01_ingest_oanc.R first.")
}

# Sample documents for perplexity evaluation.
docs <- arrow::read_parquet(in_path)
if (nrow(docs) == 0) stop("No documents found in ", in_path)

sample_n <- min(200, nrow(docs))
text_sample <- docs$text[seq_len(sample_n)]
text_sample <- substr(text_sample, 1, 5000)

sample_path <- file.path(cache_dir, "perplexity_sample.txt")
writeLines(text_sample, sample_path, useBytes = TRUE)

results <- list()

for (model_id in cfg$surprisal$model_candidates) {
  out_json <- file.path(cache_dir, paste0(gsub("/", "_", model_id), ".json"))
  cmd <- c(
    "analysis/surprisal.py",
    "--input", sample_path,
    "--model", model_id,
    "--max-tokens", as.character(cfg$surprisal$max_tokens),
    "--stride", as.character(cfg$surprisal$stride),
    "--out", out_json
  )

  status <- system2("python", cmd)
  if (!is.null(status) && status != 0) {
    stop("Perplexity run failed for model: ", model_id)
  }

  results[[model_id]] <- jsonlite::fromJSON(out_json)
}

out <- do.call(rbind, lapply(results, as.data.frame))
write.csv(out, file.path(cfg$paths$results_dir, "perplexity.csv"), row.names = FALSE)
message("Wrote: ", file.path(cfg$paths$results_dir, "perplexity.csv"))
