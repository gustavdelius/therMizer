# therMizer 1.1.0

- Replaced obsolete session extension registration and dynamic S4 marker
  classes with mizer's simpler S3 extension mechanism. Stored parameter
  objects are now S3 objects with extension class vector
  `c("therMizer", "MizerParams")`, removing the need for a load hook or an active
  binding.
- Removed obsolete workaround that pinned `gamma` in `given_species_params`,
  as mizer now evaluates default parameters on its baseline reference state.
