# scripts containing all plot functions of the package

# to appease R CMD checks
utils::globalVariables(c("Scalar", "Species", "Time", "Type", "scalar",
                         "temperature"))

# common theme for the package
therTheme <- function(){
  theme(
    panel.background = element_blank(),
    panel.grid.minor = element_line(color = "grey"),
    strip.background = element_blank(),
    legend.key = element_blank()
  )
}

#' Plot thermal performance curves
#'
#' Plot the encounter and metabolic temperature response curves implied by the
#' species-level thermal parameters stored in \code{params}.
#'
#' @param params A therMizer-enabled \code{MizerParams} object
#'   containing species thermal limits and derived scaling parameters.
#'
#' @param return_data Logical. If \code{TRUE}, return the long-format data frame
#'   used to build the plot instead of a \code{ggplot2} object. Default is
#'   \code{FALSE}.
#' @param resolution Numeric step size, in degrees C, between temperature values
#'   used to evaluate the curves. Default is \code{0.2}.
#'
#' @returns Either a \code{ggplot2} object or, when \code{return_data = TRUE}, a
#'   data frame with columns \code{temperature}, \code{Species},
#'   \code{scalar}, and \code{Type}.
#'
#' @seealso \code{\link{plotTherScalar}()}.
#'
#' @examples
#' \donttest{
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#' params <- suppressWarnings(suppressMessages(
#'   upgradeTherParams(params,
#'     temp_min = c(-2, 5), temp_max = c(12, 18),
#'     ocean_temp_array = c("2000" = 5))))
#' plotTherPerformance(params)
#'
#' # Return the underlying data instead of a plot
#' df <- plotTherPerformance(params, return_data = TRUE)
#' head(df)
#' }
#'
#' @export

plotTherPerformance <- function(params, resolution = .2, return_data = FALSE){

  temp_vec <- seq(min(params@species_params$temp_min), max(params@species_params$temp_max), resolution)
  scalar <- NULL
  scalarM <- NULL

  for(iTemp in temp_vec){

    temp_at_t <- iTemp + 273

    # Encounter rate

    # Calculate unscaled temperature effect using a generic polynomial rate equation
    unscaled_temp_effect <-
      temp_at_t * (temp_at_t - (species_params(params)$temp_min + 273)) *
      (species_params(params)$temp_max - temp_at_t + 273)^(1/2)

    # Scale using new parameter
    scaled_temp_effect_r <- unscaled_temp_effect / species_params(params)$encounterpred_scale

    # Set temperature effect to 0 if temperatures are outside thermal tolerance limits
    above_max <- (temp_at_t - 273) > species_params(params)$temp_max
    below_min <- (temp_at_t - 273) < species_params(params)$temp_min

    scaled_temp_effect_r[above_max | below_min] = 0

    scalar <- rbind(scalar,scaled_temp_effect_r)

    # Metabolism

    # Arrhenius equation
    unscaled_temp_effect <- (exp(25.22 - (0.63/((8.62e-5)*(temp_at_t)))))

    # Arrhenius equation scaled to a value between 0 and 1
    temp_effect_metabolism <-
      (unscaled_temp_effect - species_params(params)$metab_min) /
      species_params(params)$metab_range

    # Set temperature effect to 0 if temperatures are outside thermal
    # tolerance limits
    above_max <- (temp_at_t - 273) > species_params(params)$temp_max
    below_min <- (temp_at_t - 273) < species_params(params)$temp_min
    temp_effect_metabolism[above_max | below_min] = 0

    scalarM <- rbind(scalarM, temp_effect_metabolism)

  }
  # plot

  rownames(scalar) <- rownames(scalarM) <- temp_vec
  colnames(scalar) <- colnames(scalarM) <- params@species_params$species
  plot_dat <- reshape2::melt(scalar)
  plot_datM <- reshape2::melt(scalarM)
  colnames(plot_dat) <- colnames(plot_datM) <- c("temperature","Species","scalar")
  plot_dat$Type <- "Encounter"
  plot_datM$Type <- "Metabolism"

  plot_dat <- rbind(plot_dat, plot_datM)
  plot_dat$Type <- factor(plot_dat$Type, levels = c("Metabolism","Encounter"))

  # removing scalar = 0 except at the beginning and end of curve (for encounter)
  zero_keep <- NULL
  zero_val <- which(plot_dat$scalar == 0)
  for(i in 1:(length(zero_val)-1)){
    if(zero_val[i+1] != zero_val[i] + 1){
      if(plot_dat$Type[zero_val[i]] == "Encounter") zero_keep <- c(zero_keep, i, i+1)
      else zero_keep <- c(zero_keep, i)
    }
  }
  # zero keep has the position of the row to keep in zero_val
  zero_val <- zero_val[-zero_keep]
  plot_dat <-plot_dat[- zero_val,]

  p <- ggplot(plot_dat)+
    geom_line(aes(x = temperature, y = scalar, color = Type)) +
    scale_x_continuous("Temperature in C")+
    scale_y_continuous("Scalar value") +
    facet_wrap(~Species, scales = "free") +
    therTheme()

  if(return_data) return(plot_dat) else return(p)
}


#' Plot time-varying thermal scalars
#'
#' Plot the encounter and metabolism scalars experienced by each species
#' through time based on the temperature forcing stored in
#' \code{other_params(params)$ocean_temp}.
#'
#' @inheritParams plotTherPerformance
#'
#' @param species Optional character string giving a single species name to
#'   display. It must match one of the species names in \code{params}. Default
#'   is \code{NULL}, which keeps all species.
#' @param species_panel Logical. If \code{TRUE} and \code{species} is
#'   \code{NULL}, plot each species in a separate panel. Ignored when
#'   \code{species} is supplied. Default is \code{TRUE}.
#'
#' @returns Either a \code{ggplot2} object or, when \code{return_data = TRUE}, a
#'   data frame with columns \code{Time}, \code{Species}, \code{Scalar}, and
#'   \code{Type}.
#'
#' @seealso \code{\link{plotTherPerformance}()}.
#'
#' @examples
#' \donttest{
#' params <- suppressMessages(
#'   mizer::newMultispeciesParams(
#'     data.frame(species = c("sp1", "sp2"), w_inf = c(100, 1000),
#'                k_vb = c(0.3, 0.2), w_mat = c(10, 100),
#'                beta = c(100, 100), sigma = c(2, 2)),
#'     no_w = 16))
#' params <- suppressWarnings(suppressMessages(
#'   upgradeTherParams(params,
#'     temp_min = c(-2, 5), temp_max = c(12, 18),
#'     ocean_temp_array = c("2000" = 5, "2001" = 6, "2002" = 7))))
#'
#' # Plot both species in separate panels
#' plotTherScalar(params)
#'
#' # Plot a single species
#' plotTherScalar(params, species = "sp1")
#'
#' # Overlay both species on one panel
#' plotTherScalar(params, species_panel = FALSE)
#' }
#'
#' @export

plotTherScalar <- function(params, species = NULL, species_panel = TRUE, return_data = FALSE){

  params <- validParams(params)
  scalar_en <- NULL
  scalar_met <- NULL
  for(t in as.numeric(dimnames(other_params(params)$ocean_temp)[[1]])){
    # encounter
    scalar_en <- rbind(scalar_en, apply(scaled_temp_effect(params,t), 1, mean))

    # Metabolism
    temp_effect_metab_realms <- array(NA, dim = c(dim(other_params(params)$vertical_migration)), dimnames = c(dimnames(other_params(params)$vertical_migration)))

    # Using t+1 to avoid calling ocean_temp[0,] at the first time step
    # Looping through each realm
    nb_realms <- dim(other_params(params)$exposure)[1]
    for (r in seq(1, nb_realms, 1)) {
      index <- which.min(abs(as.numeric(dimnames(other_params(params)$ocean_temp)[[1]]) - t))
      temp_at_t <- other_params(params)$ocean_temp[index,r]
      # Arrhenius equation
      unscaled_temp_effect <- (exp(25.22 - (0.63/((8.62e-5)*(273 + temp_at_t)))))

      # Arrhenius equation scaled to a value between 0 and 1
      temp_effect_metabolism_r <- (unscaled_temp_effect - species_params(params)$metab_min) / species_params(params)$metab_range

      # Set temperature effect to 0 if temperatures are outside thermal tolerance limits
      above_max <- temp_at_t > species_params(params)$temp_max
      below_min <- temp_at_t < species_params(params)$temp_min

      temp_effect_metabolism_r[above_max | below_min] = 0

      temp_effect_metab_realms[r,,] <- temp_effect_metabolism_r*other_params(params)$exposure[r,]*other_params(params)$vertical_migration[r,,]
    }
    scalar_met <- rbind(scalar_met, apply(colSums(temp_effect_metab_realms), 1, mean))
  }
  rownames(scalar_en) <- rownames(scalar_met) <-as.numeric(dimnames(other_params(params)$ocean_temp)[[1]])

  plot_dat2 <- reshape2::melt(scalar_met)
  plot_dat2$Type <- "Metabolism"
  plot_dat <- reshape2::melt(scalar_en)
  plot_dat$Type <- "Encounter"
  plot_dat <- rbind(plot_dat, plot_dat2)
  names(plot_dat)[names(plot_dat) == "Var1"] <- "Time"
  names(plot_dat)[names(plot_dat) == "Var2"] <- "Species"
  names(plot_dat)[names(plot_dat) == "value"] <- "Scalar"

  if (!is.null(species)) {
    plot_dat <- plot_dat[plot_dat$Species == species, ]
    plot_dat$Species <- as.character(plot_dat$Species)
  }

  p <- ggplot(plot_dat, aes(x = Time, y = Scalar)) +
    scale_y_continuous(limits = c(0,1), name = "Scalar value") +
    scale_x_continuous(name = "Time in years")+
    therTheme()

  if(is.null(species) & species_panel){
    p <- p +
      geom_line(aes(color = Type))+
      facet_wrap(~Species) +
      scale_color_manual(values = c("#619CFF","#F8766D"))
  } else {
    p <- p +
      geom_line(aes(color = Species, linetype = Type)) +
      scale_color_manual(values = params@linecolour[params@species_params$species])
  }
  if(return_data) return(plot_dat) else return(p)
}
