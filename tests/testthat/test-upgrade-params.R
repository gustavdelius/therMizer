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

  expect_s4_class(upgraded, "MizerParams")
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
