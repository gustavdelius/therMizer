# Temperature-scaled encounter rate

therMizer implementation of mizer's `Encounter` rate function. It
multiplies the default encounter rate by
[`scaled_temp_effect()`](scaled_temp_effect.md).

## Usage

``` r
therMizerEncounter(params, t, ...)
```

## Arguments

- params:

  A `MizerParams` object that has been prepared for therMizer, typically
  with [`upgradeTherParams()`](upgradeTherParams.md).

- t:

  Numeric time in the same units as the first dimension of
  `other_params(params)$ocean_temp`. If `t` falls outside the supplied
  time series, the temperature series is recycled cyclically.

- ...:

  Additional arguments passed through by mizer's internal rate function
  machinery.

## Value

A numeric matrix with the same dimensions as the value returned by
[`mizer::mizerEncounter()`](https://sizespectrum.org/mizer/reference/mizerEncounter.html).
