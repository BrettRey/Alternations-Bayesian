# Handoff Instructions: Phase 2 Statistical Refinement

> [!TIP]
> **When Phase 2 is complete**, remove the urgent handoff hooks from `AGENTS.md` and `CLAUDE.md`.

**Context:**
The paper ("When to Say *that*") has been rewritten for a linguistic audience. The core arguments (Consistency, Theoretical Framing) are polished. The next phase focuses on rigorous statistical upgrades to "bulletproof" the claims against methodological critique.

**Pending Tasks (High Impact):**

## 1. Upgrade Model Structure
**Goal:** Make the competence claim harder to dismiss by modelling speakers/documents.
*   **Action:** Add random intercepts for `document_id` (and `speaker_id` where available).
*   **Action:** Allow `lemma` preferences to vary by `register` (interaction term or separate intercepts).
*   **Why:** Quantifies variance at the individual level vs. register level, directly supporting the "knowledge" claim.

## 2. Advanced Validation (Token-Level)
**Goal:** Upgrade "out-of-sample prediction" from coarse rates to token-level metrics.
*   **Action:** Report **log predictive density (ELPD)** on holdout data.
*   **Action:** Report **Brier score** and generate a **calibration plot**.
*   **Action:** Perform **ablation testing** (compare Baseline vs. +Lemma, +Length, etc.) and report $\Delta$ELPD.

## 3. Refine Distance Predictor
**Goal:** Resolve the "weak negative distance" anomaly.
*   **Action:** Create a `parenthetical` indicator (e.g., complement-first order, comma-delimited).
*   **Action:** Re-define `distance` as "intervening material in canonical order" to decouple it from parentheticality.
*   **Hypothesis:** Once parentheticals are controlled, the distance effect should flip positive (supporting the processing story) or the null result becomes robust.

## 4. Replication / Stress Test
**Goal:** Demonstrate "projectibility" across contexts.
*   **Options:**
    *   3-way rotation (Fit on 2 registers, test on 3rd).
    *   Train on written, test on spoken (or vice versa).
    *   Time-based split.

## Current State
*   **Code:** `analysis/` contains the `baseline_that.stan` model.
*   **Data:** `oanc-clauses.rds` is the primary dataset.
*   **Draft:** `paper-rewrite.qmd` is the active manuscript.
*   **Completed:** Visuals (Length/Distance), Consistency Audit, Theoretical Framing.
