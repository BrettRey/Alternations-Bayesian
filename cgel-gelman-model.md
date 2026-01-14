# CGEL-Compatible Gelman-Style Model

Source: ChatGPT conversation, 2026-01-14

---

## CGEL terminology corrections

- **Subordinator** (not "complementizer") for *that* in content clauses
- **Relative constructions** with formal types: *wh*-relatives, *that*-relatives (subordinator), bare relatives (gap)
- Subordination is a constructional relation (function), not invariably signalled by clause-internal structure

CGEL refs:
- Ch 11: Content clauses and reported speech
- Ch 12: Relative constructions and unbounded dependencies

---

## What Gelman would do

1. **Generative model of utterance choices**, not hunt for "significant predictors"
2. **Multilevel early**: partial pooling over lexical heads, speakers/texts, registers/corpora
3. **Expansive model with regularisation** over brittle model selection
4. **Prior predictive simulation** before fitting; **posterior predictive checks** after
5. **MRP logic** if corpus isn't representative sample

---

## Test case: subordinator realization in declarative content clauses

### Outcome
- y = 1: overt subordinator *that*
- y = 0: no overt subordinator

### Data units
Tokens of declarative content clauses functioning as complement (of verbs/adjectives/nouns)

### Predictors

A) **Complexity/weight** of content clause (length, internal complexity)

B) **Intervening material** between matrix predicator and content clause (distance)

C) **Register/medium/genre** (varying intercept, possibly varying slopes)

D) **Lexical head effects** (matrix verb/adjective/noun) - partial pooling + semantic class predictors

E) **Surprisal** of upcoming content clause material

---

## Model form

```
logit(P(y_i = 1)) =
  α
  + α_register[reg_i]
  + α_corpus[corp_i]
  + α_lemma[head_i]
  + (β_length + b_length_by_register[reg_i]) * length_i
  + (β_distance + b_distance_by_lemma[head_i]) * distance_i
  + β_surprisal * surprisal_i
  + interactions
```

Gelman moves:
- Varying intercepts for lexical heads, corpora, registers
- Varying slopes where motivated
- Regularising priors on βs and SDs of varying effects

---

## Workflow

1. **Prior predictive checks**: simulate y under prior; fix if implausible
2. **Fit, then posterior predictive checks** targeted to:
   - Overall overt-*that* rate by register
   - Distribution as function of distance
   - Lemma-to-lemma heterogeneity
   - Interactional patterns
3. **Out-of-sample validation**: hold out whole documents/speakers or entire corpus/register
4. **Poststratification** for population-level claims (MRP)

---

## Extension to relative constructions

Multinomial choice:
- *wh*-relative
- *that*-relative (subordinator)
- bare relative (gap)

Hierarchical multinomial with:
- Shared predictors (accessibility, weight, distance, register)
- Varying intercepts/slopes by head noun, matrix environment
- Structured prior encouraging similarity across alternations

---

## Further refinement

Model discourse predictors (givenness/accessibility) as noisy measurements - explicitly handle annotation uncertainty / coder effects.

---

## Key refs

- CGEL Ch 11, 12
- Gelman et al.: Bayesian Workflow (arXiv:2011.01808)
- Columbia: Bayesian workflow article
- Columbia: MRP paper
- Stan: Posterior predictive checks
