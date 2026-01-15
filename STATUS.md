# STATUS.md - Alternations-Bayesian

## Project State
**Phase**: Initial analysis pipeline
**Last updated**: 2026-01-14

## Goal
Bayesian model of English alternations (subordinator realization as initial test case), CGEL-compatible terminology, Gelman-style workflow.

## Related Projects
- `../Unsolved-problems-linguistics/` - this project tackles problem #1 from that survey

## Current Status
- OANC downloaded and extracted (GrAF release)
- Ingested document table built
- spaCy parsing completed (token shards)
- Clause dataset extracted (ccomp-based first pass)
- Fast-pass surprisal comparison run: Qwen2.5-1.5B outperforms Pythia-1.4B (perplexity)
- Baseline hierarchical model fit completed (CmdStanR)
- Diagnostics + PPC outputs generated in `results/`
- Clause-level surprisal computed on a sampled subset (Qwen2.5‑1.5B, clause-only text)

## Next Steps
1. Review diagnostics and PPC outputs; decide if baseline model needs revisions
2. Add surprisal computation at clause level and refit with surprisal predictor
3. Expand extraction rules beyond `ccomp` as needed (e.g., clause type coverage)
4. Draft manuscript sections for data + baseline results

## Open Questions
- Which corpus/register subsets to hold out for validation?
- How to compute surprisal span for the content clause (full clause vs first N tokens)?
- Should we incorporate additional predictors (e.g., discourse givenness) in v1?

## Session Log

### 2026-01-14
- Project created
- Saved background materials from ChatGPT:
  - Unsolved problems survey (12 problems, solubility ranking)
  - Solution sketch (unified mechanism, predictions)
  - CGEL/Gelman model specification
- OANC pipeline implemented and run
- Baseline model + diagnostics completed
