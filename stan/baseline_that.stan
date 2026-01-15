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
  real beta_len;
  real beta_dist;
  vector[J_reg] alpha_reg;
  vector[J_lemma] alpha_lemma_raw;
  vector[J_reg] beta_len_reg_raw;
  vector[J_reg] beta_dist_reg_raw;
  real<lower=0> sigma_lemma;
  real<lower=0> sigma_len_reg;
  real<lower=0> sigma_dist_reg;
}

transformed parameters {
  vector[J_lemma] alpha_lemma = sigma_lemma * alpha_lemma_raw;
  vector[J_reg] beta_len_reg = sigma_len_reg * beta_len_reg_raw;
  vector[J_reg] beta_dist_reg = sigma_dist_reg * beta_dist_reg_raw;
}

model {
  alpha_reg ~ normal(0, 1.5);
  beta_len ~ normal(0, 1);
  beta_dist ~ normal(0, 1);
  alpha_lemma_raw ~ normal(0, 1);
  beta_len_reg_raw ~ normal(0, 1);
  beta_dist_reg_raw ~ normal(0, 1);
  sigma_lemma ~ normal(0, 1);
  sigma_len_reg ~ normal(0, 1);
  sigma_dist_reg ~ normal(0, 1);

  y ~ bernoulli_logit(alpha_reg[reg_id] + alpha_lemma[lemma_id]
                      + (beta_len + beta_len_reg[reg_id]) .* length_std
                      + (beta_dist + beta_dist_reg[reg_id]) .* distance_std);
}
