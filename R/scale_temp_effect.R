### Functions related to creating the scaling parameters

#' Set the encounter and predation scaling constant
#'
#' Compute the species-specific \code{encounterpred_scale} value used to
#' normalise the encounter and predation temperature response so that the
#' resulting scalar varies between 0 and 1 within each species' thermal range.
#'
#' @inheritParams scaled_temp_effect
#'
#' @returns The modified \code{params} object with
#'   \code{species_params(params)$encounterpred_scale} filled in.
#'
#' @examples
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#' species_params(params)$temp_min <- c(-2, 5)
#' species_params(params)$temp_max <- c(12, 18)
#' params <- setEncounterPredScale(params)
#' species_params(params)$encounterpred_scale
#'
#' @export
#'
setEncounterPredScale <- function(params){
  species_params(params)$encounterpred_scale <- rep(NA, length(species_params(params)$temp_min))
  for (indv in seq(1:length(species_params(params)$temp_min))) {

    # Create a vector of all temperatures each species might encounter
    # Convert from degrees Celsius to Kelvin
    temperature <- seq(species_params(params)$temp_min[indv], species_params(params)$temp_max[indv], by = 0.1) + 273

    # Find the maximum value of the unscaled effect of temperature on encounter and predation rate for each species
    species_params(params)$encounterpred_scale[indv] <-
      max((temperature) * (temperature - (species_params(params)$temp_min[indv] + 273)) *
            ((species_params(params)$temp_max[indv] + 273) - temperature)^(1/2))

  }
  return(params)
}

#' Set metabolism temperature scaling parameters
#'
#' Compute the minimum and range of the Arrhenius-style metabolism response over
#' each species' thermal range. These values are later used to scale metabolic
#' effects between 0 and 1.
#'
#' @inheritParams scaled_temp_effect
#'
#' @returns The modified \code{params} object with
#'   \code{species_params(params)$metab_min} and
#'   \code{species_params(params)$metab_range} filled in.
#'
#' @examples
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#' species_params(params)$temp_min <- c(-2, 5)
#' species_params(params)$temp_max <- c(12, 18)
#' params <- setMetabTher(params)
#' species_params(params)$metab_min
#' species_params(params)$metab_range
#'
#' @export
#'

setMetabTher <- function(params){
  min_metab_value <- (exp(25.22 - (0.63/((8.62e-5)*(273 + species_params(params)$temp_min)))))
  max_metab_value <- (exp(25.22 - (0.63/((8.62e-5)*(273 + species_params(params)$temp_max)))))

  species_params(params)$metab_min <- min_metab_value
  species_params(params)$metab_range <- max_metab_value - min_metab_value

  return(params)
}


#' Calculate the encounter and predation temperature scalar
#'
#' Evaluate the temperature-dependent scalar applied to encounter and predation
#' processes at time \code{t}.
#'
#' @param params A \code{MizerParams} object that has been prepared for
#'   therMizer, typically with \code{\link{upgradeTherParams}()}.
#' @param t Numeric time in the same units as the first dimension of
#'   \code{other_params(params)$ocean_temp}. If \code{t} falls outside the
#'   supplied time series, the temperature series is recycled cyclically.
#'
#' @details The scalar is calculated separately for each realm, multiplied by
#'   the corresponding exposure and vertical migration weights, and then summed
#'   across realms. Values are set to 0 outside each species' thermal limits.
#'
#' @returns A numeric matrix with species in rows and size classes in columns.
#'
#' @seealso \code{\link{upgradeTherParams}()},
#'   \code{\link{setEncounterPredScale}()}, and
#'   \code{\link{setVerticality}()}.
#'
#' @examples
#' \donttest{
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#' params <- suppressWarnings(suppressMessages(
#'   upgradeTherParams(params,
#'     temp_min = c(-2, 5), temp_max = c(12, 18),
#'     ocean_temp_array = c("2000" = 5, "2001" = 6, "2002" = 7))))
#' # Returns a species x size matrix of temperature scalars
#' ste <- scaled_temp_effect(params, t = 2001)
#' dim(ste)  # nrow = n_species, ncol = n_size_classes
#' }
#'
#' @export
#'
scaled_temp_effect <- function(params, t) {
  # checking that t is within ocean_temp, cycling through otherwise
  if(!floor(t) %in% as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]))
    t <- t %% as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][dim(
      other_params(params)$ocean_temp)[[1]]]) +
      as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][1])

  scaled_temp_effect_realms <- array(NA, dim = c(dim(other_params(params)$vertical_migration)),
                                     dimnames = c(dimnames(other_params(params)$vertical_migration)))

  # Looping through each realm
  nb_realms <- dim(other_params(params)$vertical_migration)[1]
  for (r in seq(1, nb_realms, 1)) {
    # index selects the right temperature for any t
    index_vec <- as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]) - t
    index <- which(index_vec == max(index_vec[index_vec<=0]))
    temp_at_t <- other_params(params)$ocean_temp[index,r] + 273

    # Calculate unscaled temperature effect using a generic polynomial rate equation
    unscaled_temp_effect <-
      temp_at_t * (temp_at_t - (species_params(params)$temp_min + 273)) *
      (species_params(params)$temp_max - temp_at_t + 273)^(1/2)

    # Scale using new parameter
    scaled_temp_effect_r <- unscaled_temp_effect / species_params(params)$encounterpred_scale

    # Set temperature effect to 0 if temperatures are outside thermal tolerance limits
    above_max <- (temp_at_t - 273) > species_params(params)$temp_max
    below_min <- (temp_at_t - 273) < species_params(params)$temp_min

    scaled_temp_effect_r[above_max | below_min] = 0
    scaled_temp_effect_realms[r,,] <- scaled_temp_effect_r *
      other_params(params)$exposure[r,] * other_params(params)$vertical_migration[r,,]
  }
  scaled_temp_effect <- colSums(scaled_temp_effect_realms)

  return(scaled_temp_effect)
}
