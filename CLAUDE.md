# CLAUDE.md - Alternations-Bayesian

## Role
Editor / Research collaborator. Deep work welcome in this project.

## Project Overview
A paper attempting to "solve" the most tractable unsolved problem in English linguistics: alternations as constrained choice. Uses subordinator realization (*that* vs bare content clauses) as the initial test case.

## Key Commitments

### Terminological (*CGEL*)
- **Subordinator** not "complementizer"
- **Relative constructions** with *wh*-, *that*-, and bare types
- Subordination is a function, not invariably marked

### Methodological (Gelman)
- Generative model, not significance hunting
- Multilevel/hierarchical from the start
- Prior predictive checks before fitting
- Posterior predictive checks after fitting
- Out-of-sample validation (hold out documents/registers, not random tokens)
- MRP for population-level claims if corpus is unrepresentative

### Theoretical (functionalist)
- Cue-based construction competition
- Accessibility, weight, surprisal, entrenchment, register as the core pressure families
- Probabilistic weights are part of grammatical knowledge

## Related Projects

- `../Unsolved-problems-linguistics/` - Survey of 12 problems (this project tackles #1)

## Files

- `solution-sketch.md` - Unified mechanism, predictions, objections
- `cgel-gelman-model.md` - Specific model for subordinator realization

## House Style
Follow portfolio `.house-style/` for any LaTeX. This project will likely use:
- Quarto (for inline R/Stan code that can't drift)
- Or plain LaTeX with careful numerical verification

## Source Grounding
All statistics from fitted models must come from actual output files. No approximations or "plausible" numbers.
