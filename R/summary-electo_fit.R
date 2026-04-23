#' Summary method for electo_fit objects
#'
#' @param object Object electo_fit
#' @param ... Additional arguments (not used)
#'
#' @export
summary.electo_fit <- function(object, ...) {
  est <- object$estimacion

  # Probability of winning (being 1st in votes) from estimacion_sims
  prob_ganar <- NULL
  if (is.data.frame(object$estimacion_sims) &&
      all(c("sim","partido","seats") %in% names(object$estimacion_sims))) {
    es <- object$estimacion_sims
    # ganador por sim
    es <- es[!es$partido %in% c("ABNL","OTBL"), ]  # excluir partidos no relevantes
    winners <- lapply(split(es, es$sim), function(df) df$partido[df$votos == max(df$votos, na.rm = TRUE)])
    prob_ganar <- sort(table(unlist(winners)) / length(winners)*100, decreasing = TRUE)
    prob_ganar <- data.frame(partido = names(prob_ganar),
                             prob_ganar = as.numeric(prob_ganar))
  }

  cols_seleccionadas <- c("partido","pct_m","pct_lwr","pct_upr","seats_m","seats_lwr","seats_upr")
  keep <- intersect(cols_seleccionadas, names(est))
  if (length(keep) == 0) {
    stop("`estimacion` no contiene ninguna de las columnas esperadas: ",
         paste(cols_seleccionadas, collapse = ", "))
  }
  nacional <- est[, keep, drop = FALSE]

  res <- list(
    nacional = nacional,
    prob_ganar = prob_ganar,
    participacion_media = object$participacion_media,
    metadata = object$metadata[c("nsims","tau","umbral","tipo_umbral","uncertainty_method","tiempo_entre_elecciones","input_path","fecha_ejecucion")]
  )
  class(res) <- "summary_electo_fit"
  res
}

#' Print method for summary_electo_fit objects
#'
#' @param x Object summary_electo_fit
#' @param digits Number of digits to print
#' @param ... Additional arguments (not used)
#'
#' @export
print.summary_electo_fit <- function(x, digits = 3, ...) {
  cat("Resumen electo_fit\n")
  if (!is.null(x$metadata$nsims))
    cat("  Sims :", x$metadata$nsims, "\n")

  cat("  Tau  :", x$metadata$tau %||% "N/A", "\n")
  cat("  Uncertainty method:", x$metadata$uncertainty_method %||% "N/A", "\n")

  if (!is.null(x$participacion_media))
    cat("  Mean turnout:", round(x$participacion_media, 1), "%\n")

  cat("  Umbral:", x$metadata$umbral*100 %||% "N/A", "%",
      if (!is.null(x$metadata$tipo_umbral)) paste0(" (", x$metadata$tipo_umbral, ")") else "", "\n")

  cat("\nAggregated summary (medias e IC):\n")
  print(x$nacional, digits = digits, row.names = FALSE)

  if (is.data.frame(x$prob_ganar)) {
    cat("\nProbability of winning (1st place in votes):\n")
    print(x$prob_ganar, digits = digits, row.names = FALSE)
  }
  invisible(x)
}
