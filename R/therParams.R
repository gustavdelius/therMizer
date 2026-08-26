### Function aiming to upgrade a default mizer object to one able to work with the therMizer extension

# helper function
decimal_year <- function(date_vec) {
    parse_order <- ifelse(nchar(date_vec) <= 4, "%Y",
                          ifelse(nchar(date_vec) == 7, "%Y-%m",
                                 "%Y-%m-%d"))
    pad_year <- parse_order == "%Y" & nchar(date_vec) < 4
    if (any(pad_year)) {
        date_vec[pad_year] <- sprintf("%04d", as.integer(date_vec[pad_year]))
    }

    normalized_dates <- ifelse(
        parse_order == "%Y",
        paste0(date_vec, "-01-01"),
        ifelse(parse_order == "%Y-%m",
               paste0(date_vec, "-01"),
               date_vec)
    )
    parsed_dates <- as.Date(normalized_dates)
    if (anyNA(parsed_dates)) {
        stop("The supplied time labels could not be parsed as dates.")
    }

    year_start <- as.Date(paste0(format(parsed_dates, "%Y"), "-01-01"))
    next_year_start <- as.Date(paste0(as.integer(format(parsed_dates, "%Y")) + 1L,
                                      "-01-01"))

    as.numeric(format(parsed_dates, "%Y")) +
        as.numeric(parsed_dates - year_start) /
        as.numeric(next_year_start - year_start)
}


#' Upgrade a \code{MizerParams} object for therMizer
#'
#' Add therMizer-specific thermal parameters, temperature forcing, optional
#' plankton forcing, and realm structure to a standard
#' \code{MizerParams} object.
#'
#' @param params A \code{MizerParams} object to augment.
#' @param temp_min Numeric vector giving the lower thermal limit of each
#'   species, in degrees C. Its length must match the number of species in
#'   \code{params}.
#' @param temp_max Numeric vector giving the upper thermal limit of each
#'   species, in degrees C. Its length must match the number of species in
#'   \code{params}.
#' @param ocean_temp_array Numeric scalar, vector, matrix, or array of
#'   temperatures. The first dimension is interpreted as time. If a second
#'   dimension is present it is interpreted as realms. Character time labels in
#'   \code{\%Y}, \code{\%Y-\%m}, or \code{\%Y-\%m-\%d} format are converted to
#'   numeric years.
#' @param n_pp_array Optional vector, matrix, or array of plankton forcing with
#'   dimensions time x size. The time dimension must match
#'   \code{ocean_temp_array}, and the size dimension must match
#'   \code{params@w_full}. Values are interpreted on the log10 scale used by
#'   \code{\link{plankton_forcing}()}.
#' @param vertical_migration_array Optional array of dimensions
#'   realm x species x size giving the fraction of time each species spends in
#'   each realm at each size. Values must be non-negative and sum to 1 across
#'   realms for every species-size combination.
#' @param exposure_array Optional array of dimensions realm x species with
#'   values between 0 and 1 describing how strongly each species is exposed to
#'   temperature in each realm.
#' @param aerobic_effect Logical. If \code{TRUE}, activate therMizer's
#'   temperature scaling for encounter and predation-rate calculations. Default
#'   is \code{TRUE}.
#' @param metabolism_effect Logical. If \code{TRUE}, activate therMizer's
#'   temperature scaling for maintenance metabolism in the
#'   energy-for-growth-and-reproduction calculation. Default is \code{TRUE}.
#' @param info_level Integer controlling how much therMizer reports about the
#'   choices it made on your behalf, in the same way as mizer's own setup
#'   functions. Use \code{0} for silence. Default is
#'   \code{\link[mizer]{default_info_level}()}.
#'
#' @details Because therMizer scales the encounter rate with temperature, the
#'   current value of the calculated species parameter \code{gamma} is declared
#'   as a given species parameter, so that mizer does not later recalculate it
#'   from an encounter rate that already carries the temperature scalar. Set
#'   \code{given_species_params(params)$gamma <- NA} to hand it back to mizer.
#'
#'   If \code{vertical_migration_array} is omitted, a default realm
#'   allocation is constructed from the available temperature data. If
#'   \code{n_pp_array} is supplied, the resource dynamics function is set to
#'   \code{\link{plankton_forcing}()}. The returned object also stores a time
#'   offset in \code{other_params(params)$t_idx} so therMizer can align mizer's
#'   simulation time with the supplied forcing series.
#'
#' @returns The modified \code{params} object, ready to use with therMizer.
#'
#' @seealso \code{\link{setVerticality}()},
#'   \code{\link{setEncounterPredScale}()},
#'   \code{\link{setMetabTher}()}, and
#'   \code{\link{plankton_forcing}()}.
#'
#' @examples
#' \donttest{
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#'
#' # Minimal usage: constant temperature, one realm per species
#' params <- suppressWarnings(suppressMessages(
#'   upgradeTherParams(params,
#'     temp_min = c(-2, 5), temp_max = c(12, 18),
#'     ocean_temp_array = c("2000" = 5, "2001" = 6, "2002" = 7))))
#'
#' # Project for 2 years starting from the first temperature time step
#' sim <- project(params, t_start = 2000, t_max = 2, dt = 1)
#'
#' # Two realms: sp1 lives at the surface, sp2 in the deep
#' ocean_temp <- array(
#'   c(4, 8, 5, 9, 6, 10),
#'   dim = c(3, 2),
#'   dimnames = list(time = c("2000", "2001", "2002"),
#'                   realm = c("surface", "deep")))
#' vm <- array(0,
#'   dim = c(2, 2, length(params@w)),
#'   dimnames = list(realm = c("surface", "deep"),
#'                   sp = c("sp1", "sp2"), w = params@w))
#' vm["surface", "sp1", ] <- 1
#' vm["deep",    "sp2", ] <- 1
#' params2 <- suppressWarnings(suppressMessages(
#'   upgradeTherParams(params,
#'     temp_min = c(-2, 5), temp_max = c(12, 18),
#'     ocean_temp_array = ocean_temp,
#'     vertical_migration_array = vm)))
#' sim2 <- project(params2, t_start = 2000, t_max = 2, dt = 1)
#' }
#'
#' @export

upgradeTherParams <- function(params, temp_min = NULL, temp_max = NULL,
                              ocean_temp_array = NULL,
                              n_pp_array = NULL,
                              vertical_migration_array = NULL,
                              exposure_array = NULL,
                              aerobic_effect = TRUE,
                              metabolism_effect = TRUE,
                              info_level = default_info_level()){
 with_info_level(info_level = info_level, {
  no_sp <- length(species_params(params)$species)

  ## Protect `gamma` from being recalculated through the temperature scaling.
  ## `gamma` is a calculated species parameter, so mizer recomputes it from the
  ## encounter rate every time the species parameters are rebuilt. Once the
  ## object is a therMizer object that encounter rate is temperature-scaled, so
  ## the recalculated `gamma` would absorb the temperature scalar of whatever
  ## time step it happened to be evaluated at, and is undefined wherever that
  ## scalar is zero. Declaring the current, temperature-independent value as
  ## given keeps the model as it is. To let `gamma` follow `f0` again, set
  ## `given_species_params(params)$gamma <- NA`.
  gamma_now <- species_params(params)$gamma
  gamma_given <- given_species_params(params)$gamma
  if (!is.null(gamma_now) && (is.null(gamma_given) || anyNA(gamma_given))) {
    signal_info("gamma",
                paste("Keeping the current `gamma` fixed, so that it is not",
                      "recalculated from the temperature-scaled encounter rate."),
                level = 1)
    given_species_params(params)$gamma <- gamma_now
  }

  ## temperature parameters
  if(is.null(temp_min)){
    if(is.null(species_params(params)$temp_min)) stop("You need to setup min temperature for your species.")
  } else if(length(temp_min) != no_sp) {
    stop("The length of temp_min is not the same as the number of species.")
  } else {species_params(params)$temp_min <- temp_min}


  if(is.null(temp_max)){
    if(is.null(species_params(params)$temp_max)) stop("You need to setup max temperature for your species.")
  } else if(length(temp_max) != no_sp) {
    stop("The length of temp_max is not the same as the number of species.")
  } else {species_params(params)$temp_max <- temp_max}

  params <- setEncounterPredScale(params)
  params <- setMetabTher(params)

  ## temperature data array
  if(is.null(ocean_temp_array)) stop("You need to specify a temperature array to do the projections.")

  ## check dimension
  if(is.vector(ocean_temp_array)){
    ## check dimnames
    if(is.null(names(ocean_temp_array))){
      signal_info("ocean_temp_array",
                  "`ocean_temp_array` has no dates. They are assumed to be successive years starting from 0.",
                  level = 1, severity = "warning")
      names(ocean_temp_array) <- sprintf("%04d", seq(0, length.out = length(ocean_temp_array)))
    }
    date_vec <- names(ocean_temp_array)
    date_vec <- decimal_year(date_vec)

    ocean_temp_array <- matrix(ocean_temp_array,
                               nrow = length(ocean_temp_array),
                               ncol = dim(params@species_params)[1],
                               byrow = F,
                               dimnames = list("time" = date_vec, "species" = params@species_params$species))

  } else if(is.array(ocean_temp_array))
  {
    # assuming that the second dimension is realms. If there is an issue with that it will be signaled later
    ## check dimnames
    date_vec <- dimnames(ocean_temp_array)[[1]]
    date_vec <- decimal_year(date_vec)
    dimnames(ocean_temp_array)[[1]] <- date_vec
  } else stop("The ocean_temp_array is of the wrong format")



  other_params(params)$ocean_temp <- ocean_temp_array

  ## background resource
  if(!is.null(n_pp_array)){
    if(!dim(ocean_temp_array)[1] == dim(n_pp_array)[1])
      stop("The time dimension of ocean_temp_array and n_pp_array must be equal.")

    if(!dim(n_pp_array)[2] == length(params@w_full))
      stop("The size dimension of the n_pp_array must be the same as w_full.")

    if(!identical(dimnames(n_pp_array)[[2]],params@w_full)){
      signal_info("n_pp_array",
                  paste("The dimnames of the second dimension of `n_pp_array`",
                        "are not the same as the ones in `w_full`. Since the",
                        "dimension size is the same, the dimnames have been",
                        "replaced by `w_full`."),
                  level = 1, severity = "warning")
      dimnames(n_pp_array)[[2]] <- params@w_full
    }

    if(!is.array(n_pp_array) && !is.matrix(n_pp_array)) n_pp_array <- as.matrix(n_pp_array)

    params <- setResource(params, resource_dynamics = "plankton_forcing")
    # time names of ocean_temp_array might have been modified for thermizer to work, doing the same to n_pp
    dimnames(n_pp_array)[[1]] <- dimnames(ocean_temp_array)[[1]]

    other_params(params)$n_pp_array <- n_pp_array
  }

  # realms
  if(!is.null(vertical_migration_array))
  {
    params <- setVerticality(params, vertical_migration_array, exposure_array)
  } else if(!is.null(exposure_array)){

    vertical_fill <- 1/dim(exposure_array)[1]
    vertical_names <- dimnames(exposure_array)[[1]]
    vertical_dim <- c(dim(exposure_array),
                      length(params@w))

    vertical_migration_array <-
      array(vertical_fill,
            dim = vertical_dim,
            dimnames = list("realm" = vertical_names,
                            "species" = params@species_params$species,
                            "w" = params@w))
    signal_info("vertical_migration_array",
                "`exposure_array` used to create `vertical_migration_array`.",
                level = 1)
    params <- setVerticality(params, vertical_migration_array, exposure_array)
  } else {
    if(is.null(dim(ocean_temp_array))){
      vertical_fill <- rep(c(rep(c(1,rep(0,length(params@species_params$species))),
                                 length(params@species_params$species)-1),1),length(params@w))
      vertical_names <- params@species_params$species
      vertical_dim <- c(rep(length(params@species_params$species),2), length(params@w))
      signal_info("vertical_migration_array",
                  "Assuming one realm per species to create `vertical_migration_array`.",
                  level = 1)
    } else if(!isTRUE(all.equal(dimnames(ocean_temp_array)[[2]],params@species_params$species))){
      vertical_fill <- 1/length(dimnames(ocean_temp_array)[[2]])
      vertical_names <- dimnames(ocean_temp_array)[[2]]
      vertical_dim <- c(dim(ocean_temp_array)[2],
                        length(params@species_params$species),
                        length(params@w))
      signal_info("vertical_migration_array",
                  paste("Your realm names don't match your species names, so",
                        "species are assumed to spend equal time in all realms."),
                  level = 1)
    } else {
      vertical_fill <- rep(c(rep(c(1,rep(0,length(params@species_params$species))),
                                 length(params@species_params$species)-1),1),length(params@w))
      vertical_names <- params@species_params$species
      vertical_dim <- c(rep(length(params@species_params$species),2), length(params@w))
    }

    vertical_migration_array <-
      array(vertical_fill,
            dim = vertical_dim,
            dimnames = list("realm" = vertical_names,
                            "species" = params@species_params$species,
                            "w" = params@w))
    params <- setVerticality(params, vertical_migration_array)
  }

  other_params(params)$therMizer <- list(
    aerobic_effect = isTRUE(aerobic_effect),
    metabolism_effect = isTRUE(metabolism_effect)
  )

  ## time dimension
  other_params(params)$t_idx = - as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][1])

  # Record that therMizer has been applied to this object, stamping the
  # installed package version the first time and preserving the existing stamp
  # afterwards, then promote the object to its therMizer marker class so that
  # the project* methods dispatch during projection. `recordExtension()` takes
  # the installation requirement from the chain therMizer registered itself in
  # from `.onLoad`. The whole active registry must not be copied in, because
  # another extension can be loaded without having been applied to this model.
  version <- if ("therMizer" %in% names(params@extensions)) {
    NULL
  } else {
    as.character(packageVersion("therMizer"))
  }
  params <- mizer::recordExtension(params, "therMizer", version = version)
  params <- mizer::coerceToExtensionClass(params)

  return(params)
 })
}

# @title Project thermizer object
#
# @description Wrapper function adjusting simulation time and start time
# for the project function
#
# @inheritParams upgradeTherParams
#
# @export
#
# therProject <- function(params){
#   sim_times <- c(as.numeric(dimnames(other_params(params)$ocean_temp)[[1]][1]),
#                  dim(other_params(params)$ocean_temp)[1])
#
#   cat(sprintf("The simulation is set to start in %d and will run for %d years.\n",sim_times[1], sim_times[2]))
#
#   sim <- project(params, t_start = sim_times[1], t_max = sim_times[2]-1)
# }
