#' Aplica el umbral electoral a los datos de votos simulados por provincias.
#'
#' @param votos_provincias_sims Data frame con votos simulados por provincia
#' @param umbral Umbral minimo de voto para asignacion de escaños (por defecto 0.03)
#' @param tipo_umbral Tipo de umbral: "provincial", "autonomico" o "mixto" (por defecto "provincial")
#' @return Lista con dos data frames:
#' \describe{
#'   \item{noentran}{Partidos que no alcanzan el umbral, con votos y seats = NA}
#'   \item{entran}{Partidos que superan el umbral, con votos para asignacion D'Hondt}
#' }
#'
#' @keywords internal
umbral_electoral <- function(votos_provincias_sims, umbral = .03,
                             tipo_umbral = "provincial") {

  # Calculo el % sobre válidos del total autonomico/nacional
  # para elecciones donde el umbral es mixto o autonomico (Extremadura o CVal)
  votos_validos_provincia <-
    votos_provincias_sims %>%
    select(sim, codigo_provincia, votos_validos_provincia) %>%
    distinct() %>%
    group_by(sim) %>%
    summarise(votos_validos_total = sum(votos_validos_provincia))

  votos_provincias_sims <-
    votos_provincias_sims %>%
    left_join(votos_validos_provincia, by = "sim") %>%
    group_by(sim, partido) %>%
    mutate(votos_total_pct = sum(votos_salida) / votos_validos_total)

  if(tipo_umbral == "provincial") {

    noentran <-
      votos_provincias_sims %>%
      filter(!(partido != "OTBL" & pct_sobre_validos >= umbral)) %>%
      mutate(seats = NA_integer_) %>%
      select(sim, codigo_provincia, partido, votos_salida, seats)

    entran <-
      votos_provincias_sims %>%
      filter(partido != "OTBL" & pct_sobre_validos >= umbral) %>%
      select(sim, codigo_provincia, partido, votos_salida) %>%
      distinct()

  } else if(tipo_umbral == "autonomico") {

    noentran <-
      votos_provincias_sims %>%
      filter(!(partido != "OTBL" & votos_total_pct >= umbral)) %>%
      mutate(seats = NA_integer_) %>%
      select(sim, codigo_provincia, partido, votos_salida, seats)

    entran <-
      votos_provincias_sims %>%
      filter(partido != "OTBL" & votos_total_pct >= umbral) %>%
      select(sim, codigo_provincia, partido, votos_salida) %>%
      distinct()

  } else if(tipo_umbral == "mixto") {

    noentran <-
      votos_provincias_sims %>%
      filter(
        !(partido != "OTBL" &
            (votos_total_pct >= umbral | pct_sobre_validos >= umbral)
        )
      ) %>%
      mutate(seats = NA_integer_) %>%
      select(sim, codigo_provincia, partido, votos_salida, seats)

    entran <-
      votos_provincias_sims %>%
      filter(
        partido != "OTBL" &
          (votos_total_pct >= umbral | pct_sobre_validos >= umbral)
      ) %>%
      select(sim, codigo_provincia, partido, votos_salida) %>%
      distinct()

  }

  return(list(noentran = noentran, entran = entran))
}

