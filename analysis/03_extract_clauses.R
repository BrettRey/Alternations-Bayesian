#!/usr/bin/env Rscript

# Extract content-clause tokens and derive core predictors.

suppressPackageStartupMessages({
  library(yaml)
})

cfg <- yaml::read_yaml("analysis/config.yml")

in_dir <- file.path(cfg$paths$processed_dir, "oanc-tokens")
out_path <- file.path(cfg$paths$processed_dir, "oanc-clauses.parquet")

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required to read parquet. Install it first.")
}
if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required. Install it first.")
}

if (!dir.exists(in_dir)) {
  stop("Missing input dir: ", in_dir, "\nRun analysis/02_parse_spacy.R first.")
}

# Load all token parts (for now; can be optimized later).
tokens <- arrow::open_dataset(in_dir) |> arrow::collect()
DT <- data.table::as.data.table(tokens)

required_cols <- c("doc_id", "sentence_id", "token_id", "head_token_id", "lemma", "pos", "dep_rel")
missing_cols <- setdiff(required_cols, names(DT))
if (length(missing_cols) > 0) {
  stop("Missing columns: ", paste(missing_cols, collapse = ", "))
}

# Helper to compute subtree size for a head token within one sentence.
subtree_size <- function(sent_tokens, head_id) {
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
  length(seen)
}

out_rows <- list()

sent_groups <- split(DT, interaction(DT$doc_id, DT$sentence_id, drop = TRUE))

for (sent in sent_groups) {
  clause_heads <- sent[sent$dep_rel %in% c("ccomp"), ]
  if (nrow(clause_heads) == 0) next

  # Build lookup for head lemmas and POS
  token_idx <- setNames(seq_len(nrow(sent)), sent$token_id)

  for (i in seq_len(nrow(clause_heads))) {
    ch <- clause_heads[i, ]
    matrix_idx <- token_idx[as.character(ch$head_token_id)]
    matrix_lemma <- if (!is.na(matrix_idx)) sent$lemma[matrix_idx] else NA_character_
    matrix_pos <- if (!is.na(matrix_idx)) sent$pos[matrix_idx] else NA_character_

    # Detect overt "that" marker
    has_that <- any(
      sent$head_token_id == ch$token_id &
        sent$dep_rel == "mark" &
        sent$lemma == "that"
    )

    clause_len <- subtree_size(sent, ch$token_id)
    dist <- if (!is.na(ch$head_token_id)) abs(ch$token_id - ch$head_token_id) - 1 else NA_integer_
    dist <- if (!is.na(dist) && dist < 0) 0 else dist

    out_rows[[length(out_rows) + 1]] <- data.frame(
      doc_id = ch$doc_id,
      sent_id = ch$sentence_id,
      corpus = if ("corpus" %in% names(ch)) ch$corpus else NA_character_,
      register = if ("register" %in% names(ch)) ch$register else NA_character_,
      head_lemma = matrix_lemma,
      head_pos = matrix_pos,
      clause_head_token = ch$token_id,
      that_overt = as.integer(has_that),
      clause_len_tokens = clause_len,
      distance_tokens = dist,
      intervening_len = dist,
      stringsAsFactors = FALSE
    )
  }
}

out <- data.table::rbindlist(out_rows, fill = TRUE)

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required to write parquet. Install it first.")
}
arrow::write_parquet(out, out_path)
message("Wrote: ", out_path)
