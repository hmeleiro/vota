#' Vectorized D'Hondt Allocation
#'
#' Optimized implementation of the D'Hondt method for seat allocation
#' across multiple provinces and simulations simultaneously.
#'
#' @param data Data frame with electoral data
#' @param cod_prov Column identifying the electoral district (default codigo_provincia)
#' @param sim Column identifying the simulation (default sim)
#' @param partido Column identifying the party (default partido)
#' @param votos_prov Column with votes in the electoral district
#' @param nseats Column with number of seats per electoral district (default n_diputados)
#' @param n_next Number of additional seats to calculate. This is useful for analyzing the battle for the last seat (default 0)
#'
#' @return Data frame with assigned seats. One row per assigned seat.
#'
#' @details
#' This vectorized implementation efficiently processes thousands of simulations,
#' applying the standard D'Hondt method used in Spain.
#' Includes calculation of next seats for sensitivity analysis.
#'
#' @family allocation-functions
#' @family core-algorithms
#' @export
fast_dhondt <- function(data, cod_prov = codigo_provincia, sim = sim,
                        partido = partido, votos_prov,
                        nseats = n_diputados, n_next = 0) {
  # cod_prov = columna en data que identifica la circunscripcion
  # sim = columna en data que identifica la simulacion
  # partido = columna en data que identifica el nombre del partido
  # est_prov = columna en data que identifica la estimacion provincial de cada partido
  # nseats = columna en data que identifica el numero de diputados que se reparten en la circunscripcion
  # umbral = Barrera electoral provincial

  # Devuelve un data frame con tantas filas como escanos se repartan en cada circunscripcion
  data %>%
    group_by({{ sim }}, {{ cod_prov }}, {{ partido }}) %>%
    dplyr::slice(rep(1:n(), first({{ nseats }} + n_next))) %>%
    mutate(
      divisor = 1:length({{ partido }}),
      cociente = {{ votos_prov }} / divisor
    ) %>%
    arrange({{ cod_prov }}, -cociente) %>%
    group_by({{ sim }}, {{ cod_prov }}) %>%
    mutate(
      order = 1:length({{ nseats }} + n_next),
      tipo = if_else(order <= {{ nseats }}, "Asignado", "Siguiente"),
      col = cociente[{{ nseats }} == order],
      dif = (col - cociente) * divisor
    ) %>%
    arrange(dif) %>%
    mutate(order2 = 1:length(dif)) %>%
    filter(order2 <= ({{ nseats }} + n_next)) %>%
    arrange({{ sim }}, {{ cod_prov }}, order) %>%
    ungroup() %>%
    select(-order2)
}
