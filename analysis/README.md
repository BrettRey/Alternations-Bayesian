# Analysis
R/Stan scripts, preprocessing, and reproducible notebooks live here. Keep runs deterministic (set seeds) and write outputs to `../results/`.

## Pipeline (initial)
1) `Rscript analysis/00_setup.R`
2) `Rscript analysis/00_download_oanc.R`
3) `Rscript analysis/01_ingest_oanc.R`
4) Install spaCy + model, then `Rscript analysis/02_parse_spacy.R`
5) `Rscript analysis/03_extract_clauses.R`
6) (Optional) `Rscript analysis/04_surprisal.R` to select a surprisal model.

## Dependencies
R packages: `yaml`, `arrow`, `spacyr`, `data.table`, `jsonlite`.
Python packages: `spacy`, `transformers`, `torch`.

spaCy model (default): `en_core_web_sm` (set in `analysis/config.yml`).
