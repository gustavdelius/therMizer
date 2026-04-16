# Temperature-scaled predation mortality

therMizer implementation of mizer's `PredRate` rate function. It applies
the encounter temperature scalar to predation mortality.

## Usage

``` r
therMizerPredRate(params, n, n_pp, n_other, t, feeding_level, ...)
```

## Arguments

- params:

  A `MizerParams` object that has been prepared for therMizer, typically
  with [`upgradeTherParams()`](upgradeTherParams.md).

- n:

  Numeric matrix of species abundances with species in rows and size
  classes in columns.

- n_pp:

  Numeric vector giving the background resource abundance by size.

- n_other:

  List of abundances for any other dynamic ecosystem components.

- t:

  Numeric time in the same units as the first dimension of
  `other_params(params)$ocean_temp`. If `t` falls outside the supplied
  time series, the temperature series is recycled cyclically.

- feeding_level:

  Numeric array of feeding levels, as returned by
  [`getFeedingLevel()`](https://sizespectrum.org/mizer/reference/getFeedingLevel.html).

- ...:

  Additional arguments passed through by mizer's internal rate function
  machinery.

## Value

A numeric array with the same structure expected from mizer's `PredRate`
rate function.

## Details

If `params` uses a custom predation kernel, the function falls back to
the non-FFT implementation used by older versions of mizer.
