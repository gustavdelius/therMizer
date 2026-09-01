# Calculate the encounter and predation temperature scalar

Evaluate the temperature-dependent scalar applied to encounter and
predation processes at time `t`.

## Usage

``` r
scaled_temp_effect(params, t)
```

## Arguments

- params:

  A `MizerParams` object that has been prepared for therMizer, typically
  with
  [`upgradeTherParams()`](https://sizespectrum.org/therMizer/reference/upgradeTherParams.md).

- t:

  Numeric time in the same units as the first dimension of
  `other_params(params)$ocean_temp`. If `t` falls outside the supplied
  time series, the temperature series is recycled cyclically.

## Value

A numeric matrix with species in rows and size classes in columns.

## Details

The scalar is calculated separately for each realm, multiplied by the
corresponding exposure and vertical migration weights, and then summed
across realms. Values are set to 0 outside each species' thermal limits.

## See also

[`upgradeTherParams()`](https://sizespectrum.org/therMizer/reference/upgradeTherParams.md),
[`setEncounterPredScale()`](https://sizespectrum.org/therMizer/reference/setEncounterPredScale.md),
and
[`setVerticality()`](https://sizespectrum.org/therMizer/reference/setVerticality.md).

## Examples

``` r
# \donttest{
params <- suppressMessages(
  mizer::newMultispeciesParams(
    data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
               k_vb = c(0.3, 0.2), w_mat = c(10, 100),
               beta = c(100, 100), sigma = c(2, 2)),
    no_w = 16))
params <- suppressWarnings(suppressMessages(
  upgradeTherParams(params,
    temp_min = c(-2, 5), temp_max = c(12, 18),
    ocean_temp_array = c("2000" = 5, "2001" = 6, "2002" = 7))))
# Returns a species x size matrix of temperature scalars
ste <- scaled_temp_effect(params, t = 2001)
dim(ste)  # nrow = n_species, ncol = n_size_classes
#> [1]  2 16
# }
```
