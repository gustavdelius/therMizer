#' therMizer extension classes
#'
#' S3 extension classes for [MizerParams] and [MizerSim] that enable S3 dispatch
#' for extension-specific methods.
#'
#' The class names are ordinary entries in the object's S3 class vector. All
#' extension-specific data lives in `other_params(params)` or in component
#' parameters.
#'
#' Objects of class `therMizer` are created by [upgradeTherParams()].
#' Objects of class `therMizerSim` are returned automatically by [project()]
#' when called on a `therMizer` params object.
#'
#' No class declaration is needed. [upgradeTherParams()] records the
#' extension on the object with [mizer::recordExtension()] and then calls
#' [mizer::coerceToExtensionClass()].
#'
#' @name therMizer-class
#' @keywords internal
NULL
