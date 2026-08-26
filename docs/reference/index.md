# Package index

## Model setup

Functions for combining a standard mizer `MizerParams` object with
therMizer’s temperature forcing, realm structure, and rate functions.

- [`upgradeTherParams()`](upgradeTherParams.md) :

  Upgrade a `MizerParams` object for therMizer

- [`setVerticality()`](setVerticality.md) : Add realm-specific
  temperature structure to a therMizer model

## Scaling parameters

Functions that compute the species-specific constants used to normalise
the encounter/predation and metabolism temperature responses to the \[0,
1\] interval. These are called automatically by
[`upgradeTherParams()`](../reference/upgradeTherParams.md) but are also
exported for direct use.

- [`setEncounterPredScale()`](setEncounterPredScale.md) : Set the
  encounter and predation scaling constant
- [`setMetabTher()`](setMetabTher.md) : Set metabolism temperature
  scaling parameters

## Temperature-scaled rate functions

Drop-in replacements for mizer’s built-in rate functions that
incorporate temperature effects. Registered automatically by
[`upgradeTherParams()`](../reference/upgradeTherParams.md) and called
internally by
[`project()`](https://sizespectrum.org/mizer/reference/project.html).

- [`therMizerEncounter()`](therMizerEncounter.md) : Temperature-scaled
  encounter rate

- [`therMizerPredRate()`](therMizerPredRate.md) : Temperature-scaled
  predation mortality

- [`therMizerEReproAndGrowth()`](therMizerEReproAndGrowth.md) :
  Temperature-scaled energy for growth and reproduction

- [`plankton_forcing()`](plankton_forcing.md) :

  Resource forcing from `n_pp_array`

## Diagnostics

Functions for inspecting the temperature scalars that therMizer applies
at each time step.

- [`scaled_temp_effect()`](scaled_temp_effect.md) : Calculate the
  encounter and predation temperature scalar

## Visualisation

Plotting functions for exploring species’ thermal performance curves and
the time-varying temperature scalars they experience.

- [`plotTherPerformance()`](plotTherPerformance.md) : Plot thermal
  performance curves
- [`plotTherScalar()`](plotTherScalar.md) : Plot time-varying thermal
  scalars

## Package

- [`therMizer`](therMizer-package.md)
  [`therMizer-package`](therMizer-package.md) : therMizer: Extends the
  mizer package with temperature dynamics
