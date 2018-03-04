#' Create a plot from a \code{stanguts} object
#' 
#' @param x an object used to select a method \code{plot_stanguts}
#' @param \dots Further arguments to be passed to generic methods
#' 
#' @export
plot_stanguts <- function(x, ...){
  UseMethod("plot_stanguts")
}

#' Plotting method for \code{stanguts} objects
#'
#' This is a \code{plot} method for the
#' \code{stanguts} object.  It plots the fit obtained for each
#' profile of chemical compound in the original dataset.
#'
#' The fitted curves represent the \strong{estimated survival rate} as a function
#' of time for each profile of concentration.
#' The black dots depict the \strong{observed survival
#' rate} at each time point.
#' The function plots both 95\% binomial credible intervals for the estimated survival
#' rate (by default the grey area around the fitted curve).
#' 
#' 
#'
#' @param x An object of class \code{stanguts}.
#' @param data_type The type of data to plot: either \code{"Rate"} for the
#'   survival rate, or \code{"Number"} for the number of survivors. The
#'   default is the survival rate.
#'  
#' @return An object of class \code{("gg","ggplot")}. See package \code{ggplot2} 
#'   for further information..
#' 
#' @examples
#'
#' # (1) Load the survival data
#' data("data_Diazinon")
#'
#' \dontrun{
#' # (2) Run the stan_guts function with TK-TD model 'SD', 'IT', or 'PROPER' (and distribution) 
#' fit_SD_diaz <- stan_guts(data_Diazinon, model_type = "SD")
#'
#' # (3) Plot the fitted curve
#' plot_stanguts(fit_SD_diaz)
#' }
#' 
#' @export
#' 
#' @import ggplot2
#'
#' 
plot_stanguts.stanguts <- function(x,
                                   data_type = "Rate"){
  
  x_stanfit <- x$stanfit
  x_data <- x$dataStan
  
  if(data_type == 'Number'){
    
    Nsurv_sim <- extract(x_stanfit, pars = 'Nsurv_sim')
    
    df_Nsurv <- data.frame(Nsurv = x_data$Nsurv,
                           time = x_data$tNsurv,
                           replicate = x_data$replicate_Nsurv,
                           q50 = apply(Nsurv_sim[[1]], 2, quantile, 0.5),
                           qinf95 = apply(Nsurv_sim[[1]], 2, quantile, 0.025),
                           qsup95 = apply(Nsurv_sim[[1]], 2, quantile, 0.975))
    
    y_limits = c(0,max(df_Nsurv$Nsurv, df_Nsurv$qsup95))
    
  } else if(data_type == 'Rate'){
    
    Psurv_sim <- extract(x_stanfit, pars = 'Psurv_hat')
    
    df_Nsurv <- data.frame(Nsurv = x_data$Nsurv/x_data$Ninit,
                           time = x_data$tNsurv,
                           replicate = x_data$replicate_Nsurv,
                           q50 = apply(Psurv_sim[[1]], 2, quantile, 0.5),
                           qinf95 = apply(Psurv_sim[[1]], 2, quantile, 0.025),
                           qsup95 = apply(Psurv_sim[[1]], 2, quantile, 0.975))
    
    y_limits = c(0,1)
    
  } else stop("'data_type' must be 'Rate' for the survival rate, or 'Number' for the number of survivors")
  
  plot <- ggplot(data = df_Nsurv) + theme_bw() +
    scale_y_continuous(limits = y_limits) +
    geom_pointrange( aes(x = time, y = q50, ymin = qinf95, ymax = qsup95, group = replicate), color = "red", size = 0.2) +
    geom_line(aes(x = time, y = q50,  group = replicate), color = "red") +
    geom_ribbon(aes(x= time, ymin = qinf95, ymax = qsup95, group = replicate), fill = "pink", alpha = 0.2)+
    geom_point( aes(x = time, y = Nsurv, group = replicate) ) +
    #geom_errorbar( aes(x = time, ymin = qinf95, ymax = qsup95, group = replicate), color = "pink", width = 0.5) +
    facet_wrap(~ replicate)
  
  return(plot)
}