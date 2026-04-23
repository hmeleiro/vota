#' Matriz de Transferencia de Ejemplo
#'
#' Dataset de ejemplo con una matriz de transferencia electoral empleada
#' en las plantillas del paquete.
#'
#' @format Un data frame con las siguientes columnas:
#' \describe{
#'   \item{idv}{Factor con la intención de voto de los partidos}
#'   \item{PSOE}{Numérico, porcentaje de transferencia desde recuerdo PSOE}
#'   \item{PP}{Numérico, porcentaje de transferencia desde recuerdo PP}
#'   \item{Vox}{Numérico, porcentaje de transferencia desde recuerdo Vox}
#'   \item{Sumar}{Numérico, porcentaje de transferencia desde recuerdo Sumar}
#'   \item{OTBL}{Numérico, porcentaje de transferencia desde recuerdo OTBL}
#'   \item{ABNL}{Numérico, porcentaje de transferencia desde recuerdo ABNL}
#' }
#' @source Datos sintéticos de demostración
#' @family example-data
"mt"

#' Número de escaños por provincia
#'
#' Dataset con el número de diputados asignados a cada provincia española.
#'
#' @format Un data frame con las siguientes columnas:
#' \describe{
#'   \item{codigo_provincia}{Carácter, código INE de la provincia}
#'   \item{n_diputados}{Entero, número de escaños asignados}
#' }
#' @source Instituto Nacional de Estadística (INE)
#' @family example-data
"n_seats"

#' Patrones electorales del 23J
#'
#' Dataset con patrones históricos de voto por provincia para las elecciones
#' generales del 23 de julio de 2023.
#'
#' @format Un data frame con las siguientes columnas:
#' \describe{
#'   \item{codigo_provincia}{Carácter, código INE de la provincia}
#'   \item{partido}{Carácter, código del partido político}
#'   \item{patron}{Numérico, proporción histórica de votos (0-1)}
#' }
#' @source Ministerio del Interior, elecciones generales 23J 2023
#' @family example-data
"patrones_23J"

#' Ajustes manuales de ejemplo
#'
#' Dataset con retoques o ajustes manuales para aplicar a las estimaciones
#' electorales.
#'
#' @format Un data frame con las siguientes columnas:
#' \describe{
#'   \item{idv}{Carácter, código del partido}
#'   \item{votos_adicionales}{Entero, votos a añadir (positivo) o restar (negativo)}
#' }
#' @source Datos sintéticos de demostración
#' @family example-data
"retoques"

#' Partidos pequeños de ejemplo
#'
#' Dataset con estimaciones de voto para partidos pequeños no incluidos en la
#' matriz de transferencia principal.
#'
#' @format Un data frame con las siguientes columnas:
#' \describe{
#'   \item{idv}{Carácter, código del partido}
#'   \item{votos}{Entero, estimación de votos a nivel nacional}
#' }
#' @source Datos sintéticos de demostración
#' @family example-data
"small_parties"

#' Resultados electorales del 23J
#'
#' Dataset con los resultados oficiales de las elecciones generales del 23 de
#' julio de 2023, utilizados como referencia de elecciones anteriores.
#'
#' @format Un data frame con las siguientes columnas:
#' \describe{
#'   \item{recuerdo}{Carácter, código del partido según recuerdo de voto}
#'   \item{votos_ant}{Entero, votos obtenidos en la elección anterior}
#' }
#' @source Ministerio del Interior, elecciones generales 23J 2023
#' @family example-data
"votos_23J"
