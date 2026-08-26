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
  with
  [`upgradeTherParams()`](https://sizespectrum.org/therMizer/reference/upgradeTherParams.md).

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
species_params(params)$temp_min <- c(-2, 5)
species_params(params)$temp_max <- c(12, 18)
params <- setEncounterPredScale(params)
species_params(params)$encounterpred_scale
#>      sp1      sp2 
#> 5653.075 5172.333 
```
