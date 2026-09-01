#' Upgrade a therMizer object from an earlier version of therMizer
#'
#' This is the `therMizer` method of the `utils::upgrade()` generic (on which
#' mizer registers its own methods). It performs only the therMizer-specific
#' migration and is invoked by mizer's upgrade orchestrator (from
#' `validParams()` / `readParams()`) when the version stamp recorded in
#' `params$extensions[["therMizer"]]` is older than the installed therMizer,
#' or is missing. The orchestrator records the new stamp afterwards, so this
#' method must **not** stamp the version itself and must **not** call
#' `NextMethod()`. It is written to be idempotent.
#'
#' @param object A `therMizer` object to be upgraded.
#' @param ... Unused.
#'
#' @return The upgraded object.
#' @exportS3Method utils::upgrade
#' @keywords internal
upgrade.therMizer <- function(object, ...) {
    object
}
