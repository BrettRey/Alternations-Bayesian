#!/usr/bin/env Rscript

# Ingest OANC raw text files into a document table.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")
raw_dir <- cfg$paths$raw_oanc_dir
out_path <- file.path(cfg$paths$processed_dir, "oanc-docs.rds")

files <- list.files(raw_dir, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE)
files <- files[grepl("/data/", files)]

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
raw_norm <- normalizePath(raw_dir, winslash = "/", mustWork = FALSE)
rel_path <- sub(paste0("^", raw_norm, "/?"), "", path)
register <- ifelse(grepl("/data/", rel_path), sub("^.*?/data/([^/]+)/.*$", "\\1", rel_path), NA_character_)
rel_noext <- tools::file_path_sans_ext(rel_path)
doc_id <- gsub("[^A-Za-z0-9_\\-]+", "_", rel_noext)
text <- vapply(files, read_text, character(1))

out <- data.frame(
  doc_id = doc_id,
  corpus = corpus,
  register = register,
  path = path,
  text = text,
  stringsAsFactors = FALSE
)

saveRDS(out, out_path)
message("Wrote: ", out_path)
