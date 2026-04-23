#' Control de semillas en vota
#'
#' @name seed-control
#' @keywords internal
#'
#' @details
#'
#' ## Sistema de semillas en vota
#'
#' El paquete vota implementa un sistema coherente de control de semillas
#' para asegurar la reproducibilidad en todas las operaciones estocásticas.
#'
#' ### Funciones que aceptan semillas:
#'
#' - `run_vota()`: Función principal - propaga semillas a todas las subfunciones
#' - `simulate_mt()`: Simulación de matrices de transferencia
#' - `simulate_prov_votes()`: Simulación de votos provinciales
#' - `bootstrap()`: Bootstrap de datos de encuesta
#' - `project_to_provinces()`: Proyección provincial con incertidumbre
#'
#' ### Sistema de semillas derivadas:
#'
#' Para evitar correlaciones indeseadas entre diferentes etapas del pipeline,
#' el sistema genera semillas derivadas automáticamente:
#'
#' - `seed + 1`: Para simulación de matrices de transferencia
#' - `seed + 2`: Para proyección provincial
#' - `seed + sim`: Para cada simulación individual dentro de proyección provincial
#'
#' ### Uso básico:
#'
#' ```r
#' # Simulación reproducible
#' resultado1 <- run_vota("input.xlsx", seed = 12345)
#' resultado2 <- run_vota("input.xlsx", seed = 12345)
#'
#' # Los resultados serán idénticos
#' identical(resultado1, resultado2)  # TRUE
#' ```
#'
#' ### Uso avanzado:
#'
#' ```r
#' # Control fino de semillas en funciones individuales
#' mt_sims <- simulate_mt(mt_data, nsims = 100, seed = 123)
#'
#' # Reproducibilidad en proyección provincial
#' prov_results <- project_to_provinces(
#'   estimacion_previa_sims = datos,
#'   patrones = patrones,
#'   n_seats = n_seats,
#'   idv_lvls = ids,
#'   seed = 456
#' )
#' ```
#'
#' ### Consideraciones:
#'
#' 1. **Reproducibilidad completa**: Usar la misma semilla en `run_vota()`
#'    garantiza resultados idénticos en toda la pipeline.
#'
#' 2. **Semillas derivadas**: El sistema automáticamente genera semillas
#'    diferentes para cada etapa, evitando correlaciones artificiales.
#'
#' 3. **Compatibilidad**: Si no se especifica semilla (`seed = NULL`),
#'    las funciones usan el estado aleatorio actual de R.
#'
#' 4. **Debugging**: Para debugging, usar semillas específicas permite
#'    reproducir exactamente los mismos resultados.
#'
#' @examples
#' \dontrun{
#' # Ejemplo de reproducibilidad completa
#' library(vota)
#'
#' # Primera ejecución
#' resultado_a <- run_vota(
#'     input_path = "mi_encuesta.xlsx",
#'     nsims_mt = 50,
#'     nsims_prov = 200,
#'     seed = 2024
#' )
#'
#' # Segunda ejecución con misma semilla
#' resultado_b <- run_vota(
#'     input_path = "mi_encuesta.xlsx",
#'     nsims_mt = 50,
#'     nsims_prov = 200,
#'     seed = 2024
#' )
#'
#' # Verificar reproducibilidad
#' identical(resultado_a$nacional, resultado_b$nacional) # TRUE
#' identical(resultado_a$provincial, resultado_b$provincial) # TRUE
#' identical(resultado_a$seats_summary, resultado_b$seats_summary) # TRUE
#'
#' # Para análisis de sensibilidad con diferentes semillas
#' seeds <- c(100, 200, 300, 400, 500)
#' resultados <- lapply(seeds, function(s) {
#'     run_vota("input.xlsx", seed = s)
#' })
#' }
NULL
