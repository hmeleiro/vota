#' Crea un objeto electo_fit
#'
#' @param results Lista con los resultados del ajuste, que debe incluir los siguientes elementos:
#' \describe{
#'  \item{estimacion}{Data frame con las estimaciones finales, debe incluir columnas 'partido', 'pct_m', 'seats_m'}
#'  \item{estimacion_sims}{(Opcional) Data frame con las simulaciones detalladas por partido y provincia}
#'  \item{estimacion_provincias_sims}{(Opcional) Data frame con las simulaciones detalladas por partido y provincia}
#'  \item{mt_sims_pct}{(Opcional) Matriz de transferencias simuladas en porcentaje de voto sobre recuerdo}
#'  \item{mt_sims_electores}{(Opcional) Matriz
#'  de transferencias simuladas en número de electores}
#'  \item{dhondt_output}{(Opcional) Resultado del método D'Hondt aplicado a las simulaciones}
#'  \item{participacion_media}{(Opcional) Valor numérico con la participación media estimada}
#'  \item{metadata}{Lista con metadatos del ajuste, como 'nsims', 'tau', 'umbral', etc.}
#'  }
#'
#' @return Objeto de clase electo_fit
#' @export
new_electo_fit <- function(results) {
  obj <- results

  validate_electo_fit(obj)
  class(obj) <- c("electo_fit", "list")
  attr(obj, "package_version") <- tryCatch(utils::packageVersion(utils::packageName()), error = function(e) NA)
  obj
}
#' Valida un objeto electo_fit
#' @param x Objeto a validar
#' @return TRUE si es válido, error si no lo es
#' @keywords internal
validate_electo_fit <- function(x) {
  stopifnot(is.data.frame(x$estimacion))
  need <- c("partido","pct_m","seats_m")
  if (!all(need %in% names(x$estimacion))) {
    stop("`estimacion` must have columns: ", paste(need, collapse=", "))
  }
  invisible(TRUE)
}

