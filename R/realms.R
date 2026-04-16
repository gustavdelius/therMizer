#' Add realm-specific temperature structure to a therMizer model
#'
#' Store vertical migration and exposure information in a
#' \code{MizerParams} object so temperature effects can be combined across
#' multiple realms.
#'
#' @inheritParams upgradeTherParams
#'
#' @details If \code{ocean_temp_array} has no realm dimension, it is expanded to
#'   one column per realm in \code{vertical_migration_array}. When
#'   \code{exposure_array} is omitted, exposure is inferred from whether a
#'   species occupies a realm at any size class.
#'
#' @returns The modified \code{params} object with
#'   \code{other_params(params)$vertical_migration} and
#'   \code{other_params(params)$exposure} filled in.
#'
#' @examples
#' \donttest{
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#' species_params(params)$temp_min <- c(-2, 5)
#' species_params(params)$temp_max <- c(12, 18)
#'
#' # Store a two-realm temperature array in params before calling setVerticality
#' ocean_temp <- array(
#'   c(4, 8, 5, 9, 6, 10),
#'   dim = c(3, 2),
#'   dimnames = list(time = c("2000", "2001", "2002"),
#'                   realm = c("surface", "deep")))
#' other_params(params)$ocean_temp <- ocean_temp
#'
#' # sp1 stays in the surface realm; sp2 stays in the deep realm
#' vm <- array(0,
#'   dim = c(2, 2, length(params@w)),
#'   dimnames = list(realm = c("surface", "deep"),
#'                   sp = c("sp1", "sp2"), w = params@w))
#' vm["surface", "sp1", ] <- 1
#' vm["deep",    "sp2", ] <- 1
#'
#' params <- setEncounterPredScale(params)
#' params <- setMetabTher(params)
#' params <- setVerticality(params, vm)
#' str(other_params(params)$exposure)
#' }
#'
#' @export
#'

setVerticality <- function(params, vertical_migration_array, exposure_array = NULL){

  species_names <- as.character(params@species_params$species)
  realm_names <- dimnames(vertical_migration_array)$realm
  sizes <- params@w
  ocean_temp_array <- other_params(params)$ocean_temp

  # check if ocean_array has realms
  if(is.null(ocean_temp_array))
    stop("The params object needs to contain an ocean_temp_array.")

  if(is.null(dim(ocean_temp_array))){
    ocean_temp_array <- array(rep(ocean_temp_array, length(dimnames(vertical_migration_array)[[1]])),
                              dim = c(length(ocean_temp_array), length(dimnames(vertical_migration_array)[[1]])),
                              dimnames = list("time" = names(ocean_temp_array),
                                              "realm" = dimnames(vertical_migration_array)[[1]]))
    other_params(params)$ocean_temp <- ocean_temp_array
    message("ocean_temp_array was extended to a matrix with the same names as the vertical_migration_array.")
  }

  if(is.null(exposure_array) & !isTRUE(all.equal(dimnames(ocean_temp_array)[[2]],dimnames(vertical_migration_array)[[1]])))
    stop("The realm names of ocean_temp_array and vertical_migration_array are different.")

  # check if vertical_migration_array is correct
  if(dim(vertical_migration_array)[1] != dim(ocean_temp_array)[2])
    stop("The first dimension of vertical_migration_array must be equal to the number of realms in ocean_temp_array")

  if(dim(vertical_migration_array)[2] != length(species_names))
    stop("The second dimension of vertical_migration_array must be equal to the number of species")

  if(dim(vertical_migration_array)[3] != length(sizes))
    stop("The third dimension of vertical_migration_array must be equal to the number of size classes")

  # And check that all filled size classes sum to 1, no more and no less
  for (iSpecies in 1:length(species_names)) {
    if(length(realm_names) == 1){
      if(!all(vertical_migration_array[ , iSpecies, ] == 1))
        stop(paste0("Your realm allocations for ", species_names[iSpecies], " don't sum to 1 for all sizes.
		Their time in a given realm is either over- or under-allocated."))
    } else {
      if (!all(apply(vertical_migration_array[ , iSpecies, ],2,sum) == 1)) {
        stop(paste0("Your realm allocations for ", species_names[iSpecies], " don't sum to 1 for all sizes.
		Their time in a given realm is either over- or under-allocated."))
      }
    }# the check above sometimes doesn't work, it may have to do with long decimals and rounding
  }

  other_params(params)$vertical_migration <- vertical_migration_array

  if(is.null(exposure_array)){
    exposure_array <- array(0, dim = (c(length(realm_names), length(species_names))),
                            dimnames = list(realm = realm_names, sp = species_names)) # realm x species

    for (r in seq(1,length(realm_names),1)) {
      for (s in seq(1,length(species_names),1)) {
        if (any(vertical_migration_array[r,s,] > 0)) {
          exposure_array[r,s] = 1
        }
      }
    }
  } else {
    # check if exposure_array is correct
    if(!isTRUE(all.equal(dimnames(vertical_migration_array)[[1]],dimnames(exposure_array)[[1]])))
      stop("The first dimension of exposure_array must have the same names as the first dimension of the vertical_migration_array.")

    if(dim(exposure_array)[2] != length(species_names))
      stop("The second dimension of exposure_array must be equal to the number of species.")

    if(any(exposure_array > 1 & exposure_array <0))
      stop("The values within the exposure array must be between 0 and 1.")
  }
  other_params(params)$exposure <- exposure_array



  return(params)
}
