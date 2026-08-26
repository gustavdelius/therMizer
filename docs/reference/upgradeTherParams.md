# Upgrade a `MizerParams` object for therMizer

Add therMizer-specific thermal parameters, temperature forcing, optional
plankton forcing, and realm structure to a standard `MizerParams`
object.

## Usage

``` r
upgradeTherParams(
  params,
  temp_min = NULL,
  temp_max = NULL,
  ocean_temp_array = NULL,
  n_pp_array = NULL,
  vertical_migration_array = NULL,
  exposure_array = NULL,
  aerobic_effect = TRUE,
  metabolism_effect = TRUE,
  info_level = default_info_level()
)
```

## Arguments

- params:

  A `MizerParams` object to augment.

- temp_min:

  Numeric vector giving the lower thermal limit of each species, in
  degrees C. Its length must match the number of species in `params`.

- temp_max:

  Numeric vector giving the upper thermal limit of each species, in
  degrees C. Its length must match the number of species in `params`.

- ocean_temp_array:

  Numeric scalar, vector, matrix, or array of temperatures. The first
  dimension is interpreted as time. If a second dimension is present it
  is interpreted as realms. Character time labels in `%Y`, `%Y-%m`, or
  `%Y-%m-%d` format are converted to numeric years.

- n_pp_array:

  Optional vector, matrix, or array of plankton forcing with dimensions
  time x size. The time dimension must match `ocean_temp_array`, and the
  size dimension must match `params@w_full`. Values are interpreted on
  the log10 scale used by [`plankton_forcing()`](plankton_forcing.md).

- vertical_migration_array:

  Optional array of dimensions realm x species x size giving the
  fraction of time each species spends in each realm at each size.
  Values must be non-negative and sum to 1 across realms for every
  species-size combination.

- exposure_array:

  Optional array of dimensions realm x species with values between 0 and
  1 describing how strongly each species is exposed to temperature in
  each realm.

- aerobic_effect:

  Logical. If `TRUE`, activate therMizer's temperature scaling for
  encounter and predation-rate calculations. Default is `TRUE`.

- metabolism_effect:

  Logical. If `TRUE`, activate therMizer's temperature scaling for
  maintenance metabolism in the energy-for-growth-and-reproduction
  calculation. Default is `TRUE`.

- info_level:

  Integer controlling how much therMizer reports about the choices it
  made on your behalf, in the same way as mizer's own setup functions.
  Use `0` for silence. Default is
  [`default_info_level()`](https://sizespectrum.org/mizer/reference/default_info_level.html).

## Value

The modified `params` object, ready to use with therMizer.

## Details

Because therMizer scales the encounter rate with temperature, the
current value of the calculated species parameter `gamma` is declared as
a given species parameter, so that mizer does not later recalculate it
from an encounter rate that already carries the temperature scalar. Set
`given_species_params(params)$gamma <- NA` to hand it back to mizer.

If `vertical_migration_array` is omitted, a default realm allocation is
constructed from the available temperature data. If `n_pp_array` is
supplied, the resource dynamics function is set to
[`plankton_forcing()`](plankton_forcing.md). The returned object also
stores a time offset in `other_params(params)$t_idx` so therMizer can
align mizer's simulation time with the supplied forcing series.

## See also

[`setVerticality()`](setVerticality.md),
[`setEncounterPredScale()`](setEncounterPredScale.md),
[`setMetabTher()`](setMetabTher.md), and
[`plankton_forcing()`](plankton_forcing.md).

## Examples

``` r
# \donttest{
params <- suppressMessages(
  mizer::newMultispeciesParams(
    data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
               k_vb = c(0.3, 0.2), w_mat = c(10, 100),
               beta = c(100, 100), sigma = c(2, 2)),
    no_w = 16))

# Minimal usage: constant temperature, one realm per species
params <- suppressWarnings(suppressMessages(
  upgradeTherParams(params,
    temp_min = c(-2, 5), temp_max = c(12, 18),
    ocean_temp_array = c("2000" = 5, "2001" = 6, "2002" = 7))))

# Project for 2 years starting from the first temperature time step
sim <- project(params, t_start = 2000, t_max = 2, dt = 1)

# Two realms: sp1 lives at the surface, sp2 in the deep
ocean_temp <- array(
  c(4, 8, 5, 9, 6, 10),
  dim = c(3, 2),
  dimnames = list(time = c("2000", "2001", "2002"),
                  realm = c("surface", "deep")))
vm <- array(0,
  dim = c(2, 2, length(params@w)),
  dimnames = list(realm = c("surface", "deep"),
                  sp = c("sp1", "sp2"), w = params@w))
vm["surface", "sp1", ] <- 1
vm["deep",    "sp2", ] <- 1
params2 <- suppressWarnings(suppressMessages(
  upgradeTherParams(params,
    temp_min = c(-2, 5), temp_max = c(12, 18),
    ocean_temp_array = ocean_temp,
    vertical_migration_array = vm)))
sim2 <- project(params2, t_start = 2000, t_max = 2, dt = 1)
# }
```
