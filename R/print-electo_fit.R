#' Print method for electo_fit objects
#' @param x Objeto electo_fit
#' @param ... Additional arguments (not used)
#' @export
print.electo_fit <- function(x, ...) {
  cat("<electo_fit>\n")
  cat("  nsims:", x$metadata$nsims %||% NA,
      " | mean turnout:", round(x$participacion_media %||% NA_real_, 1), "%\n")
  cat("  correction factors: abst=", x$metadata$factor_correccion_abstencion %||% NA,
      " new voters=", x$metadata$factor_correccion_jovenes %||% NA,
      " otbl=", x$metadata$factor_correccion_otbl %||% NA, "\n", sep = "")
  if (!is.null(x$estimacion_provincias_sims)) {
    nprov <- length(unique(x$estimacion_provincias_sims$codigo_provincia))
    cat("  districts:", nprov, "\n")
  }

  est <- x$estimacion[!x$estimacion$partido %in% c("ABNL","OTBL"), ]
  # Top-10 by seats
  top_s <- head(est[order(-est$seats_m), c("partido","seats_m")], 10)
  # Top-10 by votes
  top_v <- head(est[order(-est$pct_m), c("partido","pct_m")], 10)
  cat("  Top seats:\n")
  apply(top_s, 1, function(r) cat(sprintf("    - %s: %s\n", r[1], r[2])))
  cat("  Top voto (%):\n")
  apply(top_v, 1, function(r) cat(sprintf("    - %s: %.1f\n", r[1], as.numeric(r[2]))))
  invisible(x)
}
