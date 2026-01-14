#!/usr/bin/env Rscript

# Parse documents with spaCy and write token tables.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")

in_path <- file.path(cfg$paths$processed_dir, "oanc-docs.parquet")
out_dir <- file.path(cfg$paths$processed_dir, "oanc-tokens")

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required to read parquet. Install it first.")
}
if (!requireNamespace("spacyr", quietly = TRUE)) {
  stop("Package 'spacyr' is required. Install it first.")
}

if (!file.exists(in_path)) {
  stop("Missing input: ", in_path, "\nRun analysis/01_ingest_oanc.R first.")
}

docs <- arrow::read_parquet(in_path)
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
}

spacyr::spacy_initialize(model = cfg$spacy$model)

chunk_size <- cfg$spacy$batch_size
n <- nrow(docs)

for (start in seq(1, n, by = chunk_size)) {
  end <- min(start + chunk_size - 1, n)
  chunk <- docs[start:end, ]
  text_vec <- chunk$text
  names(text_vec) <- chunk$doc_id

  parsed <- spacyr::spacy_parse(
    text_vec,
    lemma = TRUE,
    pos = TRUE,
    tag = TRUE,
    dependency = TRUE,
    entity = FALSE
  )

  parsed$corpus <- chunk$corpus[match(parsed$doc_id, chunk$doc_id)]
  parsed$register <- chunk$register[match(parsed$doc_id, chunk$doc_id)]

  out_file <- file.path(out_dir, sprintf("part-%04d.parquet", start))
  arrow::write_parquet(parsed, out_file)
  message("Wrote: ", out_file)
}

spacyr::spacy_finalize()
