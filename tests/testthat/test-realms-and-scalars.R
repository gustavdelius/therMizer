test_that("setVerticality expands vector temperatures and infers exposure", {
  params <- make_base_params()
  realm_inputs <- make_realm_inputs(params, times = c("2000", "2001"))

  other_params(params)$ocean_temp <- c("2000" = 4, "2001" = 6)
  expect_message(
    params <- setVerticality(params, realm_inputs$vertical_migration_array),
    "ocean_temp_array was extended"
  )

  expect_equal(dim(other_params(params)$ocean_temp), c(2, 2))
  expect_equal(colnames(other_params(params)$ocean_temp), c("surface", "deep"))
  expect_equal(unname(other_params(params)$exposure[, "sp1"]), c(1, 0))
  expect_equal(unname(other_params(params)$exposure[, "sp2"]), c(0, 1))
})

test_that("setVerticality rejects realm allocations that do not sum to one", {
  params <- make_base_params()
  realm_inputs <- make_realm_inputs(params, times = c("2000", "2001"))

  other_params(params)$ocean_temp <- realm_inputs$ocean_temp_array
  realm_inputs$vertical_migration_array["surface", "sp1", 1] <- 0.5

  expect_error(
    setVerticality(params, realm_inputs$vertical_migration_array),
    "don't sum to 1"
  )
})

test_that("scaled_temp_effect returns a species by size matrix and recycles time", {
  params <- make_upgraded_params(with_realms = TRUE)

  scalar <- scaled_temp_effect(params, 2001)
  wrapped_scalar <- scaled_temp_effect(params, 2003)

  expect_equal(dim(scalar), c(nrow(params@species_params), length(params@w)))
  expect_true(all(is.finite(scalar)))
  expect_true(all(scalar >= 0))
  expect_true(all(scalar <= 1))
  expect_equal(wrapped_scalar, scalar)
})
