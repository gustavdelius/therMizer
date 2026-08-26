make_species_params <- function() {
  data.frame(
    species = c("sp1", "sp2"),
    w_inf = c(100, 1000),
    w_max = c(150, 1500),
    k_vb = c(0.3, 0.2),
    w_mat = c(10, 100),
    beta = c(100, 100),
    sigma = c(2, 2),
    stringsAsFactors = FALSE
  )
}

make_temp_limits <- function() {
  list(
    temp_min = c(-2, 5),
    temp_max = c(12, 18)
  )
}

make_base_params <- function(no_w = 16) {
  suppressMessages(
    mizer::newMultispeciesParams(
      species_params = make_species_params(),
      no_w = no_w,
      info_level = 0
    )
  )
}

make_realm_inputs <- function(params, times = c("2000", "2001", "2002")) {
  realm_names <- c("surface", "deep")
  species_names <- as.character(params@species_params$species)

  ocean_temp_array <- array(
    c(4, 8,
      5, 9,
      6, 10),
    dim = c(length(times), length(realm_names)),
    dimnames = list(time = times, realm = realm_names)
  )

  vertical_migration_array <- array(
    0,
    dim = c(length(realm_names), length(species_names), length(params@w)),
    dimnames = list(realm = realm_names, sp = species_names, w = params@w)
  )
  vertical_migration_array["surface", "sp1", ] <- 1
  vertical_migration_array["deep", "sp2", ] <- 1

  exposure_array <- array(
    c(1, 0,
      0, 1),
    dim = c(length(realm_names), length(species_names)),
    dimnames = list(realm = realm_names, sp = species_names)
  )

  list(
    ocean_temp_array = ocean_temp_array,
    vertical_migration_array = vertical_migration_array,
    exposure_array = exposure_array
  )
}

make_n_pp_array <- function(params, times = c("2000", "2001", "2002"), value = -5) {
  array(
    value,
    dim = c(length(times), length(params@w_full)),
    dimnames = list(time = times, w = params@w_full)
  )
}

make_upgraded_params <- function(with_realms = FALSE,
                                 with_n_pp = FALSE,
                                 ocean_temp_array = NULL,
                                 aerobic_effect = TRUE,
                                 metabolism_effect = TRUE) {
  params <- make_base_params()
  limits <- make_temp_limits()

  args <- list(
    params = params,
    temp_min = limits$temp_min,
    temp_max = limits$temp_max,
    aerobic_effect = aerobic_effect,
    metabolism_effect = metabolism_effect
  )

  if (with_realms) {
    realm_inputs <- make_realm_inputs(params)
    args$ocean_temp_array <- if (is.null(ocean_temp_array)) {
      realm_inputs$ocean_temp_array
    } else {
      ocean_temp_array
    }
    args$vertical_migration_array <- realm_inputs$vertical_migration_array
    args$exposure_array <- realm_inputs$exposure_array
    time_labels <- dimnames(args$ocean_temp_array)[[1]]
  } else {
    args$ocean_temp_array <- if (is.null(ocean_temp_array)) {
      c("2000" = 3, "2001" = 6, "2002" = 9)
    } else {
      ocean_temp_array
    }
    time_labels <- names(args$ocean_temp_array)
  }

  if (with_n_pp) {
    args$n_pp_array <- make_n_pp_array(params, times = time_labels)
  }

  suppressWarnings(suppressMessages(do.call(upgradeTherParams, args)))
}
