# Repository Guidelines

## Project Structure & Module Organization
This repository contains planning/spec documents and a Quarto manuscript in the repo root:
- `STATUS.md` — current phase, next steps, and open questions.
- `solution-sketch.md` — conceptual mechanism and predictions.
- `cgel-gelman-model.md` — model specification and workflow.
- `CLAUDE.md` — project commitments and house style notes.
- `paper.qmd` — manuscript draft (Quarto).
- `_quarto.yml` — Quarto project settings.

There are no `src/` or `tests/` directories yet. If you add code or data, use top-level folders such as `analysis/`, `stan/`, `data/`, and `results/`, and document them here.

## Build, Test, and Development Commands
- `quarto preview` — live preview of `paper.qmd` with auto-refresh.
- `quarto render` — render the project to HTML using `_quarto.yml`.
- `quarto render paper.qmd --to pdf` — render a PDF (requires LaTeX).
- R/Stan execution should run through Quarto chunks or dedicated scripts in `analysis/` once added.

## Coding Style & Naming Conventions
- **Terminology:** Use CGEL terms (e.g., “subordinator,” not “complementizer”). See `CLAUDE.md`.
- **Workflow norms:** Follow the Gelman-style Bayesian workflow (prior/posterior predictive checks, out-of-sample validation).
- **Numbers:** Any reported statistics must come from actual output files; do not invent or approximate values.
- **R/Stan style:** 2-space indentation, `snake_case` for objects/parameters, and explicit seeds for simulations.
- **Files:** Use descriptive, lowercase, hyphenated filenames for docs (matches existing files).
- **Typesetting:** Follow the portfolio `.house-style/` conventions referenced in `CLAUDE.md` when LaTeX is introduced.

## Testing Guidelines
No automated test suite yet. Treat model checks as required tests (prior predictive checks, posterior predictive checks, and held-out validation) and document how to run them alongside the analysis code.

## Commit & Pull Request Guidelines
Keep commits small and descriptive (imperative subject lines, ≤72 chars). In commit bodies, note data sources, random seeds, and any generated outputs. For PRs, include a short summary, the commands used (e.g., `quarto render`), and attach or link to key rendered figures or tables.

## Agent-Specific Instructions
Keep the project’s statistical grounding intact: all reported results must be traceable to saved model outputs, and documentation should remain concise and directly tied to the files in this repository.
