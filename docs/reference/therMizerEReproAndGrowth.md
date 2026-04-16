# Temperature-scaled energy for growth and reproduction

therMizer implementation of mizer's `EReproAndGrowth` rate function. The
assimilation term is calculated from encounter, while maintenance
metabolism is multiplied by a temperature scalar that is aggregated
across realms.

## Usage

``` r
therMizerEReproAndGrowth(params, t, encounter, feeding_level, ...)
```

## Arguments

- params:

  A `MizerParams` object that has been prepared for therMizer, typically
  with [`upgradeTherParams()`](upgradeTherParams.md).

- t:

  Numeric time in the same units as the first dimension of
  `other_params(params)$ocean_temp`. If `t` falls outside the supplied
  time series, the temperature series is recycled cyclically.

- encounter:

  Numeric array of encounter rates, as returned by
  [`getEncounter()`](https://sizespectrum.org/mizer/reference/getEncounter.html).

- feeding_level:

  Numeric array of feeding levels, as returned by
  [`getFeedingLevel()`](https://sizespectrum.org/mizer/reference/getFeedingLevel.html).

- ...:

  Additional arguments passed through by mizer's internal rate function
  machinery.

## Value

A numeric matrix with the same dimensions as `encounter`.
