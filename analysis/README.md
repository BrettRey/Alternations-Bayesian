# Analysis
R/Stan scripts, preprocessing, and reproducible notebooks live here. Keep runs deterministic (set seeds) and write outputs to `../results/`.

## Pipeline (initial)
1) `Rscript analysis/00_setup.R`
2) `Rscript analysis/00_download_oanc.R`
3) `Rscript analysis/01_ingest_oanc.R`
4) Install spaCy + model, then `Rscript analysis/02_parse_spacy.R`
5) `Rscript analysis/03_extract_clauses.R`
6) (Optional) `Rscript analysis/04_surprisal.R` to select a surprisal model.
7) `Rscript analysis/05_fit_baseline.R` to fit a baseline hierarchical model.
8) `Rscript analysis/06_baseline_diagnostics.R` to generate summaries and PPC outputs.
9) `Rscript analysis/08_prepare_clause_text.R` to build clause text for surprisal (sampled).
10) `Rscript analysis/09_compute_surprisal.R` to compute clause-level surprisal on that sample.

## Dependencies
R packages: `yaml`, `spacyr`, `data.table`, `jsonlite`, `cmdstanr`, `posterior`.
Python packages: `spacy`, `transformers`, `torch`.

spaCy model (default): `en_core_web_sm` (set in `analysis/config.yml`).
