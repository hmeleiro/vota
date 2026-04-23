#' Project Estimates to Electoral District Level
#' Projects national vote estimates to electoral district level using
#' historical patterns and electoral census data.
#'
#' @param estimacion_previa_sims Data frame with national estimates by simulation
#' @param patrones Data frame with electoral district patterns
#' @param n_seats Data frame with number of seats per province
#' @param tau Smoothing parameter for multinomial simulation (default 300)
#' @param umbral Electoral threshold (default 0.03)
#' @param tipo_umbral Type of threshold: "provincial", "autonomico" or "mixto" (default "provincial")
#' @param seed Seed for reproducibility (optional)
#' @param censo Optional data frame with census data (columns: codigo_provincia, censo_real). If NULL, downloaded from INE.
#'
#' @return Data frame with electoral district results including uncertainty simulations
#'
#' @details
#' This process:
#' 1. Applies district historical patterns to national estimates
#' 2. Adjusts by real electoral census of each district
#' 3. Generates additional simulations with multinomial uncertainty
#' 4. Prepares data for D'Hondt allocation
#'
#' @keywords internal
#'
project_to_districts <- function(estimacion_previa_sims, patrones,
                                 n_seats, tau = 300,
                                 umbral = .03, tipo_umbral = "provincial",
                                 seed = NULL, censo = NULL) {
  provincias <- unique(patrones$codigo_provincia)
  if (is.null(censo)) {
    censo <- get_censo(provincias)
  } else {
    censo <- censo %>% filter(codigo_provincia %in% provincias)
  }

  estimacion_previa_sims <-
    split(estimacion_previa_sims, estimacion_previa_sims$sim)

  votos_provincias_sims <-
    safe_map(estimacion_previa_sims, function(estimacion_previa) {
      sim <- unique(estimacion_previa$sim)

      # Generar semilla unica para esta simulacion
      sim_seed <- if (!is.null(seed)) seed + as.numeric(sim) else NULL

      estimacion_provincial_mat <-
        simulate_prov_votes(
          patrones = patrones,
          estimacion = estimacion_previa,
          tau = tau,
          seed = sim_seed
        )

      estimacion_provincial <-
        estimacion_provincial_mat %>%
        as_tibble() %>%
        mutate(sim, codigo_provincia = rownames(estimacion_provincial_mat), .before = 1) %>%
        pivot_longer(3:ncol(.), names_to = "idv", values_to = "votos") %>%
        group_by(codigo_provincia) %>%
        mutate(votos = votos / sum(votos))
    }) %>%
    bind_rows() %>%
    group_by(sim, codigo_provincia) %>%
    mutate(votos = votos / sum(votos)) %>%
    left_join(censo, by = "codigo_provincia") %>%
    mutate(
      sim = as.numeric(sim),
      votos_salida = round(votos * censo_real, 2)
    ) %>%
    select(-c(censo_real, votos)) %>%
    relocate(sim, codigo_provincia, .before = 1) %>%
    arrange(sim, codigo_provincia, -votos_salida) %>%
    filter(votos_salida > 0) %>%
    rename(partido = idv)

  out <- allocate_seats(votos_provincias_sims, n_seats, umbral, tipo_umbral)

  return(out)
}

#' Allocate Seats to Parties in Each Province
#' Allocates seats to parties in each province using the D'Hondt method, applying
#' electoral thresholds to determine which parties are eligible for seat allocation.
#'
#' @param votos_provincias_sims Data frame with simulated votes by province and party
#' @param n_seats Data frame with number of seats per province
#' @param umbral Electoral threshold (default 0.03)
#' @param tipo_umbral Type of threshold: "provincial", "autonomico" or "mixto" (default "provincial")
#' @return List with two data frames:
#' \describe{
#'  \item{votos_provincias_sims}{Data frame with votes and assigned seats for each party in each province and simulation}
#'  \item{dhondt_output}{Detailed output from D'Hondt allocation including assigned seats and margins for next seats}
#'  }
#'
#'  @keywords internal
#'
allocate_seats <- function(votos_provincias_sims, n_seats,
                           umbral = .03, tipo_umbral = "provincial") {

  # ASIGNACION DE ESCANOS (d'hondt)
  abnl <-
    votos_provincias_sims %>%
    filter(partido == "ABNL")

  votos_provincias_sims <-
    votos_provincias_sims %>%
    left_join(n_seats, by = "codigo_provincia") %>%
    group_by(sim, codigo_provincia) %>%
    filter(!partido == "ABNL") %>%
    mutate(
      votos_validos_provincia = sum(votos_salida),
      pct_sobre_validos = votos_salida / sum(votos_salida)
    ) %>%
    ungroup() %>%
    arrange(sim, codigo_provincia, -votos_salida)

  # Quien entra y quién no
  quien_entra <- umbral_electoral(
    votos_provincias_sims,
    umbral = umbral,
    tipo_umbral = tipo_umbral
  )

  entran <- quien_entra$entran
  noentran <- quien_entra$noentran

  dhondt_output <-
    votos_provincias_sims %>%
    right_join(select(entran, -votos_salida),
      by = join_by(sim, codigo_provincia, partido)
    ) %>%
    fast_dhondt(votos_prov = votos_salida, n_next = 3) %>%
    arrange(sim, codigo_provincia, order)

  votos_provincias_sims <-
    dhondt_output %>%
    filter(tipo == "Asignado") %>%
    arrange(sim, codigo_provincia, -votos_salida) %>%
    group_by(sim, codigo_provincia, partido, votos_salida) %>%
    count(name = "seats") %>%
    full_join(entran, by = c("sim", "codigo_provincia", "partido", "votos_salida")) %>%
    mutate(seats = ifelse(is.na(seats), 0, seats)) %>%
    rbind(noentran) %>%
    bind_rows(abnl) %>%
    arrange(sim, codigo_provincia, -votos_salida) %>%
    ungroup() %>%
    relocate(sim, codigo_provincia, .before = 1) %>%
    mutate(across(where(is.numeric), as.integer)) %>%
    arrange(sim, codigo_provincia, -votos_salida)

  return(list(
    votos_provincias_sims = votos_provincias_sims,
    dhondt_output = dhondt_output
  ))
}
