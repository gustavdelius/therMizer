test_that("scaling helpers populate derived species parameters", {
  params <- make_base_params()
  limits <- make_temp_limits()

  params@species_params$temp_min <- limits$temp_min
  params@species_params$temp_max <- limits$temp_max

  params <- setEncounterPredScale(params)
  params <- setMetabTher(params)

  expect_true(all(is.finite(params@species_params$encounterpred_scale)))
  expect_true(all(params@species_params$encounterpred_scale > 0))
  expect_true(all(is.finite(params@species_params$metab_min)))
  expect_true(all(params@species_params$metab_range > 0))
})

test_that("upgradeTherParams augments params and honours rate toggles", {
  params <- make_base_params()
  limits <- make_temp_limits()
  ocean_temp_array <- c("2000-01" = 3, "2000-02" = 6, "2000-03" = 9)

  upgraded <- suppressMessages(
    upgradeTherParams(
      params = params,
      temp_min = limits$temp_min,
      temp_max = limits$temp_max,
      ocean_temp_array = ocean_temp_array,
      aerobic_effect = FALSE,
      metabolism_effect = FALSE
    )
  )

  expect_s3_class(upgraded, "MizerParams")
  expect_s3_class(upgraded, "therMizer")
  expect_true("therMizer" %in% names(mizer::getMetadata(upgraded)$extensions))
  expect_equal(
    mizer::getMetadata(upgraded)$extensions$therMizer[["requirement"]],
    "sizespectrum/therMizer"
  )
  expect_equal(mizer::getMetadata(upgraded)$extensions$therMizer[["version"]],
               as.character(utils::packageVersion("therMizer")))
  expect_false(other_params(upgraded)$therMizer$aerobic_effect)
  expect_false(other_params(upgraded)$therMizer$metabolism_effect)
  expect_true(all(c(
    "temp_min",
    "temp_max",
    "encounterpred_scale",
    "metab_min",
    "metab_range"
  ) %in% names(upgraded@species_params)))
  expect_true(is.matrix(other_params(upgraded)$ocean_temp))
  expect_true(all(is.finite(as.numeric(dimnames(other_params(upgraded)$ocean_temp)[[1]]))))
  expect_false(is.null(other_params(upgraded)$vertical_migration))
  expect_false(is.null(other_params(upgraded)$exposure))
  expect_equal(upgraded@rates_funcs$Encounter, "mizerEncounter")
  expect_equal(upgraded@rates_funcs$PredRate, "mizerPredRate")
  expect_equal(upgraded@rates_funcs$EReproAndGrowth, "mizerEReproAndGrowth")
})

test_that("upgradeTherParams installs plankton forcing when n_pp_array is supplied", {
  params <- make_upgraded_params(with_realms = TRUE, with_n_pp = TRUE)

  expect_equal(params@resource_dynamics, "plankton_forcing")
  expect_equal(dim(other_params(params)$n_pp_array), c(3, length(params@w_full)))
})

test_that("info_level controls what upgradeTherParams reports", {
  params <- make_base_params()
  limits <- make_temp_limits()

  args <- list(
    params = params,
    temp_min = limits$temp_min,
    temp_max = limits$temp_max,
    ocean_temp_array = c(3, 6, 9)
  )

  # Unnamed temperatures make therMizer invent dates, which it reports
  expect_warning(suppressMessages(do.call(upgradeTherParams, args)),
                 "assumed to be successive years")
  expect_silent(do.call(upgradeTherParams, c(args, list(info_level = 0))))
})

test_that("upgradeTherParams does not contaminate gamma calculation with temperature scaling", {
  base <- make_base_params()
  limits <- make_temp_limits()
  ocean_temp_array <- c("2000" = 5, "2001" = 6, "2002" = 7)

  upgrade <- function(params) {
    suppressWarnings(suppressMessages(
      upgradeTherParams(params,
                        temp_min = limits$temp_min,
                        temp_max = limits$temp_max,
                        ocean_temp_array = ocean_temp_array)))
  }

  once <- upgrade(base)
  twice <- upgrade(once)

  expect_equal(species_params(once)$gamma, species_params(base)$gamma)
  expect_equal(species_params(twice)$gamma, species_params(base)$gamma)
  expect_true(is.null(given_species_params(once)$gamma) ||
              all(is.na(given_species_params(once)$gamma)))

  # An ordinary species parameter change recalculates gamma cleanly without error
  changed <- once
  species_params(changed)$beta <- c(120, 120)
  expect_true(all(is.finite(species_params(changed)$gamma)))
  expect_true(all(species_params(changed)$gamma > 0))
})
