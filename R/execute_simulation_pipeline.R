#' Execute the full simulation pipeline
#'
#' This function orchestrates the complete electoral simulation process,
#' from drawing simulated vote shares to allocating seats and aggregating results.
#'
#' @param data Data frame with polling data.
#' @param retoques Data frame with adjustments to be applied.
#' @param small_parties Data frame with small party votes.
#' @param votos_ant Data frame with previous electoral results (column votos_ant).
#' @param patrones Data frame with district-level voting patterns.
#' @param n_seats Data frame with number of seats per district.
#' @param uncertainty_method Method for introducing uncertainty in simulations (e.g., "mcmc", "bootstrap").
#' @param strategy Strategy for simulation ("top_down" or "bottom_up").
#' @param nsims Number of simulations to run.
#' @param factor_correccion_abstencion Correction factor for abstention.
#' @param factor_correccion_jovenes Correction factor for new voters.
#' @param factor_correccion_otbl Correction factor for other blank/null votes.
#' @param tiempo_entre_elecciones Years between elections for demographic adjustments.
#' @param district_col Name of column in survey_data indicating province or electoral district
#' @param tau Parameter to control variability level of provincial party projection patterns (only needed if strategy is "top_down")
#' @param umbral Minimum vote threshold for seat assignment (default 0.03)
#' @param tipo_umbral Threshold type: "provincial", "autonomico" or "mixto" (default "provincial")
#' @param interval_level Confidence level for uncertainty intervals (default 0.9)
#' @param censo Optional data frame with census data per province (columns: codigo_provincia, censo_real). If NULL (default), downloaded from INE.
#' @param seed Seed for reproducibility (default NULL)
#' @param verbose Show progress messages (default TRUE)
#' @param ... Additional arguments for bootstrap internal function. The current accepted parameters are calib_vars and weights. Only used when uncertainty_method is "bootstrap"
#'
#' @return A list with simulation results and metadata.
#'
#' @keywords internal
#'
execute_simulation_pipeline <- function(data, retoques, small_parties, votos_ant,
                                        patrones, n_seats,
                                        uncertainty_method,
                                        strategy,
                                        nsims,
                                        factor_correccion_abstencion,
                                        factor_correccion_jovenes,
                                        factor_correccion_otbl,
                                        tiempo_entre_elecciones,
                                        district_col,
                                        tau,
                                        umbral,
                                        tipo_umbral,
                                        interval_level,
                                        censo = NULL,
                                        verbose,
                                        seed, ...) {
  mt_sims <- draw_mt(
    data = data, district_col = district_col,
    uncertainty_method = uncertainty_method,
    strategy = strategy,
    nsims = nsims, seed = seed,
    verbose = verbose, ...
  )

  # 3. Execute VOTA algorithm
  if (verbose) message(emoji(0x2728), " Executing VOTA algorithm...")
  vota_results <- execute_vota(
    strategy = strategy,
    mt_sims = mt_sims,
    factor_correccion_abstencion = factor_correccion_abstencion,
    factor_correccion_jovenes = factor_correccion_jovenes,
    factor_correccion_otbl = factor_correccion_otbl,
    tiempo_entre_elecciones = tiempo_entre_elecciones,
    retoques = retoques,
    small_parties = small_parties,
    votos_ant = votos_ant,
    district_col = district_col
  )

  estimacion_previa_sims <- vota_results$estimacion_previa_sims
  mt_sims_electores <- vota_results$mt_sims_electores

  if (strategy == "top_down") {
    # 4. Provincial projection and D'Hondt
    if (verbose) message(paste0(emoji(0x1f5fa), emoji(0xfe0f)), " Projecting to provincial level...")
    resultados_provincias <-
      project_to_districts(
        estimacion_previa_sims = estimacion_previa_sims,
        patrones = patrones,
        n_seats = n_seats,
        tau = tau,
        seed = derive_seed(seed, 2),
        umbral = umbral, tipo_umbral = tipo_umbral,
        censo = censo
      )
  } else {
    # 4. D'Hondt
    if (verbose) message(paste0(emoji(0x1f5fa), emoji(0xfe0f)), " Allocating seats...")

    resultados_provincias <-
      allocate_seats(
        votos_provincias_sims = estimacion_previa_sims,
        n_seats = n_seats,
        umbral = umbral,
        tipo_umbral = tipo_umbral
      )
  }

  votos_provincias_sims <- resultados_provincias$votos_provincias_sims
  dhondt_output <- resultados_provincias$dhondt_output


  # 5. Aggregate results
  if (verbose) message(emoji(0x1f4be), " Aggregating and exporting results...")
  participacion_media <-
    votos_provincias_sims %>%
    mutate(participa = ifelse(partido == "ABNL", F, T)) %>%
    group_by(sim, participa) %>%
    summarise(votos = sum(votos_salida, na.rm = T), .groups = "drop_last") %>%
    mutate(pct = round(votos / sum(votos) * 100, 2)) %>%
    group_by(participa) %>%
    summarise(participacion = round(mean(pct), 1)) %>%
    filter(participa) %>%
    pull(participacion)

  estimacion <- aggregate_results(votos_provincias_sims, interval_level)
  lvls <- levels(estimacion$partido)

  estimacion_provincias_sims <-
    votos_provincias_sims %>%
    mutate(
      partido = factor(partido, levels = lvls),
      sim = as.numeric(sim)
    ) %>%
    arrange(sim, !!sym(district_col), partido)

  estimacion_sims <-
    votos_provincias_sims %>%
    group_by(sim, partido) %>%
    summarise(
      votos = sum(votos_salida, na.rm = T),
      seats = sum(seats, na.rm = T), .groups = "drop"
    )

  # 6. Results are returned; saving is handled by run_vota()

  results <- list(
    estimacion = estimacion,
    estimacion_sims = estimacion_sims,
    estimacion_provincias_sims = votos_provincias_sims,
    mt_sims_pct = mt_sims,
    mt_sims_electores = mt_sims_electores,
    dhondt_output = dhondt_output,
    participacion_media = participacion_media,
    metadata = list(
      input_data = data,
      retoques = retoques,
      small_parties = small_parties,
      nsims = nsims,
      factor_correccion_abstencion = factor_correccion_abstencion,
      factor_correccion_jovenes = factor_correccion_jovenes,
      factor_correccion_otbl = factor_correccion_otbl,
      tau = tau,
      umbral = umbral,
      tipo_umbral = tipo_umbral,
      uncertainty_method = uncertainty_method,
      seed = seed,
      tiempo_entre_elecciones = tiempo_entre_elecciones,
      fecha_ejecucion = Sys.time()
    )
  )
}


#' Execute VOTA algorithm based on the selected strategy
#'
#' This function executes the VOTA algorithm using either a top-down or bottom-up approach,
#' depending on the specified strategy. It captures and validates additional arguments
#' and calls the appropriate internal function to perform the simulation.
#'
#' @param strategy Strategy for simulation ("top_down" or "bottom_up").
#' @param ... Additional arguments to be passed to the internal functions.
#'
#' @return A list containing the results of the VOTA algorithm execution.
#'
#' @keywords internal
#'
execute_vota <- function(strategy = c("top_down", "bottom_up"), ...) {
  # Validar strategy
  strategy <- match.arg(strategy)

  # Capturar y validar argumentos
  args <- list(...)
  if (length(args) == 0) {
    stop("At least one argument must be provided")
  }

  args <- args[!sapply(args, is.null)]

  # Ejecutar función apropiada
  result <- switch(strategy,
    "top_down" = {
      tryCatch(
        do.call(execute_vota_top_down, args),
        error = function(e) {
          stop("Error in execute_vota_top_down: ", e$message)
        }
      )
    },
    "bottom_up" = {
      tryCatch(
        do.call(execute_vota_bottom_up, args),
        error = function(e) {
          stop("Error in execute_vota_bottom_up: ", e$message)
        }
      )
    }
  )

  return(result)
}

#' Execute VOTA algorithm using top-down strategy
#' This function executes the VOTA algorithm using a top-down approach. It
#' processes the simulated transfer matrices and applies the VOTA corrections
#' to estimate national vote shares.
#'
#' @param mt_sims Data frame with simulated transfer matrices.
#' @param factor_correccion_abstencion Correction factor for abstention.
#' @param factor_correccion_jovenes Correction factor for new voters.
#' @param factor_correccion_otbl Correction factor for other blank/null votes.
#' @param tiempo_entre_elecciones Years between elections for demographic adjustments.
#' @param retoques Data frame with adjustments to be applied.
#' @param small_parties Data frame with small party votes.
#' @param votos_ant Data frame with previous electoral results (column votos_ant).
#' @param ... Additional arguments (not used)
#'
#' @return A list containing the estimated national vote shares and the adjusted transfer matrices.
#'
#' @keywords internal
#'
execute_vota_top_down <- function(mt_sims, factor_correccion_abstencion,
                                  factor_correccion_jovenes, factor_correccion_otbl,
                                  tiempo_entre_elecciones, retoques, small_parties, votos_ant, ...) {
  mt_sims_list <- split(mt_sims, mt_sims$sim)

  estimacion_previa_sims_list <-
    safe_map(mt_sims_list, function(mt_sim) {
      vota(
        mt_simplificada = mt_sim,
        tiempo_entre_elecciones = tiempo_entre_elecciones,
        factor_correccion_abstencion = factor_correccion_abstencion,
        factor_correccion_jovenes = factor_correccion_jovenes,
        factor_correccion_otbl = factor_correccion_otbl,
        retoques = retoques,
        small_parties = small_parties,
        votos_ant = votos_ant
      )
    })

  estimacion_previa_sims <-
    safe_map_dfr(estimacion_previa_sims_list, function(x) {
      x$estimacion
    }, .id = "sim")

  mt_sims_electores <- safe_map_dfr(estimacion_previa_sims_list, function(x) {
    x$mt
  }, .id = "sim")


  return(list(
    estimacion_previa_sims = estimacion_previa_sims,
    mt_sims_electores = mt_sims_electores
  ))
}

#' Execute VOTA algorithm using bottom-up strategy
#' This function executes the VOTA algorithm using a bottom-up approach. It
#' processes the simulated transfer matrices and applies the VOTA corrections
#' to estimate national vote shares.
#'
#' @param mt_sims Data frame with simulated transfer matrices.
#' @param district_col Name of column in survey_data indicating province or electoral district
#' @param factor_correccion_abstencion Correction factor for abstention.
#' @param factor_correccion_jovenes Correction factor for new voters.
#' @param factor_correccion_otbl Correction factor for other blank/null votes.
#' @param tiempo_entre_elecciones Years between elections for demographic adjustments.
#' @param retoques Data frame with adjustments to be applied.
#' @param small_parties Data frame with small party votes.
#' @param votos_ant Data frame with previous electoral results (column votos_ant).
#'
#' @return A list containing the estimated national vote shares and the adjusted transfer matrices.
#'
#' @keywords internal
#'
execute_vota_bottom_up <- function(mt_sims, district_col, factor_correccion_abstencion,
                                   factor_correccion_jovenes, factor_correccion_otbl,
                                   tiempo_entre_elecciones, retoques, small_parties, votos_ant) {
  mt_sims_list <- split(mt_sims, mt_sims$sim)

  estimacion_previa_sims_list <-
    safe_map(mt_sims_list, function(mt_sim) {
      mt_sims_prov_list <- split(mt_sim, mt_sim[, district_col])

      safe_map(mt_sims_prov_list, function(mt_sims_prov_sim) {
        d <- pull(unique(mt_sims_prov_sim[, district_col]))

        retoques <- retoques %>% filter(!!sym(district_col) == d)
        small_parties <- small_parties %>% filter(!!sym(district_col) == d)
        votos_ant <- votos_ant %>% filter(!!sym(district_col) == d)

        vota_out <-
          vota(
            mt_simplificada = mt_sims_prov_sim,
            tiempo_entre_elecciones = tiempo_entre_elecciones,
            factor_correccion_abstencion = factor_correccion_abstencion,
            factor_correccion_jovenes = factor_correccion_jovenes,
            factor_correccion_otbl = factor_correccion_otbl,
            retoques = retoques,
            small_parties = small_parties,
            votos_ant = votos_ant
          )

        vota_out$mt <- vota_out$mt %>%
          mutate(!!sym(district_col) := d, .before = 1)
        vota_out$estimacion <- vota_out$estimacion %>%
          mutate(!!sym(district_col) := d, .before = 1)

        return(vota_out)
      })
    })

  estimacion_previa_sims <-
    safe_map_dfr(estimacion_previa_sims_list, function(sim) {
      safe_map_dfr(sim, function(prov) {
        prov$estimacion
      })
    }, .id = "sim")

  mt_sims_electores <-
    safe_map_dfr(estimacion_previa_sims_list, function(sim) {
      safe_map_dfr(sim, function(prov) {
        prov$mt
      })
    }, .id = "sim")



  return(list(
    estimacion_previa_sims = estimacion_previa_sims,
    mt_sims_electores = mt_sims_electores
  ))
}
