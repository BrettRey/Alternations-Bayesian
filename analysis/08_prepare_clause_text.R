#!/usr/bin/env Rscript

# Build clause-level text strings for surprisal computation.

suppressPackageStartupMessages({
  library(yaml)
})

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required. Install it first.")
}

cfg <- yaml::read_yaml("analysis/config.yml")
processed_dir <- cfg$paths$processed_dir

clauses_path <- file.path(processed_dir, "oanc-clauses.rds")
if (!file.exists(clauses_path)) {
  stop("Missing input: ", clauses_path, "\nRun analysis/03_extract_clauses.R first.")
}

clauses <- data.table::as.data.table(readRDS(clauses_path))
clauses <- clauses[!is.na(doc_id) & !is.na(sent_id) & !is.na(clause_head_token)]
clauses[, clause_id := paste(doc_id, sent_id, clause_head_token, sep = "__")]

# Optional sampling to keep runtime manageable.
set.seed(cfg$surprisal$seed %||% 123)
`%||%` <- function(x, y) if (is.null(x)) y else x

sample_n <- cfg$surprisal$clause_sample_n %||% NA_integer_
if (!is.na(sample_n) && nrow(clauses) > sample_n) {
  clauses <- clauses[sample(.N, sample_n)]
}

max_chars <- cfg$surprisal$clause_max_chars %||% 2000

# Index by doc_id + sent_id for fast lookup.
data.table::setkey(clauses, doc_id, sent_id)
target_sents <- unique(clauses[, .(doc_id, sentence_id = sent_id)])
data.table::setkey(target_sents, doc_id, sentence_id)

# Helper: build subtree token ids
subtree_tokens <- function(sent_tokens, head_id) {
  children <- split(sent_tokens$token_id, sent_tokens$head_token_id)
  stack <- head_id
  seen <- integer(0)
  while (length(stack) > 0) {
    node <- stack[[1]]
    stack <- stack[-1]
    if (node %in% seen) next
    seen <- c(seen, node)
    kids <- children[[as.character(node)]]
    if (!is.null(kids)) stack <- c(stack, kids)
  }
  seen
}

fix_spacing <- function(text) {
  text <- gsub(" ([,.;:!?])", "\\1", text)
  text <- gsub(" \\)", ")", text)
  text <- gsub("\\( ", "(", text)
  text <- gsub(" '", "'", text)
  text <- gsub(" n't", "n't", text)
  text
}

parts <- list.files(file.path(processed_dir, "oanc-tokens"), pattern = "\\.rds$", full.names = TRUE)
if (length(parts) == 0) stop("No token shards found.")

out_rows <- list()

for (part in parts) {
  tok <- data.table::as.data.table(readRDS(part))
  if (!"token" %in% names(tok)) {
    stop("Token column not found in shard: ", part)
  }
  tok <- tok[target_sents, on = .(doc_id, sentence_id), nomatch = 0]
  if (nrow(tok) == 0) next

  groups <- split(tok, interaction(tok$doc_id, tok$sentence_id, drop = TRUE))
  for (sent in groups) {
    doc_id <- sent$doc_id[1]
    sent_id <- sent$sentence_id[1]
    subset_clauses <- clauses[.(doc_id, sent_id)]
    if (nrow(subset_clauses) == 0) next

    token_idx <- setNames(seq_len(nrow(sent)), sent$token_id)
    for (i in seq_len(nrow(subset_clauses))) {
      head_id <- subset_clauses$clause_head_token[i]
      if (is.na(head_id) || !as.character(head_id) %in% names(token_idx)) next

      ids <- subtree_tokens(sent, head_id)
      ids <- ids[order(ids)]
      tokens <- sent$token[token_idx[as.character(ids)]]
      clause_text <- paste(tokens, collapse = " ")
      clause_text <- fix_spacing(clause_text)
      clause_text <- substr(clause_text, 1, max_chars)

      out_rows[[length(out_rows) + 1]] <- data.table::data.table(
        clause_id = subset_clauses$clause_id[i],
        doc_id = doc_id,
        sent_id = sent_id,
        clause_head_token = head_id,
        clause_text = clause_text
      )
    }
  }
}

out <- data.table::rbindlist(out_rows, fill = TRUE)

out_path <- file.path(processed_dir, "oanc-clauses-text.rds")
saveRDS(out, out_path)
message("Wrote: ", out_path)
