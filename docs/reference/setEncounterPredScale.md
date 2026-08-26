# Set the encounter and predation scaling constant

Compute the species-specific `encounterpred_scale` value used to
normalise the encounter and predation temperature response so that the
resulting scalar varies between 0 and 1 within each species' thermal
range.

## Usage

``` r
setEncounterPredScale(params)
```

## Arguments

- params:

  A `MizerParams` object that has been prepared for therMizer, typically
  with [`upgradeTherParams()`](upgradeTherParams.md).

## Value

The modified `params` object with
`species_params(params)$encounterpred_scale` filled in.

## Examples

``` r
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
params <- setEncounterPredScale(params)
species_params(params)$encounterpred_scale
#> [1] 5653.075 5172.333
```
