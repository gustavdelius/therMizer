# Resource forcing from `n_pp_array`

therMizer resource dynamics function that reads the time-varying
plankton forcing stored in `other_params(params)$n_pp_array`.

## Usage

``` r
plankton_forcing(params, t, ...)
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

A numeric vector of resource densities over `params@w_full`.

## Details

The function selects the row corresponding to time `t`, converts the
stored log-scale spectrum back to density with `10^x / params@dw_full`,
and sets bins above `w_pp_cutoff` to 0. If `t` falls outside the
supplied time series, the series is recycled cyclically.
