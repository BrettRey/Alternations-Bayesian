#!/usr/bin/env Rscript

# Ingest OANC raw text files into a document table.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")
raw_dir <- cfg$paths$raw_oanc_dir
out_path <- file.path(cfg$paths$processed_dir, "oanc-docs.parquet")

files <- list.files(raw_dir, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE)

if (length(files) == 0) {
  stop(
    "No .txt files found under ", raw_dir, ".\n",
    "Add OANC text files (or export them as .txt) before running this step."
  )
}

read_text <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  paste(lines, collapse = "\n")
}

corpus <- rep("OANC", length(files))
path <- files
register <- basename(dirname(files))
doc_id <- tools::file_path_sans_ext(basename(files))
text <- vapply(files, read_text, character(1))

out <- data.frame(
  doc_id = doc_id,
  corpus = corpus,
  register = register,
  path = path,
  text = text,
  stringsAsFactors = FALSE
)

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required to write parquet. Install it first.")
}

arrow::write_parquet(out, out_path)
message("Wrote: ", out_path)
