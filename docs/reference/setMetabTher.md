# Set metabolism temperature scaling parameters

Compute the minimum and range of the Arrhenius-style metabolism response
over each species' thermal range. These values are later used to scale
metabolic effects between 0 and 1.

## Usage

``` r
setMetabTher(params)
```

## Arguments

- params:

  A `MizerParams` object that has been prepared for therMizer, typically
  with [`upgradeTherParams()`](upgradeTherParams.md).

## Value

The modified `params` object with `species_params(params)$metab_min` and
`species_params(params)$metab_range` filled in.

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
params <- setMetabTher(params)
species_params(params)$metab_min
#>       sp1       sp2 
#> 0.1739570 0.3430521 
species_params(params)$metab_range
#>       sp1       sp2 
#> 0.4803643 0.7672018 
```
