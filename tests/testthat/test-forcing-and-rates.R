test_that("plankton_forcing converts log-scale forcing and recycles time", {
  params <- make_upgraded_params(with_realms = TRUE, with_n_pp = TRUE)

  forcing <- plankton_forcing(params, 2001)
  wrapped_forcing <- plankton_forcing(params, 2003)
  below_cutoff <- as.numeric(names(forcing)) < params@resource_params$w_pp_cutoff

  expect_length(forcing, length(params@w_full))
  expect_equal(wrapped_forcing, forcing)
  expect_equal(
    unname(forcing[below_cutoff]),
    unname(rep(10^-5, sum(below_cutoff)) / params@dw_full[below_cutoff])
  )
  expect_true(all(forcing[!below_cutoff] == 0))
})

test_that("temperature-scaled rate functions collapse to zero outside thermal limits", {
  params <- make_upgraded_params(
    ocean_temp_array = c("2000" = 40, "2001" = 40, "2002" = 40)
  )
  n <- mizer::initialN(params)
  n_pp <- mizer::initialNResource(params)
  n_other <- mizer::initialNOther(params)
  feeding_level <- mizer::getFeedingLevel(
    params,
    n = n,
    n_pp = n_pp,
    n_other = n_other,
    t = 2000
  )

  encounter <- mizer::getEncounter(
    params,
    n = n,
    n_pp = n_pp,
    n_other = n_other,
    t = 2000
  )
  pred_rate <- mizer::getPredRate(
    params,
    n = n,
    n_pp = n_pp,
    n_other = n_other,
    t = 2000
  )
  e_growth <- mizer::getEReproAndGrowth(
    params,
    n = n,
    n_pp = n_pp,
    n_other = n_other,
    t = 2000
  )

  expect_true(all(encounter == 0))
  expect_true(all(pred_rate == 0))
  expect_true(all(e_growth == 0))

  rates <- mizer::getRates(
    params,
    n = n,
    n_pp = n_pp,
    n_other = n_other,
    t = 2000
  )

  expect_true(all(rates$encounter == 0))
  expect_true(all(rates$pred_rate == 0))
  expect_true(all(rates$e_growth == 0))
})
