# Analysis
R/Stan scripts, preprocessing, and reproducible notebooks live here. Keep runs deterministic (set seeds) and write outputs to `../results/`.

## Pipeline (initial)
1) `Rscript analysis/00_setup.R`
2) `Rscript analysis/00_download_oanc.R`
3) `Rscript analysis/01_ingest_oanc.R`
4) Install spaCy + model, then `Rscript analysis/02_parse_spacy.R`
5) `Rscript analysis/03_extract_clauses.R`
6) (Optional) `Rscript analysis/04_surprisal.R` to select a surprisal model.
7) `Rscript analysis/05_fit_baseline.R` to fit a baseline model (lemma partial pooling, register-specific intercepts, register-varying slopes). Saves the exact fit sample to `results/baseline_fit/baseline_data.rds`.
8) `Rscript analysis/06_baseline_diagnostics.R` to generate summaries and PPC outputs.
9) `Rscript analysis/08_prepare_clause_text.R` to build clause text for surprisal (sampled).
10) `Rscript analysis/09_compute_surprisal.R` to compute clause-level surprisal on that sample.
11) `Rscript analysis/10_out_of_sample.R` to run document-level holdout, refit the baseline model, and report out-of-sample PPC + ELPD.

## Gelman-style workflow checklist
- Define the token and exclusion rules explicitly (see `analysis/data_dictionary.csv`).
- Standardize continuous predictors before fitting.
- Choose weakly informative priors and run prior predictive checks.
- Fit a baseline multilevel model with lemma partial pooling and register-specific effects.
- Run posterior predictive checks targeted to claims (overall, by register, by lemma).
- Hold out whole documents or registers for validation (not random tokens).
- Expand the model only if predictive performance or interpretability improves.
- Record model versions and outputs in `results/`.

## Dependencies
R packages: `yaml`, `spacyr`, `data.table`, `jsonlite`, `cmdstanr`, `posterior`.
Python packages: `spacy`, `transformers`, `torch`.

spaCy model (default): `en_core_web_sm` (set in `analysis/config.yml`).
