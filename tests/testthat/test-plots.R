test_that("plotTherPerformance returns documented plot data and ggplot output", {
  params <- make_upgraded_params()

  plot_data <- plotTherPerformance(params, resolution = 1, return_data = TRUE)
  plot_object <- plotTherPerformance(params, resolution = 1)

  expect_setequal(names(plot_data), c("temperature", "Species", "scalar", "Type"))
  expect_equal(sort(unique(as.character(plot_data$Type))), c("Encounter", "Metabolism"))
  expect_true(all(plot_data$scalar >= 0))
  expect_true(all(plot_data$scalar <= 1))
  expect_s3_class(plot_object, "ggplot")
})

test_that("plotTherScalar returns documented plot data and supports species filtering", {
  params <- make_upgraded_params()

  plot_data <- plotTherScalar(params, return_data = TRUE)
  species_data <- plotTherScalar(params, species = "sp1", return_data = TRUE)
  plot_object <- plotTherScalar(params)

  expect_setequal(names(plot_data), c("Time", "Species", "Scalar", "Type"))
  expect_equal(sort(unique(as.character(plot_data$Type))), c("Encounter", "Metabolism"))
  expect_true(all(plot_data$Scalar >= 0))
  expect_true(all(plot_data$Scalar <= 1))
  expect_equal(unique(as.character(species_data$Species)), "sp1")
  expect_s3_class(plot_object, "ggplot")
})
