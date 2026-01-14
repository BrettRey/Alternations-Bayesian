data {
  int<lower=1> N;
  array[N] int<lower=0, upper=1> y;
  vector[N] length_std;
  vector[N] distance_std;
  int<lower=1> J_lemma;
  int<lower=1> J_reg;
  array[N] int<lower=1, upper=J_lemma> lemma_id;
  array[N] int<lower=1, upper=J_reg> reg_id;
}

parameters {
  real alpha;
  real beta_len;
  real beta_dist;
  vector[J_lemma] alpha_lemma_raw;
  vector[J_reg] alpha_reg_raw;
  real<lower=0> sigma_lemma;
  real<lower=0> sigma_reg;
}

transformed parameters {
  vector[J_lemma] alpha_lemma = sigma_lemma * alpha_lemma_raw;
  vector[J_reg] alpha_reg = sigma_reg * alpha_reg_raw;
}

model {
  alpha ~ normal(0, 1);
  beta_len ~ normal(0, 1);
  beta_dist ~ normal(0, 1);
  alpha_lemma_raw ~ normal(0, 1);
  alpha_reg_raw ~ normal(0, 1);
  sigma_lemma ~ normal(0, 1);
  sigma_reg ~ normal(0, 1);

  y ~ bernoulli_logit(alpha + alpha_lemma[lemma_id] + alpha_reg[reg_id]
                      + beta_len * length_std + beta_dist * distance_std);
}
