
therMizerOptions <- function(params) {
  opts <- other_params(params)$therMizer
  if (is.null(opts)) {
    return(list(aerobic_effect = TRUE, metabolism_effect = TRUE))
  }
  list(
    aerobic_effect = isTRUE(opts$aerobic_effect),
    metabolism_effect = isTRUE(opts$metabolism_effect)
  )
}

withTherMizerSearchVolume <- function(params, t) {
  params@search_vol <- params@search_vol * scaled_temp_effect(params, t)
  params
}

withTherMizerMetabolism <- function(params, t) {
  params@metab <- params@metab * thermizer_metabolism_effect(params, t)
  params
}

thermizer_metabolism_effect <- function(params, t) {
  # checking that t is within ocean_temp, cycling through otherwise
  if(!floor(t) %in% as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]))
    t <- t %% as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][dim(
      other_params(params)$ocean_temp)[[1]]]) +
      as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][1])

  temp_effect_metab_realms <- array(NA, dim = c(dim(other_params(params)$vertical_migration)), dimnames = c(dimnames(other_params(params)$vertical_migration)))

  # Using t+1 to avoid calling ocean_temp[0,] at the first time step
  # Looping through each realm
  nb_realms <- dim(other_params(params)$exposure)[1]
  for (r in seq(1, nb_realms, 1)) {
    # index selects the right temperature for any t
    index_vec <- as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]) - t
    index <- which(index_vec == max(index_vec[index_vec<=0]))
    temp_at_t <- other_params(params)$ocean_temp[index,r]
    # Arrhenius equation
    unscaled_temp_effect <- (exp(25.22 - (0.63/((8.62e-5)*(273 + temp_at_t)))))

    # Arrhenius equation scaled to a value between 0 and 1
    temp_effect_metabolism_r <- (unscaled_temp_effect - species_params(params)$metab_min) / species_params(params)$metab_range

    # Set temperature effect to 0 if temperatures are outside thermal tolerance limits
    above_max <- temp_at_t > species_params(params)$temp_max
    below_min <- temp_at_t < species_params(params)$temp_min

    temp_effect_metabolism_r[above_max | below_min] = 0

    temp_effect_metab_realms[r,,] <- temp_effect_metabolism_r*other_params(params)$exposure[r,]*other_params(params)$vertical_migration[r,,]
  }

  colSums(temp_effect_metab_realms)
}

#' @export
projectEncounter.therMizer <- function(params, n, n_pp, n_other, t = 0, ...) {
  if (isTRUE(therMizerOptions(params)$aerobic_effect)) {
    params <- withTherMizerSearchVolume(params, t)
  }

  NextMethod()
}

#' @export
projectPredRate.therMizer <- function(params, n, n_pp, n_other, t = 0,
                                      feeding_level, ...) {
  if (isTRUE(therMizerOptions(params)$aerobic_effect)) {
    params <- withTherMizerSearchVolume(params, t)
  }

  NextMethod()
}

#' @export
projectEReproAndGrowth.therMizer <- function(params, n, n_pp, n_other, t = 0,
                                             encounter, feeding_level, ...) {
  if (isTRUE(therMizerOptions(params)$metabolism_effect)) {
    params <- withTherMizerMetabolism(params, t)
  }

  NextMethod()
}

#' Temperature-scaled encounter rate
#'
#' therMizer implementation of mizer's \code{Encounter} rate function.
#' It multiplies the default encounter rate by
#' \code{\link{scaled_temp_effect}()}.
#'
#' @inheritParams therMizerPredRate
#'
#' @returns A numeric matrix with the same dimensions as the value returned by
#'   \code{mizer::mizerEncounter()}.
#'
#' @export

therMizerEncounter <- function(params, n, n_pp, n_other, t = 0, ...) {
  params <- withTherMizerSearchVolume(params, t)
  mizerEncounter(params, n = n, n_pp = n_pp, n_other = n_other, t = t, ...)
}


#' Temperature-scaled predation mortality
#'
#' therMizer implementation of mizer's \code{PredRate} rate function.
#' It applies the encounter temperature scalar to predation mortality.
#'
#' @inheritParams scaled_temp_effect
#' @param n Numeric matrix of species abundances with species in rows and size
#'   classes in columns.
#' @param n_pp Numeric vector giving the background resource abundance by size.
#' @param n_other List of abundances for any other dynamic ecosystem
#'   components.
#' @param feeding_level Numeric array of feeding levels, as returned by
#'   \code{getFeedingLevel()}.
#' @param ... Additional arguments passed through by mizer's internal rate
#'   function machinery.
#'
#' @details If \code{params} uses a custom predation kernel, the function falls
#'   back to the non-FFT implementation used by older versions of mizer.
#'
#' @returns A numeric array with the same structure expected from mizer's
#'   \code{PredRate} rate function.
#'
#' @export

therMizerPredRate <- function(params, n, n_pp, n_other, t, feeding_level, ...) {
  params <- withTherMizerSearchVolume(params, t)
  mizerPredRate(
    params, n = n, n_pp = n_pp, n_other = n_other, t = t,
    feeding_level = feeding_level, ...)
}

#' Temperature-scaled energy for growth and reproduction
#'
#' therMizer implementation of mizer's \code{EReproAndGrowth} rate function.
#' The assimilation term is calculated from encounter, while maintenance
#' metabolism is multiplied by a temperature scalar that is aggregated across
#' realms.
#'
#' @inheritParams therMizerPredRate
#' @param encounter Numeric array of encounter rates, as returned by
#'   \code{getEncounter()}.
#'
#' @returns A numeric matrix with the same dimensions as \code{encounter}.
#'
#' @export

therMizerEReproAndGrowth <- function(params, n = NULL, n_pp = NULL,
                                     n_other = NULL, t = 0, encounter,
                                     feeding_level, ...) {
  params <- withTherMizerMetabolism(params, t)
  mizerEReproAndGrowth(
    params, n = n, n_pp = n_pp, n_other = n_other, t = t,
    encounter = encounter, feeding_level = feeding_level, ...)
}

#' Resource forcing from \code{n_pp_array}
#'
#' therMizer resource dynamics function that reads the time-varying plankton
#' forcing stored in \code{other_params(params)$n_pp_array}.
#'
#' @inheritParams therMizerPredRate
#'
#' @details The function selects the row corresponding to time \code{t},
#'   converts the stored log-scale spectrum back to density with
#'   \code{10^x / params@dw_full}, and sets bins above
#'   \code{w_pp_cutoff} to 0. If \code{t} falls outside the supplied time
#'   series, the series is recycled cyclically.
#'
#' @returns A numeric vector of resource densities over \code{params@w_full}.
#'
#' @export

plankton_forcing <- function(params, t, ...) {

  # checking that t is within ocean_temp, cycling through otherwise
  if(!floor(t) %in% as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]))
    t <- t %% as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][dim(
      other_params(params)$ocean_temp)[[1]]]) +
      as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][1])

  w_cut_off <- params@resource_params$w_pp_cutoff
  # index selects the right temperature for any t
  index_vec <- as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]) - t
  index <- which(index_vec == max(index_vec[index_vec<=0]))
  pkt <- 10^(other_params(params)$n_pp_array[index,])/params@dw_full # converting to density
  pkt[which(as.numeric(names(pkt)) >= w_cut_off)] <- 0

  return(pkt)
}
