#' Run Complete Electoral Simulation
#'
#' This function executes the complete VOTA system pipeline for
#' Spanish electoral simulation, starting from national-level data.
#'
#' @param survey_data Data frame with individual survey data (required if uncertainty_method is "bootstrap")
#' @param input_path Path to Excel input file with multiple sheets
#' @param output_file Path to the output RDS file where the electo_fit object will be saved (e.g., "output/results.rds")
#' @param uncertainty_method Type of input data: "bootstrap" or "mcmc"
#' @param strategy Projection strategy: "top_down" or "bottom_up"
#' @param nsims Number of Monte Carlo simulations for transfer matrices (or bootstrap replications if uncertainty_method is "bootstrap")
#' @param factor_correccion_abstencion Abstention correction factor (default 3)
#' @param factor_correccion_jovenes New voters correction factor (default 2.5)
#' @param factor_correccion_otbl Other+blank votes intention correction factor (default 3)
#' @param tiempo_entre_elecciones Years between elections for demographic adjustments
#' @param district_col Name of column in survey_data indicating province or electoral district
#' @param tau Parameter to control variability level of provincial party projection patterns (only needed if strategy is "top_down")
#' @param umbral Minimum vote threshold for seat assignment (default 0.03)
#' @param tipo_umbral Threshold type: "provincial", "autonomico" or "mixto" (default "provincial")
#' @param interval_level Confidence level for uncertainty intervals (default 0.9)
#' @param censo Optional data frame with census data per province (columns: codigo_provincia, censo_real). If NULL (default), census data is downloaded from INE using `get_censo()`.
#' @param verbose Show progress messages (default TRUE)
#' @param seed Seed for reproducibility (default NULL)
#' @param ... Additional arguments for bootstrap internal function. The current accepted parameters are calib_vars and weights. Only used when uncertainty_method is "bootstrap"
#'
#' @return Object of class electo_fit with simulation results including:
#' \describe{
#'  \item{estimacion}{National vote estimates by party}
#'  \item{estimacion_sims}{National vote estimates simulations by party}
#'  \item{estimacion_provincias_sims}{Provincial results with assigned seats}
#'  \item{mt_sims_pct}{Transfer matrix simulations (percentages)}
#'  \item{mt_sims_electores}{Transfer matrix simulations (number of voters)}
#'  \item{dhondt_output}{Detailed D'Hondt allocation results}
#'  \item{participacion_media}{Estimated turnout percentage}
#'  \item{metadata}{Execution metadata}
#'  }
#'
#' @family main-functions
#' @family simulation-pipeline
#' @export
run_vota <- function(survey_data = NULL,
                     input_path,
                     output_file,
                     uncertainty_method = c("mcmc", "bootstrap"),
                     strategy = "top_down",
                     nsims = 100,
                     factor_correccion_abstencion = 3,
                     factor_correccion_jovenes = 2.5,
                     factor_correccion_otbl = 3,
                     tiempo_entre_elecciones = 0.1,
                     district_col,
                     tau = 300,
                     umbral = .03,
                     tipo_umbral = "provincial",
                     interval_level = .9,
                     censo = NULL,
                     verbose = TRUE,
                     seed = NULL, ...) {
  input_params <- as.list(environment(), all = TRUE)
  params <- do.call(validate_params, input_params)

  if (verbose) message(emoji(0x1f5f3), " Starting VOTA electoral simulation...")
  tryCatch(
    {
      # 1. Load and validate data
      if (verbose) message(emoji(0x1f4cb), " Loading input data...")
      data_list <- load_and_validate(
        input_path = params$data$input_path,
        uncertainty_method = params$simulation$uncertainty_method,
        strategy = params$simulation$strategy,
        verbose = params$runtime$verbose
      )

      if (params$simulation$uncertainty_method == "mcmc") {
        params$data$input_data <- data_list$mt_simplificada
      }

      params$additional_args <- data_list

      # 2. Execute simulation pipeline
      results <- do.call(execute_simulation_pipeline, prepare_pipeline_args(params, ...))
      if (verbose) message(emoji(0x1f389), " Estimacion completada exitosamente!")

      # 3. Create electo_fit object
      electo_fit <- new_electo_fit(results)

      # 4. Save electo_fit object
      if (!missing(output_file) && !is.null(output_file)) {
        output_dir <- dirname(output_file)
        if (!dir.exists(output_dir)) {
          dir.create(output_dir, recursive = TRUE)
        }
        saveRDS(electo_fit, output_file)
        if (verbose) message(emoji(0x1f4be), " Results saved to: ", output_file)
      }

      return(electo_fit)
    },
    error = function(e) {
      stop(e$message, call. = FALSE)
    }
  )
}
