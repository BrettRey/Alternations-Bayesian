#!/usr/bin/env Rscript

# Add extraposition flag to clause dataset.
# Extraposition is detected by presence of expletive 'it' as subject of the
# matrix predicate (nsubj with lemma "it" and head = matrix head).

suppressPackageStartupMessages({
  library(yaml)
  library(data.table)
})

cfg <- yaml::read_yaml("analysis/config.yml")

clauses_path <- file.path(cfg$paths$processed_dir, "oanc-clauses.rds")
tokens_dir <- file.path(cfg$paths$processed_dir, "oanc-tokens")

if (!file.exists(clauses_path)) {
  stop("Missing clauses file: ", clauses_path, "\nRun 03_extract_clauses.R first.")
}

clauses <- readRDS(clauses_path)
message("Loaded ", nrow(clauses), " clause tokens")

# Load all token shards
parts <- list.files(tokens_dir, pattern = "\\.rds$", full.names = TRUE)
tokens_list <- lapply(parts, readRDS)
DT <- rbindlist(tokens_list, fill = TRUE)
message("Loaded ", nrow(DT), " tokens from ", length(parts), " shards")

# For each clause, check if the matrix head has an expletive 'it' subject
# We need: doc_id, sent_id, clause_head_token (which has head_token_id = matrix head)

# First, re-extract matrix head token IDs from original tokens
# The clause_head_token in clauses is the content clause head
# Its head_token_id in the original tokens is the matrix predicate

# Create lookup: for each (doc_id, sent_id, token_id), find head_token_id
setkey(DT, doc_id, sentence_id, token_id)

# Function to check for expletive 'it' subject
has_expl_it <- function(doc, sent, matrix_token_id) {
  sent_tokens <- DT[.(doc, sent)]
  if (nrow(sent_tokens) == 0 || is.na(matrix_token_id)) return(FALSE)
  
  # Find nsubj dependents of the matrix head with lemma "it"
  expl <- sent_tokens[
    head_token_id == matrix_token_id & 
    dep_rel %in% c("nsubj", "expl") & 
    tolower(lemma) == "it"
  ]
  nrow(expl) > 0
}

# We need to get the matrix head token ID for each clause
# This requires looking up the clause head in the original tokens

message("Detecting extraposition (this may take a while)...")

# Build a lookup for clause heads to matrix heads
clause_heads <- unique(clauses[, c("doc_id", "sent_id", "clause_head_token")])
setDT(clause_heads)

# Get matrix head token IDs
matrix_heads <- DT[clause_heads, on = .(doc_id, sentence_id = sent_id, token_id = clause_head_token),
                   .(doc_id, sent_id = sentence_id, clause_head_token = token_id, 
                     matrix_token_id = head_token_id)]

# Now check each for expletive 'it'
matrix_heads[, extraposed := mapply(has_expl_it, doc_id, sent_id, matrix_token_id)]

message("Extraposed clauses detected: ", sum(matrix_heads$extraposed), " / ", nrow(matrix_heads))

# Merge back to clauses
clauses <- merge(clauses, 
                 matrix_heads[, .(doc_id, sent_id, clause_head_token, extraposed)],
                 by = c("doc_id", "sent_id", "clause_head_token"),
                 all.x = TRUE)

clauses[is.na(extraposed), extraposed := FALSE]

# Summary
message("\nExtraposition summary:")
message("  Total clauses: ", nrow(clauses))
message("  Extraposed: ", sum(clauses$extraposed), 
        " (", round(100 * mean(clauses$extraposed), 1), "%)")
message("  Non-extraposed: ", sum(!clauses$extraposed))

message("\nThat-rate by extraposition:")
message("  Extraposed: ", round(mean(clauses$that_overt[clauses$extraposed]), 3))
message("  Non-extraposed: ", round(mean(clauses$that_overt[!clauses$extraposed]), 3))

# Save updated clauses
saveRDS(clauses, clauses_path)
message("\nUpdated: ", clauses_path)
