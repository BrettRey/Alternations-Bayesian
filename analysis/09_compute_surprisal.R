#!/usr/bin/env Rscript

# Compute clause-level surprisal using an open-weight LM (Qwen by default).

suppressPackageStartupMessages({
  library(yaml)
})

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Install it first.")
}
if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required. Install it first.")
}

cfg <- yaml::read_yaml("analysis/config.yml")
`%||%` <- function(x, y) if (is.null(x)) y else x
processed_dir <- cfg$paths$processed_dir
cache_dir <- "analysis/cache"
if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

in_path <- file.path(processed_dir, "oanc-clauses-text.rds")
if (!file.exists(in_path)) {
  stop("Missing input: ", in_path, "\nRun analysis/08_prepare_clause_text.R first.")
}

clauses <- data.table::as.data.table(readRDS(in_path))
clauses <- clauses[!is.na(clause_id) & !is.na(clause_text)]
clauses <- unique(clauses, by = "clause_id")

input_jsonl <- file.path(cache_dir, "clause_text.jsonl")
output_jsonl <- file.path(cache_dir, "clause_surprisal.jsonl")

# Write JSONL input
con <- file(input_jsonl, open = "w", encoding = "UTF-8")
for (i in seq_len(nrow(clauses))) {
  row <- list(clause_id = clauses$clause_id[i], text = clauses$clause_text[i])
  writeLines(jsonlite::toJSON(row, auto_unbox = TRUE), con)
}
close(con)

model_id <- cfg$surprisal$clause_model %||% "Qwen/Qwen2.5-1.5B"
max_tokens <- cfg$surprisal$max_tokens %||% 128
stride <- cfg$surprisal$stride %||% 64

cmd <- c(
  "analysis/clause_surprisal.py",
  "--input", input_jsonl,
  "--output", output_jsonl,
  "--model", model_id,
  "--max-tokens", as.character(max_tokens),
  "--stride", as.character(stride)
)

if (!file.exists(output_jsonl)) {
  status <- system2("python", cmd)
  if (!is.null(status) && status != 0) {
    stop("Surprisal computation failed.")
  }
}

# Merge results back into dataset
surprisal <- jsonlite::stream_in(file(output_jsonl), verbose = FALSE)
surprisal <- data.table::as.data.table(surprisal)
surprisal <- unique(surprisal, by = "clause_id")
DT <- merge(clauses, surprisal, by = "clause_id", all.x = TRUE)

out_path <- file.path(processed_dir, "oanc-clauses-surprisal.rds")
saveRDS(DT, out_path)
message("Wrote: ", out_path)
