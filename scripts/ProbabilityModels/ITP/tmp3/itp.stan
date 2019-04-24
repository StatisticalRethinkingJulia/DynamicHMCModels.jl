data {
  int N1; // Sample size for both categories
  int N2; // Sample size for both categories
  int T; // Number of times
  int K; // Number end points
  int D; // Number domains
  int domains[D];
  // Dose 1
  matrix[K,T] Y1[N1];
  // Dose 2
  matrix[K,T] Y2[N2];
  row_vector[T] times;

}
transformed data{
  int N = N1 + N2;
  int Tm1 = T-1;
  int ind = 0;
  row_vector[Tm1] delta_times = times[2:T] - times[1:Tm1];
  matrix[K,D] domain_map = rep_matrix(0, K, D);
  for (d in 1:D){
    for (k in 1:domains[d]){
      ind += 1;
      domain_map[ind,d] = 1;
    }
  }
}
parameters {
  real muh[2];
  real<lower=-1,upper=1> rho;
  vector<lower=0>[K] kappa;
  vector[K] theta;
  cholesky_factor_corr[K] L;
  vector[D] muraw[2];
  vector[K] betaraw[2];
  real<lower=0> sigma_beta;
  real<lower=0> sigma_h;
  vector<lower=0>[K] sigma;
}
model {
  real scaledrho = 0.5*rho + 0.5;
  vector[K] mu_beta[2];
  vector[K] beta[2];
  row_vector[Tm1] temp;
  vector[T] temp2;
  row_vector[Tm1] AR_diag;
  row_vector[Tm1] nAR_offdiag;
  matrix[K,T] kappa_time;
  matrix[K,T] delta;
  matrix[K,T] SLdelta;
  matrix[K,Tm1] SLdeltaAR;
  matrix[K,T] itp_expected_value[2];
  matrix[K,K] SL = diag_pre_multiply(sigma, L);

  scaledrho ~ beta(2,2);
  kappa ~ gamma(0.1,0.1);
  sigma ~ gamma(1.5, 0.25);
  theta ~ normal(0, 10);
  L ~ lkj_corr_cholesky(2);
  for (i in 1:2){
    muh[i] ~ normal(0,10);
    muraw[i] ~ normal(0,1);
    betaraw[i] ~ normal(0,1);
    mu_beta[i] = domain_map * (muh[i] + muraw[i] * sigma_h);
    beta[i] = mu_beta[i] + betaraw[i] * sigma_beta;
  }
  sigma_h ~ normal(0, 10);
  sigma_beta ~ normal(0, 10);

  if (rho > 0){ // temp = - sign(rho) * abs(rho)^delta_times
    temp =   exp(delta_times * log(  rho)); 
  } else if (rho == 0) {
    temp = rep_row_vector(0, Tm1);
  } else { // rho < 0
    temp =  - exp(delta_times * log(-rho)); 
  }

  AR_diag = inv_sqrt(1 - temp .* temp);
  nAR_offdiag = AR_diag .* temp;

  kappa_time = expm1(-1 * kappa * times);
  for (i in 1:2){
    itp_expected_value[i] =  rep_matrix(theta, T) - rep_matrix(beta[i], T) .* kappa_time; 
  }
  // covariance logdeterminant
  // AR is the inverse of the cholesky factor of a correlation matrix => +
  // SL is the cholesky factor of a covariance matrix => -
  target += N*(K*sum(log(AR_diag)) - T*log_determinant(SL));

  for (n in 1:N1){
    delta = Y1[n] - itp_expected_value[1];
    SLdelta = mdivide_left_tri_low(SL, delta);
    target += -0.5 * dot_self(SLdelta[:,1]);
    SLdeltaAR = SLdelta[:,2:T] .* rep_matrix(AR_diag, K) - SLdelta[:,1:Tm1] .* rep_matrix(nAR_offdiag, K);
    target += -0.5 * sum(columns_dot_self(SLdeltaAR));
  }
  for (n in 1:N2){
    delta = Y2[n] - itp_expected_value[2];
    SLdelta = mdivide_left_tri_low(SL, delta);
    target += -0.5 * dot_self(SLdelta[:,1]);
    SLdeltaAR = SLdelta[:,2:T] .* rep_matrix(AR_diag, K) - SLdelta[:,1:Tm1] .* rep_matrix(nAR_offdiag, K);
    target += -0.5 * sum(columns_dot_self(SLdeltaAR));
  }
}