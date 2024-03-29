#' Extract Coefficient Values From a ubmsFit Model
#'
#' @param object A \code{ubmsFit} model
#' @param ... Currently ignored
#'
#' @return A vector of coefficient values for all submodels.
#'
#' @importFrom unmarked coef
#' @export
setMethod("coef", "ubmsFit", function(object, ...){
  unlist(lapply(submodel_types(object), function(x){
    s <- summary(object, x)
    out <- s$mean
    names(out) <- paste0(object[x]@type,"[",rownames(s),"]")
    out
  }))
})


#' Plot Residuals For All Submodels in a ubmsFit Model
#'
#' @param x A \code{ubmsFit} model
#' @param y Currently ignored
#' @param ... Currently ignored
#'
#' @return A plot object of class \code{gtable} with one panel per submodel.
#'
#' @importFrom gridExtra grid.arrange
#' @importFrom graphics plot
#' @export
setMethod("plot", "ubmsFit", function(x, ...){
  pl <- lapply(c("state","det"), function(s) plot_residuals(x, s, draws=6))
  grid.arrange(grobs=pl)
})


#' Extract a Submodel from a ubmsFit Model
#'
#' @param x A \code{ubmsFit} model
#' @param i The name of a submodel to extract
#'
#' @return An object of class \code{ubmsSubmodel}.
#'
#' @export
setMethod("[", c("ubmsFit", "character", "missing", "missing"),
  function(x, i){
  x@submodels[i]
})


#' Get Parameter Names From a ubmsFit Model
#'
#' @param x A \code{ubmsFit} model
#'
#' @return A character vector of parameter names.
#'
#' @export
setMethod("names", "ubmsFit", function(x){
  out <- names(x@stanfit)
  out[!grepl("log_lik\\[|lp__", out)]
})


#' Get number of Posterior Samples Stored in a ubmsFit Model
#'
#' @param object A \code{ubmsFit} model
#' @param ... Currently ignored
#'
#' @return An integer representing the number of posterior samples
#'
#' @importFrom rstantools nsamples
#' @export
setMethod("nsamples", "ubmsFit", function(object, ...){
  sum(object@stanfit@sim$n_save - object@stanfit@sim$warmup2)
})

setMethod("show", "ubmsFit", function(object){

  cat("\nCall:\n")
  print(object@call)
  cat("\n")

  for (i in submodel_types(object)){
    to_print <- summary(object, i)[,c(1,3,4,8:10),drop=FALSE]
    keep_row_names <- nrow(to_print) > 1
    names(to_print)[1:2] <- c("Estimate", "SD")
    cat(paste0(object[i]@name, get_link_name(object[i]),":\n"))
    print(to_print, row.names=keep_row_names, digits=3)
    cat("\n")
  }

  cat(paste0("LOOIC: ", round(object@loo$estimates[3,1], 3)))
  cat("\n")
  cat("Runtime:", get_runtime(object))
  cat("\n")
})

get_link_name <- function(submodel){
  switch(submodel@link,
        "plogis" = {" (logit-scale)"},
        "exp" = {" (log-scale)"}
        )
}

#' Extract Summary Statistics from a ubmsFit Model
#'
#' @param object A \code{ubmsFit} model
#' @param submodel Name of submodel to summarize
#' @param ... Currently ignored
#'
#' @return An object of class \code{data.frame} containing summary statistics
#'  for posterior distributions of parameters from the chosen submodel.
#'
#' @importFrom unmarked summary
#' @export
setMethod("summary", "ubmsFit", function(object, submodel, ...){
  sm <- object[submodel]
  out <- rstan::summary(object@stanfit, beta_par(sm))
  out <- as.data.frame(out$summary)
  rownames(out) <- beta_names(sm)

  if(has_random(sm)){
    random <- rstan::summary(object@stanfit, sig_par(sm))
    random <- as.data.frame(random$summary)
    rownames(random) <- sigma_names(sm)
    out <- rbind(out, random)
  }
  if(has_spatial(sm)){
    tau <- rstan::summary(object@stanfit, "tau")
    tau <- as.data.frame(tau$summary)
    rownames(tau) <- "RSR [tau]"
    out <- rbind(out, tau)
  }
  out
})

#' Extract y, the Response Variable, From a ubmsFit Model
#'
#' @param object A \code{ubmsFit} model
#'
#' @return A matrix containing the response variable \code{y}.
#'
#' @importFrom unmarked getY
#' @export
setMethod("getY", "ubmsFit", function(object){
  object@data@y
})


#' Leave-one-out Cross Validation
#'
#' @param x A \code{ubmsFit} model
#' @param ... Currently ignored
#' @param cores Number of cores to use for calculation
#'
#' @return A named list of class \code{loo} with estimates of
#'  the expected log predictive density and other parameters used
#'  for model comparison. See \code{?loo::loo} for more information.
#'
#' @importFrom loo loo
#' @export
setMethod("loo", "ubmsFit", function(x, ..., cores=getOption("mc.cores", 1)){
  loglik <- extract_log_lik(x, merge_chains=FALSE)
  r_eff <- loo::relative_eff(exp(loglik), cores=cores)
  loo::loo(loglik, r_eff=r_eff, cores=cores)
})


#' Widely Applicable Information Criterion (WAIC)
#'
#' @param x A \code{ubmsFit} model
#' @param ... Currently ignored
#'
#' @return An object of class \code{waic} containing an estimate of WAIC and
#'  other parameters useful for model comparison. See \code{?loo::waic} for
#'  more information.
#'
#' @importFrom loo waic
#' @export
setMethod("waic", "ubmsFit", function(x, ...){
  loglik <- extract_log_lik(x)
  loo::waic(loglik)
})


#' Extract Samples From a ubmsFit Model
#'
#' Extract samples from a \code{ubmsFit} model
#'
#' @param object A \code{ubmsFit} object
#' @param pars An optional character vector providing parameter
#'  names of interest. If not specified, all parameters are used
#' @param permuted Logical. If \code{TRUE}, draws are permuted
#'  and merged; if \code{FALSE}, the original order is kept
#' @param inc_warmup Logical. If \code{TRUE}, warmup iterations
#'  are included; if \code{FALSE} they are discarded.
#' @param include Logical. If \code{TRUE} provided parameter names
#'  in \code{pars} are kept; if \code{FALSE} they are excluded.
#'
#' @return If \code{permuted=TRUE}, a list; if \code{permuted=FALSE},
#'  an array.
#'
#' @importFrom rstan extract
#' @export
setMethod("extract", "ubmsFit",
  function(object, pars, permuted=TRUE, inc_warmup=FALSE, include=TRUE){
  rstan::extract(object@stanfit, pars, permuted, inc_warmup, include)
})

#' Markov Chain Traceplots
#'
#' Draws traceplots for chains from a \code{ubmsFit} object
#'
#' @param object A \code{ubmsFit} object
#' @param ... Arguments passed to \code{rstan::traceplot}
#'
#' @return A \code{ggplot} object.
#'
#' @importFrom rstan traceplot
#' @export
setMethod("traceplot", "ubmsFit", function(object, ...){
  rstan::traceplot(object@stanfit, ...)
})

#' Get Model Runtime
#'
#' Get warmup and sampling time from a \code{ubmsFit} object
#'
#' @param object A \code{ubmsFit} object
#' @param ... Arguments passed to \code{rstan::get_elapsed_time}
#'
#' @return A matrix with one row per chain and two columns, containing
#'  the warmup time and sampling time, respectively, in seconds
#'
#' @importFrom rstan get_elapsed_time
#' @export
setMethod("get_elapsed_time", "ubmsFit", function(object, ...){
  rstan::get_elapsed_time(object@stanfit, ...)
})

# Get total model runtime to display in output of show() method
get_runtime <- function(object){
  units <- 'sec'
  chain_time <- get_elapsed_time(object)
  if(was_parallel(object)){
    total_time <- max(apply(chain_time, 1, sum))
  } else {
    total_time <- sum(chain_time)
  }
  if(total_time > 100){
    units <- 'min'
    total_time <- total_time / 60
  }
  if(total_time > 100){
    units <- 'hr'
    total_time <- total_time / 60
  }
  paste(sprintf("%.3f", round(total_time, 3)), units)
}

# Check if chains were run in parallel
was_parallel <- function(object){
  if(!is.null(object@call$cores) && object@call$cores > 1) return(TRUE)
  if(getOption("mc.cores", 1L) > 1) return(TRUE)
  FALSE
}

#' Get Stan Code From Model
#'
#' Get the Stan code used to run a model as a character string
#'
#' @param object A \code{ubmsFit} object
#' @param ... Arguments passed to \code{rstan::get_stancode}
#'
#' @return A character string with the model code
#'
#' @details Pass the result of \code{get_stancode} to \code{cat} to get the
#'  code in a more readable format. Note that the output in most cases
#'  is Stan code that can be used to fit several types of models, and not
#'  all Stan code will be used in all models.
#'
#' @importFrom rstan get_stancode
#'
#' @export
setMethod("get_stancode", "ubmsFit", function(object, ...){
  rstan::get_stancode(object@stanfit, ...)
})

# Re-create inputs
rebuild_inputs <- function(object){
  inps <- build_stan_inputs(object@stanfit@model_name, object@response,
                            object@submodels, loglik_saved(object))
  inps$submodels <- object@submodels
  inps
}
