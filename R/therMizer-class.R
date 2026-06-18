### S4 marker classes for the therMizer extension
#
# These classes carry no new slots; they exist only as dispatch labels so that
# mizer's generic functions and the project* rate generics can dispatch to
# therMizer's methods. All therMizer-specific state lives in
# other_params(params). See the "Creating a mizer extension package" vignette in
# mizer for the rationale.

#' @export
setClass("therMizer", contains = "MizerParams")

#' @export
setClass("therMizerSim", contains = "MizerSim")
