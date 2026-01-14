# Solution Sketch: Alternations as Constrained Choice

Source: ChatGPT conversation, 2026-01-14

---

## Core claim

English alternations are competition between constructions whose selection probabilities are part of speakers' grammatical knowledge, learned from usage, shaped by recurrent communicative/processing constraints.

---

## Unified mechanism: cue-based construction competition

### A) Accessibility-first packaging
Put highly accessible material early; defer less accessible material.

Cues: pronominality, givenness/recency, definiteness, animacy/humanness

### B) End-weight / planning pressure
Defer heavy constituents to later positions.

Cues: length, internal branching, dependency length

### C) Information-density management (surprisal smoothing)
Distribute information to avoid local surprisal peaks.

Cues: surprisal of upcoming material

### D) Entrenchment and verb-/frame-specific preferences
Lexically specific histories condition choices.

Cues: lemma-specific effects, semantic class interactions

### E) Register/style as higher-level controller
Register modulates weights and baseline preferences.

Cues: formality, modality, medium, genre

---

## What "solved" looks like

1. Cross-alternation generalization (same cue families predict multiple alternations)
2. Out-of-sample robustness (principled degradation across registers)
3. Experimental confirmability (manipulation of givenness/animacy/weight shifts probabilities)
4. Developmental plausibility (cue-weight trajectories in acquisition)
5. Diachronic coherence (historical change as shifts in cue weights)

---

## Formalization

```
Activation(construction_j) =
  baseline_j(register, variety)
  + Σ w_k * cue_k(context)
  + lexical_adjustment(verb lemma)
  + interaction terms

P(choice) = softmax over competing constructions
```

This is MaxEnt / harmonic grammar / mixed-effects logistic, but with the theoretical commitment that weights are learned grammatical knowledge.

---

## Where functionalist "crack" goes beyond existing practice

- Treat surprisal as first-class cue (not afterthought)
- Treat register as hierarchical moderator of weights
- Treat lexical entrenchment as structured (semantic class x construction)

---

## Cross-alternation predictions

A) Same accessibility cues push parallel directions across alternations
B) Surprisal is common lever for optional function material
C) Register modulates baseline rates and sometimes cue weights
D) Lexical idiosyncrasy compressible via semantic dimensions

---

## Objections handled

1. "Performance not grammar" - stability and generalization make it grammar
2. "Efficiency unfalsifiable" - commit to specific measurable predictors
3. "Construction-specific, no single story" - shared pressures + construction-specific affordances
