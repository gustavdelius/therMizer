
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

#' @method projectEncounter therMizer
#' @export
projectEncounter.therMizer <- function(params, n, n_pp, n_other, t = 0, ...) {
  if (isTRUE(therMizerOptions(params)$aerobic_effect)) {
    params <- withTherMizerSearchVolume(params, t)
  }

  NextMethod()
}

#' @method projectPredRate therMizer
#' @export
projectPredRate.therMizer <- function(params, n, n_pp, n_other, t = 0,
                                      feeding_level, ...) {
  if (isTRUE(therMizerOptions(params)$aerobic_effect)) {
    params <- withTherMizerSearchVolume(params, t)
  }

  NextMethod()
}

#' @method projectEReproAndGrowth therMizer
#' @export
projectEReproAndGrowth.therMizer <- function(params, n, n_pp, n_other, t = 0,
                                             encounter, feeding_level, ...) {
  if (isTRUE(therMizerOptions(params)$metabolism_effect)) {
    params <- withTherMizerMetabolism(params, t)
  }

  NextMethod()
}

#' Resource forcing from \code{n_pp_array}
#'
#' therMizer resource dynamics function that reads the time-varying plankton
#' forcing stored in \code{other_params(params)$n_pp_array}.
#'
#' @inheritParams scaled_temp_effect
#' @param ... Unused. Present for compatibility with mizer's resource dynamics
#'   interface.
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
