# Results
Model fits, posterior draws, and rendered tables/figures live here. Do not edit outputs by hand.

Initial outputs:
- `perplexity.csv`: model comparison for surprisal candidates.
- `baseline_fit/`: CmdStanR fit objects and CSVs for the baseline model, plus the exact fit sample (`baseline_data.rds`).
- `ppc_overall.csv`, `ppc_by_register.csv`: posterior predictive checks on the fit sample.
- `ppc_doc_rates.rds`: document-level PPC data (observed + posterior predictive) on the fit sample.
- `oos_fit/`: out-of-sample fit objects and the train/test data used for holdout evaluation.
- `oos_summary.csv`, `oos_by_register.csv`: document split + basic outcome rates for train/test.
- `oos_ppc_overall.csv`, `oos_ppc_by_register.csv`: out-of-sample PPCs on held-out documents.
- `oos_ppc_doc_rates.rds`: document-level PPC data (observed + posterior predictive) on the held-out set.
- `oos_elpd.csv`: out-of-sample expected log predictive density (ELPD).
