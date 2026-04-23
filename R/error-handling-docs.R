#' Manejo de errores en operaciones map
#'
#' Conjunto de funciones auxiliares para mejorar el manejo de errores
#' cuando se usan operaciones purrr::map dentro del paquete vota.
#'
#' @name error-handling
#' @keywords internal
#'
#' @details
#'
#' ## Problema
#'
#' Cuando una funcion falla dentro de `purrr::map()`, el mensaje de error
#' original puede perderse o ser confuso para el usuario final.
#'
#' ## Solucion
#'
#' Este paquete implementa tres funciones auxiliares:
#'
#' ### `safe_map()`
#' Version segura de `purrr::map()` que captura errores y proporciona
#' contexto sobre que elemento fallo.
#'
#' ### `safe_map_dfr()`
#' Version segura de `purrr::map_dfr()` que combina resultados en data.frame
#' y proporciona manejo robusto de errores.
#'
#' ### `add_error_context()`
#' Funcion para agregar contexto personalizado a errores dentro de
#' funciones individuales.
#'
#' ## Ejemplos de uso
#'
#' ### Reemplazar map() regular:
#' ```r
#' # En lugar de:
#' resultados <- purrr::map(lista, mi_funcion)
#'
#' # Usar:
#' resultados <- safe_map(lista, mi_funcion)
#' ```
#'
#' ### Para map_dfr():
#' ```r
#' # En lugar de:
#' df_resultado <- purrr::map_dfr(lista, mi_funcion, .id = "sim")
#'
#' # Usar:
#' df_resultado <- safe_map_dfr(lista, mi_funcion, .id = "sim")
#' ```
#'
#' ### Agregar contexto especifico:
#' ```r
#' resultados <- safe_map(lista_simulaciones, function(sim) {
#'   add_error_context(
#'     vota(sim$mt),
#'     context = "Ejecutando algoritmo VOTA",
#'     element = paste("Simulacion", sim$id)
#'   )
#' })
#' ```
#'
#' ## Formato de mensajes de error
#'
#' Los errores se reportan con el siguiente formato:
#' ```
#' Error en iteracion de map() - elemento X:
#' Mensaje original: [mensaje del error original]
#' Total errores: Y de Z elementos
#' ```
#'
#' Esto permite al usuario:
#' 1. Identificar exactamente que elemento fallo
#' 2. Ver el mensaje de error original (ej. de stop())
#' 3. Entender la magnitud del problema (cuantos elementos fallaron)
#'
#' @examples
#' \dontrun{
#' # Ejemplo que falla en elemento especifico
#' datos <- list(a = 1, b = 2, c = "texto")
#'
#' # Con map() normal - mensaje confuso:
#' try(purrr::map(datos, function(x) x + 1))
#'
#' # Con safe_map() - mensaje claro:
#' try(safe_map(datos, function(x) x + 1))
#' }
NULL
