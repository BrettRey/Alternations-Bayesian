# Feature Specification (Draft)

This file defines how predictors are measured and derived. Update once a corpus and parsing pipeline are chosen.

## Outcome
- `that_overt`: 1 if an overt subordinator *that* appears in a declarative content clause; 0 otherwise.

## Core predictors
- `clause_len_tokens`: token count of the content clause (exclude preceding subordinator).
- `distance_tokens`: tokens from matrix head to clause onset.
- `intervening_len`: tokens between matrix head and clause onset (may equal `distance_tokens` depending on tokenization).
- `surprisal`: average surprisal over a defined span of the clause; specify LM, tokenization, and context window.
  - **Current implementation (v0):** clause-only surprisal computed on the extracted clause string (no sentential context), using Qwen2.5‑1.5B base. This is a placeholder until context-conditioned surprisal is added.

## Grouping variables
- `corpus`, `register`, `doc_id`, `speaker_id`, `head_lemma` for varying effects.

## Notes
- Hold out documents or registers for out-of-sample checks.
- Record derivation scripts and settings alongside outputs in `results/`.
