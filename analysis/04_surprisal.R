#!/usr/bin/env Rscript

# Compute perplexity for candidate LMs on a sample of OANC documents.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")

`%||%` <- function(x, y) if (is.null(x)) y else x

in_path <- file.path(cfg$paths$processed_dir, "oanc-docs.rds")
cache_dir <- "analysis/cache"
if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Install it first.")
}

if (!file.exists(in_path)) {
  stop("Missing input: ", in_path, "\nRun analysis/01_ingest_oanc.R first.")
}

# Sample documents for perplexity evaluation.
docs <- readRDS(in_path)
if (nrow(docs) == 0) stop("No documents found in ", in_path)

set.seed(cfg$surprisal$seed %||% 123)
sample_n <- min(cfg$surprisal$sample_n %||% 20, nrow(docs))
max_chars <- cfg$surprisal$max_chars %||% 2000

idx <- sample(seq_len(nrow(docs)), sample_n)
text_sample <- docs$text[idx]
text_sample <- substr(text_sample, 1, max_chars)

sample_path <- file.path(cache_dir, "perplexity_sample.txt")
writeLines(text_sample, sample_path, useBytes = TRUE)

results <- list()

for (model_id in cfg$surprisal$model_candidates) {
  out_json <- file.path(cache_dir, paste0(gsub("/", "_", model_id), ".json"))
  if (!file.exists(out_json)) {
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
      warning("Perplexity run failed for model: ", model_id)
      next
    }
  }

  results[[model_id]] <- jsonlite::fromJSON(out_json)
}

if (length(results) == 0) {
  stop("No perplexity results were generated.")
}

out <- do.call(rbind, lapply(results, as.data.frame))
out$sample_n <- sample_n
out$max_chars <- max_chars
out$max_tokens <- cfg$surprisal$max_tokens
out$stride <- cfg$surprisal$stride
write.csv(out, file.path(cfg$paths$results_dir, "perplexity.csv"), row.names = FALSE)
message("Wrote: ", file.path(cfg$paths$results_dir, "perplexity.csv"))
