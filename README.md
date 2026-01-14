# Alternations-Bayesian

Bayesian modeling of English alternations as constrained choice, with the initial test case being **subordinator realization** in finite declarative content clauses: overt subordinator *that* vs zero subordinator (CGEL terminology).

## What counts as a token
A token is a **finite declarative content clause** functioning as a complement of a licensing head (verb/adjective/noun). The outcome is whether the subordinator is overt (*that*) or zero. See `analysis/data_dictionary.csv` and `analysis/feature-spec.md` for details.

## Repository map
- `paper.qmd`: manuscript (Quarto)
- `analysis/`: data pipeline + modeling scripts
- `stan/`: Stan programs
- `data/`: raw/processed data locations (not committed)
- `results/`: model outputs (not committed)
- `styles/`: HTML typography
- `STATUS.md`, `solution-sketch.md`, `cgel-gelman-model.md`: project notes

## Quickstart (reproducible)
1) **R environment**
   - `Rscript -e 'install.packages("renv")'`
   - `Rscript -e 'renv::restore()'`

2) **Download + extract OANC**
   - `Rscript analysis/00_setup.R`
   - `Rscript analysis/00_download_oanc.R`

3) **Ingest + parse + extract**
   - `Rscript analysis/01_ingest_oanc.R`
   - `Rscript -e 'spacyr::spacy_install(model = "en_core_web_sm")'`
   - `Rscript analysis/02_parse_spacy.R`
   - `Rscript analysis/03_extract_clauses.R`

4) **(Optional) Surprisal model selection**
   - `python -m pip install -r requirements.txt`
   - `Rscript analysis/04_surprisal.R`

5) **Render manuscript**
   - `quarto render`

## Licenses
- **Text, figures, and manuscript content**: CC-BY 4.0 (see `LICENSE`).
- **Code (analysis/, stan/, scripts)**: MIT (see `LICENSE-CODE`).

## Notes
- Raw/processed data and results are not committed; see `data/README.md` and `results/README.md`.
- The pipeline currently uses spaCy via `spacyr` and produces RDS outputs.
