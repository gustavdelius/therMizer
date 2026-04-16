# Add realm-specific temperature structure to a therMizer model

Store vertical migration and exposure information in a `MizerParams`
object so temperature effects can be combined across multiple realms.

## Usage

``` r
setVerticality(params, vertical_migration_array, exposure_array = NULL)
```

## Arguments

- params:

  A `MizerParams` object to augment.

- vertical_migration_array:

  Optional array of dimensions realm x species x size giving the
  fraction of time each species spends in each realm at each size.
  Values must be non-negative and sum to 1 across realms for every
  species-size combination.

- exposure_array:

  Optional array of dimensions realm x species with values between 0 and
  1 describing how strongly each species is exposed to temperature in
  each realm.

## Value

The modified `params` object with
`other_params(params)$vertical_migration` and
`other_params(params)$exposure` filled in.

## Details

If `ocean_temp_array` has no realm dimension, it is expanded to one
column per realm in `vertical_migration_array`. When `exposure_array` is
omitted, exposure is inferred from whether a species occupies a realm at
any size class.

## Examples

``` r
# \donttest{
params <- suppressMessages(
  mizer::newMultispeciesParams(
    data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
               k_vb = c(0.3, 0.2), w_mat = c(10, 100),
               beta = c(100, 100), sigma = c(2, 2)),
    no_w = 16))
#> Warning: The species parameter data frame is missing a `w_max` column. I am copying over the values from the `w_inf` column. But note that `w_max` should be the maximum size of the largest individual, not the asymptotic size of an average indivdidual.
#> Warning: The species parameter data frame is missing a `w_max` column. I am copying over the values from the `w_inf` column. But note that `w_max` should be the maximum size of the largest individual, not the asymptotic size of an average indivdidual.
species_params(params)$temp_min <- c(-2, 5)
species_params(params)$temp_max <- c(12, 18)

# Store a two-realm temperature array in params before calling setVerticality
ocean_temp <- array(
  c(4, 8, 5, 9, 6, 10),
  dim = c(3, 2),
  dimnames = list(time = c("2000", "2001", "2002"),
                  realm = c("surface", "deep")))
other_params(params)$ocean_temp <- ocean_temp

# sp1 stays in the surface realm; sp2 stays in the deep realm
vm <- array(0,
  dim = c(2, 2, length(params@w)),
  dimnames = list(realm = c("surface", "deep"),
                  sp = c("sp1", "sp2"), w = params@w))
vm["surface", "sp1", ] <- 1
vm["deep",    "sp2", ] <- 1

params <- setEncounterPredScale(params)
params <- setMetabTher(params)
params <- setVerticality(params, vm)
str(other_params(params)$exposure)
#>  num [1:2, 1:2] 1 0 0 1
#>  - attr(*, "dimnames")=List of 2
#>   ..$ realm: chr [1:2] "surface" "deep"
#>   ..$ sp   : chr [1:2] "sp1" "sp2"
# }
```
