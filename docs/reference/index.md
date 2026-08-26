# Package index

## Model setup

Functions for combining a standard mizer `MizerParams` object with
therMizer’s temperature forcing and realm structure. The result is a
`therMizer` object, whose temperature-scaled encounter, predation and
metabolism rates mizer dispatches to automatically during
[`project()`](https://sizespectrum.org/mizer/reference/project.html).

- [`upgradeTherParams()`](https://sizespectrum.org/therMizer/reference/upgradeTherParams.md)
  :

  Upgrade a `MizerParams` object for therMizer

- [`setVerticality()`](https://sizespectrum.org/therMizer/reference/setVerticality.md)
  : Add realm-specific temperature structure to a therMizer model

## Scaling parameters

Functions that compute the species-specific constants used to normalise
the encounter/predation and metabolism temperature responses to the \[0,
1\] interval. These are called automatically by
[`upgradeTherParams()`](https://sizespectrum.org/therMizer/reference/upgradeTherParams.md)
but are also exported for direct use.

- [`setEncounterPredScale()`](https://sizespectrum.org/therMizer/reference/setEncounterPredScale.md)
  : Set the encounter and predation scaling constant
- [`setMetabTher()`](https://sizespectrum.org/therMizer/reference/setMetabTher.md)
  : Set metabolism temperature scaling parameters

## Resource forcing

The resource dynamics function that reads the time-varying plankton
spectrum stored in the model.
[`upgradeTherParams()`](https://sizespectrum.org/therMizer/reference/upgradeTherParams.md)
installs it automatically when it is given an `n_pp_array`.

- [`plankton_forcing()`](https://sizespectrum.org/therMizer/reference/plankton_forcing.md)
  :

  Resource forcing from `n_pp_array`

## Diagnostics

Functions for inspecting the temperature scalars that therMizer applies
at each time step.

- [`scaled_temp_effect()`](https://sizespectrum.org/therMizer/reference/scaled_temp_effect.md)
  : Calculate the encounter and predation temperature scalar

## Visualisation

Plotting functions for exploring species’ thermal performance curves and
the time-varying temperature scalars they experience.

- [`plotTherPerformance()`](https://sizespectrum.org/therMizer/reference/plotTherPerformance.md)
  : Plot thermal performance curves
- [`plotTherScalar()`](https://sizespectrum.org/therMizer/reference/plotTherScalar.md)
  : Plot time-varying thermal scalars

## Package

- [`therMizer`](https://sizespectrum.org/therMizer/reference/therMizer-package.md)
  [`therMizer-package`](https://sizespectrum.org/therMizer/reference/therMizer-package.md)
  : therMizer: Extends the mizer package with temperature dynamics
