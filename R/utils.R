#' Apply Corrections to Vote Transfer Matrix
#'
#' Auxiliary function that applies corrections for abstention, new voters
#' and other blank/null votes to the transfer matrix.
#'
#' @param mt_simplificada Data frame with vote transfer matrix
#' @param factor_correccion_otbl Correction factor for other blank/null votes
#' @param factor_correccion_abstencion Correction factor for abstention
#' @param factor_correccion_jovenes Correction factor for new voters
#'
#' @return Data frame with corrected transfer matrix
#' @keywords internal
mt_correction <- function(mt_simplificada, factor_correccion_otbl,
                          factor_correccion_abstencion, factor_correccion_jovenes) {
  recuerdo <- unique(mt_simplificada$recuerdo)
  idv <- unique(mt_simplificada$idv)

  MUST_VALUES <- c("ABNL", "OTBL")

  if (!all(MUST_VALUES %in% recuerdo)) {
    stop(paste0("The 'recuerdo' column in transfer matrix must contain values: ", paste(MUST_VALUES, collapse = ", ")))
  }

  if (!all(MUST_VALUES %in% idv)) {
    stop(paste0("The 'idv' column in transfer matrix must contain values: ", paste(MUST_VALUES[1:2], collapse = ", ")))
  }

  mt_corregida <-
    mt_simplificada %>%
    group_by(recuerdo) %>%
    mutate(
      transfer = case_when(
        idv == "OTBL" & !recuerdo %in% c("ABNL", "<18") ~ transfer / factor_correccion_otbl,
        recuerdo == "ABNL" & idv != "ABNL" ~ transfer / factor_correccion_abstencion,
        recuerdo == "<18" & !idv %in% c("ABNL", "Indecisos") ~ transfer / factor_correccion_jovenes,
        T ~ transfer
      )
    )


  columna_abnl_corregida <-
    mt_corregida %>%
    filter(recuerdo == "ABNL") %>%
    mutate(
      transfer = case_when(
        idv == "OTBL" ~ transfer / factor_correccion_otbl,
        T ~ transfer
      ),
      transfer = case_when(
        idv == "ABNL" ~ 1 - sum(transfer[idv != "ABNL"]),
        T ~ transfer
      )
    )

  columna_18_corregida <-
    mt_corregida %>%
    filter(recuerdo == "<18") %>%
    mutate(
      transfer = case_when(
        idv == "OTBL" ~ transfer / factor_correccion_otbl,
        T ~ transfer
      ),
      transfer = case_when(
        idv == "ABNL" ~ 1 - sum(transfer[idv != "ABNL"]),
        T ~ transfer
      )
    )

  fila_otbl_corregida <-
    full_join(
      mt_simplificada %>%
        filter(idv == "OTBL") %>%
        rename(transfer_simp = transfer),
      mt_corregida %>%
        filter(idv == "OTBL") %>%
        rename(transfer_corregida = transfer),
      by = join_by(sim, recuerdo, idv, n)
    ) %>%
    transmute(sim, recuerdo, transfer_otbl_corregido = transfer_simp - transfer_corregida)

  fil_abnl_corregida <-
    mt_corregida %>%
    filter(idv == "ABNL") %>%
    left_join(fila_otbl_corregida, by = join_by(sim, recuerdo)) %>%
    mutate(
      transfer_otbl_corregido = ifelse(is.na(transfer_otbl_corregido), 0, transfer_otbl_corregido),
      transfer = transfer + transfer_otbl_corregido
    ) %>%
    select(-transfer_otbl_corregido) %>%
    filter(!recuerdo %in% c("ABNL", "<18"))

  mt_corregida <-
    mt_corregida %>%
    filter(idv != "ABNL" & recuerdo != "ABNL" & recuerdo != "<18") %>%
    rbind(columna_abnl_corregida) %>%
    rbind(fil_abnl_corregida) %>%
    rbind(columna_18_corregida) %>%
    arrange(recuerdo, idv) %>%
    ungroup()

  return(mt_corregida)
}

#' Get Latest Electoral Census URL
#'
#' Fetches the URL of the latest electoral census file from the INE website. If there is an error during fetching, it returns a fallback URL.
#'
#' @return A string containing the URL of the latest electoral census file.
#'
#' @keywords internal
last_cer_url <- function() {
  url <- "https://www.ine.es/dyngs/CEL/index.htm?cid=77"

  tryCatch(
    {
      resp <- GET(url)

      if (resp$status_code != 200) {
        stop(paste("Error fetching URL \u00faltimo censo. Status code:", resp$status_code))
      }
      urls <- resp %>%
        read_html() %>%
        html_elements("option") %>%
        html_attr("value")
      last_cer <- max(urls[grepl("cerprov", urls)])
      last_cer <- paste0("https://ine.es", last_cer)

      return(last_cer)
    },
    error = function(e) {
      warning(paste("Error fetching URL \u00faltimo censo:", e$message))
      return("https://ine.es/oficina_censo/censo_cerrado/cerprov_25.xlsx") # fallback
    }
  )
}

#' Download Electoral Census Data
#'
#' Downloads electoral census data from INE for specified provinces.
#'
#' @param provincias Vector with province codes to obtain census data for
#'
#' @return Data frame with columns codigo_provincia and censo_real
#'
#' @details
#' This function automatically downloads the census file from INE and extracts
#' data for requested provinces. Requires internet connection.
#'
#' @examples
#' \dontrun{
#' # Get census data for Madrid, Barcelona and Valencia
#' censo <- get_censo(c("28", "08", "46"))
#' }
#'
#' @export
get_censo <- function(provincias) {
  temp <- tempfile(fileext = ".xlsx")

  # Verificar conexi\u00f3n y descargar con manejo de errores
  tryCatch(
    {
      url <- last_cer_url()
      download.file(url,
        temp,
        mode = "wb", quiet = TRUE
      )

      if (!file.exists(temp) || file.size(temp) == 0) {
        stop("Error: Census file not downloaded correctly")
      }


      suppressMessages(
        censo <- read_xlsx(temp, skip = 5) %>%
          select(codigo_provincia = 1, censo_real = 3) %>%
          filter(codigo_provincia %in% provincias)
      )

      # Limpiar archivo temporal
      unlink(temp)

      if (nrow(censo) == 0) {
        warning("No se encontraron datos de censo para las provincias especificadas")
      }

      return(censo)
    },
    error = function(e) {
      # Limpiar archivo temporal en caso de error
      if (file.exists(temp)) unlink(temp)
      stop(paste("Error descargando censo del INE:", e$message))
    }
  )
}

#' Calcular Tama\enc{ñ}{n}os de Muestra de MT
#'
#' Calcula los tama\enc{ñ}{n}os de muestra efectivos para cada columna de recuerdo
#' en la matriz de transferencia.
#'
#' @param mt Data frame con matriz de transferencia
#'
#' @return Data frame con fila N a\enc{ñ}{n}adida
#' @export
calculate_n <- function(mt) {
  if (!is.data.frame(mt)) {
    stop("mt must be a data.frame")
  }
  rm_cols <- c("Total", "NS/NC")
  rm_rows <- c("N", "n")

  n <-
    mt %>%
    filter(idv %in% rm_rows) %>%
    select(-idv) %>%
    pivot_longer(1:ncol(.), names_to = "recuerdo", values_to = "n")

  if (nrow(n) == 0) {
    stop("Matrix must include a row with total respondents per party recall (N)")
  }

  mt <- mt %>% filter(!idv %in% rm_rows)

  mt <-
    mt %>%
    select(-any_of(rm_cols)) %>%
    pivot_longer(2:ncol(.), names_to = "recuerdo", values_to = "pct") %>%
    left_join(n, by = "recuerdo") %>%
    mutate(
      n = round(pct * n / 100)
    ) %>%
    select(recuerdo, idv, n, pct_original = pct) %>%
    filter(!is.na(n))

  return(mt)
}

# Funcion auxiliar para emojis (uso interno)
emoji <- function(code) {
  intToUtf8(code, multiple = FALSE)
}


#' Agregar Resultados Nacionales desede Simulaciones Provinciales
#'
#' Agrega los resultados de votos y esca\enc{ñ}{n}os a nivel nacional
#'
#' @param votos_provincias_sims Data frame con resultados provinciales por simulacion
#' @param interval_level Nivel de confianza para los intervalos (default 0.9)
#'
#' @return Data frame con resultados nacionales agregados
#' @export
aggregate_results <- function(votos_provincias_sims, interval_level = .9) {
  lwr <- (1 - interval_level) / 2
  upr <- 1 - lwr

  estimacion_horquillas <-
    votos_provincias_sims %>%
    mutate(partido = as.character(partido)) %>%
    group_by(sim, partido) %>%
    summarise(
      votos = sum(votos_salida, na.rm = T),
      seats = sum(seats, na.rm = T),
      .groups = "drop"
    ) %>%
    group_by(sim) %>%
    mutate(
      pct = round(votos / sum(votos) * 100, 2),
      pct = ifelse(partido == "ABNL", NA_real_, pct),
      pct = round(pct / sum(pct, na.rm = T) * 100, 2),
      seats = ifelse(partido %in% c("ABNL", "OTBL"), NA_integer_, seats)
    ) %>%
    group_by(partido) %>%
    summarise(
      votos_lwr = quantile(votos, lwr, na.rm = T),
      votos_upr = quantile(votos, upr, na.rm = T),
      pct_lwr = quantile(pct, lwr, na.rm = T),
      pct_upr = quantile(pct, upr, na.rm = T),
      seats_lwr = quantile(seats, lwr, na.rm = T),
      seats_upr = quantile(seats, upr, na.rm = T)
    ) %>%
    mutate(across(c(starts_with(c("votos", "seats"))), as.integer))


  estimacion <-
    votos_provincias_sims %>%
    group_by(sim, codigo_provincia, partido) %>%
    summarise(
      votos = sum(votos_salida, na.rm = T),
      seats = sum(seats, na.rm = T),
      .groups = "drop"
    ) %>%
    group_by(sim, partido) %>%
    summarise(
      votos = sum(votos, na.rm = T),
      seats = sum(seats, na.rm = T),
      .groups = "drop_last"
    ) %>%
    mutate(
      pct = round(votos / sum(votos) * 100, 2),
      pct = ifelse(partido == "ABNL", NA_real_, pct),
      pct = round(pct / sum(pct, na.rm = T) * 100, 2)
    ) %>%
    group_by(partido) %>%
    summarise(
      votos_m = mean(votos, na.rm = T),
      pct_m = mean(pct, na.rm = T),
      seats_m = round(mean(seats, na.rm = T)),
    ) %>%
    mutate(across(c(votos_m, seats_m), as.integer)) %>%
    full_join(estimacion_horquillas, by = "partido") %>%
    arrange(-votos_m)

  lvls <- estimacion$partido
  lvls <- lvls[!lvls %in% c("ABNL", "OTBL")]
  lvls <- c(lvls, "OTBL", "ABNL")

  estimacion <-
    estimacion %>%
    mutate(partido = factor(partido, levels = lvls)) %>%
    arrange(partido)

  return(estimacion)
}


#' Prepare Pipeline Arguments
#'
#' Prepares a list of arguments for the election simulation pipeline based on the provided parameters.
#'
#' @param params A list containing various parameter settings for the simulation.
#' @param ... Additional arguments to be included in the output list.
#'
#' @return A list of arguments ready to be passed to the simulation pipeline.
#'
#' @keywords internal
prepare_pipeline_args <- function(params, ...) {
  tryCatch(
    {
      params <- list(
        data = params$data$input_data,
        retoques = params$additional_args$retoques,
        small_parties = params$additional_args$small_parties,
        votos_ant = params$additional_args$anteriores_elecciones,
        patrones = params$additional_args$patrones,
        n_seats = params$additional_args$n_diputados,
        uncertainty_method = params$simulation$uncertainty_method,
        strategy = params$simulation$strategy, nsims = params$simulation$nsims,
        factor_correccion_abstencion = params$correction_params$factor_correccion_abstencion,
        factor_correccion_jovenes = params$correction_params$factor_correccion_jovenes,
        factor_correccion_otbl = params$correction_params$factor_correccion_otbl,
        tiempo_entre_elecciones = params$correction_params$tiempo_entre_elecciones,
        district_col = params$data$district_col, tau = params$simulation$tau,
        umbral = params$seats_allocation$umbral, tipo_umbral = params$seats_allocation$tipo_umbral,
        interval_level = params$simulation$interval_level,
        censo = params$data$censo,
        verbose = params$runtime$verbose, seed = params$simulation$seed,
        ...
      )
    },
    error = function(e) {
      stop(paste("Error in prepare_pipeline_args:", e$message))
    }
  )
  return(params)
}
