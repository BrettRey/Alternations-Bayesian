# Repository Guidelines

## Project Structure & Module Organization
Root files:
- `STATUS.md`: project state and next steps.
- `solution-sketch.md`: mechanism and predictions.
- `cgel-gelman-model.md`: model spec and workflow.
- `CLAUDE.md`: commitments and house style reference.
- `paper.qmd`: Quarto manuscript.
- `_quarto.yml`: Quarto project settings.

There are no `src/` or `tests/` dirs yet. If you add code/data, use top-level folders such as `analysis/`, `stan/`, `data/`, and `results/`, and document them here.

## Build, Test, and Development Commands
- `quarto preview`: live preview of `paper.qmd`.
- `quarto render`: render the project to HTML.
- `quarto render paper.qmd --to pdf`: render PDF (requires LaTeX).
- `quarto render paper.qmd --to latex` then `python ../../.house-style/check-style.py paper.tex`: run the house-style linter on the generated LaTeX.
- R/Stan execution should run via Quarto chunks or scripts in `analysis/` once added.

## Coding Style & Naming Conventions
- Use CGEL terminology (e.g., "subordinator," not "complementizer").
- Follow the Gelman-style Bayesian workflow (prior/posterior checks, held-out validation).
- R/Stan: 2-space indentation, `snake_case`, explicit seeds for simulations.
- Use descriptive, lowercase, hyphenated filenames for docs.

## Typography & House Style
House typography lives in `/Users/brettreynolds/Documents/LLM-CLI-projects/.house-style/`:
- `style-guide.md` (human rules), `style-rules.yaml` (machine rules), `preamble.tex` (LaTeX macros), `check-style.py` (linter).

Key conventions to apply in LaTeX/Quarto output:
- Fonts: EB Garamond (text), Charis SIL (IPA).
- Headings: small-caps sections; italic subsections.
- Links: dark maroon.
- Semantic macros: `\term{}`, `\mention{}`, `\mentionh{}`, `\olang{}`, `\enquote{}`.
- Examples: `langsci-gb4e` (no `exe` environment); use en-dashes, not em-dashes.

## Testing Guidelines
No automated test suite yet. Treat model checks as required tests and document how to run them with the analysis code.

## Commit & Pull Request Guidelines
Keep commits small and descriptive (imperative subject lines, <=72 chars). In commit bodies, note data sources, random seeds, and generated outputs. For PRs, include a short summary, the commands used (e.g., `quarto render`), and link/attach key figures or tables.

## Agent-Specific Instructions
All reported statistics must be traceable to saved model outputs; keep documentation concise and grounded in repository files.
