% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/colext.R
\name{stan_colext}
\alias{stan_colext}
\title{Fit the MacKenzie et al. (2003) Dynamic Occupancy Model}
\usage{
stan_colext(
  psiformula = ~1,
  gammaformula = ~1,
  epsilonformula = ~1,
  pformula = ~1,
  data,
  prior_intercept_psi = logistic(0, 1),
  prior_coef_psi = logistic(0, 1),
  prior_intercept_gamma = logistic(0, 1),
  prior_coef_gamma = logistic(0, 1),
  prior_intercept_eps = logistic(0, 1),
  prior_coef_eps = logistic(0, 1),
  prior_intercept_det = logistic(0, 1),
  prior_coef_det = logistic(0, 1),
  prior_sigma = gamma(1, 1),
  log_lik = TRUE,
  ...
)
}
\arguments{
\item{psiformula}{Right-hand sided formula for the initial probability of
occupancy at each site}

\item{gammaformula}{Right-hand sided formula for colonization probability}

\item{epsilonformula}{Right-hand sided formula for extinction probability}

\item{pformula}{Right-hand sided formula for detection probability}

\item{data}{A \code{\link[unmarked]{unmarkedMultFrame}} object}

\item{prior_intercept_psi}{Prior distribution for the intercept of the
psi (initial occupancy probability) model; see \code{?priors} for options}

\item{prior_coef_psi}{Prior distribution for the regression coefficients of
the psi model}

\item{prior_intercept_gamma}{Prior distribution on intercept for
colonization probability}

\item{prior_coef_gamma}{Prior distribution on regression coefficients for
colonization probability}

\item{prior_intercept_eps}{Prior distribution on intercept for
extinction probability}

\item{prior_coef_eps}{Prior distribution on regression coefficients for
extinction probability}

\item{prior_intercept_det}{Prior distribution for the intercept of the
detection probability model}

\item{prior_coef_det}{Prior distribution for the regression coefficients of
the detection model}

\item{prior_sigma}{Prior distribution on random effect standard deviations}

\item{log_lik}{If \code{TRUE}, Stan will save pointwise log-likelihood values
in the output. This can greatly increase the size of the model. If
\code{FALSE}, the values are calculated post-hoc from the posteriors}

\item{...}{Arguments passed to the \code{\link[rstan]{stan}} call, such as
number of chains \code{chains} or iterations \code{iter}}
}
\value{
\code{ubmsFitColext} object describing the model fit.
}
\description{
This function fits the dynamic occupancy model of
MacKenzie et al. (2003).
}
\examples{
\donttest{
data(frogs)
umf <- formatMult(masspcru)
umf@y[umf@y > 1] <- 1 #convert counts to presence/absence
umf <- umf[1:100,] #Use only 100 sites

fit_frog <- stan_colext(~1, ~1, ~1, ~1, umf, chains=3, iter=300)
}

}
\references{
MacKenzie DI, Nicholas JD, Hines JE, Knutson MG, Franklin AB.
            2003. Ecology 84: 2200-2207.
}
\seealso{
\code{\link[unmarked]{colext}}, \code{\link[unmarked]{unmarkedMultFrame}}
}
