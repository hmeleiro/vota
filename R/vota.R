#' VOTA: Vote Outcome Transfer-based Algorithm
#'
#' Applies the central electoral projection algorithm with corrections
#' of abstention, new voters and redistribution of undecided voters to the probability transfer matrix.
#'
#' @param mt_simplificada Data frame with transfer matrix with columns recuerdo, idv, transfer
#' @param tiempo_entre_elecciones Years between elections for demographic adjustments (default 4)
#' @param factor_correccion_abstencion Abstention correction factor (default 3)
#' @param factor_correccion_jovenes New voters correction factor (default 2.5)
#' @param factor_correccion_otbl Other blank/null votes correction factor (default 2.5)
#' @param retoques Optional data frame with manual adjustments (column votos_adicionales)
#' @param small_parties Optional data frame with small party votes
#' @param votos_ant Data frame with previous electoral results (column votos_ant)
#'
#' @return Data frame with national vote estimates by party
#'
#' @details
#' The VOTA algorithm implements the following corrections:
#' 1. Abstention correction: adjusts votes from those who abstained in previous elections
#' 2. New voters correction: adjusts votes from those not of age in previous elections
#' 3. Undecided redistribution: distributes according to transfer patterns the votes of undecided voters
#' 4. Small parties incorporation: adds external estimates for small parties not included in the transfer matrix or dificult to model
#' 5. Manual adjustments application: manual discretionary expert adjustments to the estimates based on additional information or judgement
#'
#' @family main-functions
#' @family core-algorithms
#' @export
vota <- function(mt_simplificada,
                 tiempo_entre_elecciones = 4,
                 factor_correccion_abstencion = 3,
                 factor_correccion_jovenes = 2.5,
                 factor_correccion_otbl = 2.5,
                 retoques = NULL,
                 small_parties = NULL,
                 votos_ant) {
  # Robust input validation
  if (!is.data.frame(mt_simplificada)) {
    stop("mt_simplificada must be a data.frame")
  }
  if (!all(c("recuerdo", "idv", "transfer") %in% colnames(mt_simplificada))) {
    stop("mt_simplificada must have columns recuerdo, idv and transfer")
  }
  if (!is.numeric(tiempo_entre_elecciones) || tiempo_entre_elecciones < 0) {
    stop("tiempo_entre_elecciones must be a positive number")
  }
  if (!is.data.frame(votos_ant) || !"votos_ant" %in% colnames(votos_ant)) {
    stop("votos_ant must be a data.frame with column 'votos_ant'")
  }

  mt_corregida <- mt_correction(
    mt_simplificada, factor_correccion_otbl,
    factor_correccion_abstencion, factor_correccion_jovenes
  )

  nuevos_votantes <- round((sum(votos_ant$votos_ant) * 0.01 * tiempo_entre_elecciones))

  votos_ant_corregido <-
    votos_ant %>%
    mutate(
      muertes = nuevos_votantes * votos_ant / sum(votos_ant),
      votos_ant = votos_ant - muertes
    ) %>%
    select(-muertes) %>%
    add_row(recuerdo = "<18", votos_ant = nuevos_votantes)

  mt_electores <-
    mt_corregida %>%
    left_join(votos_ant_corregido, by = join_by(recuerdo)) %>%
    mutate(electores = votos_ant * transfer) %>%
    select(recuerdo, idv, electores)

  indecisos <-
    mt_electores %>%
    filter(idv == "Indecisos") %>%
    select(recuerdo, indecisos = electores)

  if (nrow(indecisos) > 0) {
    mt_electores <-
      mt_electores %>%
      left_join(indecisos, by = join_by(recuerdo)) %>%
      mutate(
        asignacion = indecisos * electores / sum(electores, na.rm = T),
        idv2 = if_else(idv == "Indecisos", "ABNL", idv)
      ) %>%
      group_by(recuerdo, idv2) %>%
      mutate(
        asignacion = sum(asignacion, na.rm = T),
        electores = electores + asignacion
      ) %>%
      filter(idv != "Indecisos") %>%
      ungroup() %>%
      select(recuerdo, idv, electores)

    estimacion_previa <-
      mt_electores %>%
      group_by(idv) %>%
      summarise(votos = sum(electores, na.rm = T))
  } else {
    estimacion_previa <-
      mt_electores %>%
      group_by(idv) %>%
      summarise(votos = sum(electores))
  }

  if (!is.null(retoques)) {
    estimacion_previa <-
      estimacion_previa %>%
      left_join(retoques, by = join_by(idv)) %>%
      mutate(
        votos = case_when(
          !is.na(votos_adicionales) ~ votos + votos_adicionales,
          T ~ votos
        )
      ) %>%
      select(idv, votos)
  }

  if (!is.null(small_parties)) {
    estimacion_previa <-
      estimacion_previa %>%
      filter(!idv %in% small_parties$idv) %>%
      rbind(small_parties) %>%
      ungroup()
  }



  return(list(estimacion = estimacion_previa, mt = mt_electores))
}
