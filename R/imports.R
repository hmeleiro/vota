#' Package imports
#'
#' These declarations ensure NAMESPACE keeps required imports.
#' @title Imports
#' @description Package import declarations
#' @name vota-imports
#' @keywords internal
#' @import dplyr
#' @import tidyr
#' @import ggplot2
#' @importFrom readxl read_xlsx excel_sheets
#' @importFrom purrr map_df map safely transpose map
#' @importFrom httr GET
#' @importFrom rvest read_html html_elements html_attr
#' @importFrom openxlsx createWorkbook addWorksheet writeData saveWorkbook
#' @importFrom stats median quantile rmultinom rexp
#' @importFrom utils download.file head
#' @importFrom rlang .data
#' @importFrom stats setNames aggregate reorder
#' @importFrom gtools rdirichlet
#' @importFrom survey svydesign as.svrepdesign calibrate
#' @importFrom magrittr %>%
#' @importFrom stats weights rnorm
NULL

# Funcion auxiliar para generar semillas derivadas
derive_seed <- function(base_seed, offset = 0) {
    if (is.null(base_seed)) {
        return(NULL)
    }
    return(base_seed + offset)
}

# Funcion auxiliar para emojis (uso interno)
emoji <- function(code) {
    intToUtf8(code, multiple = FALSE)
} # Funcion auxiliar para mejor manejo de errores en map operations
safe_map_dfr <- function(.x, .f, ..., .id = NULL) {
    # Crear version segura de la funcion
    safe_f <- purrr::safely(.f, quiet = FALSE)

    # Ejecutar map con version segura
    results <- purrr::map(.x, safe_f, ...)

    # Separar resultados y errores
    transposed <- purrr::transpose(results)

    # Verificar si hay errores
    errors <- transposed$error
    has_errors <- !sapply(errors, is.null)

    if (any(has_errors)) {
        # Encontrar primer error con contexto
        error_indices <- which(has_errors)
        first_error_idx <- error_indices[1]

        # Crear mensaje informativo
        element_name <- if (is.null(names(.x))) paste("elemento", first_error_idx) else names(.x)[first_error_idx]
        original_message <- conditionMessage(errors[[first_error_idx]])

        stop(
            "Error en iteracion de map() - ", element_name, ":\n",
            "Mensaje original: ", original_message, "\n",
            "Total errores: ", length(error_indices), " de ", length(.x), " elementos",
            call. = FALSE
        )
    }

    # Si no hay errores, combinar resultados
    successful_results <- transposed$result

    if (!is.null(.id)) {
        # Agregar columna ID si se especifica
        for (i in seq_along(successful_results)) {
            if (!is.null(successful_results[[i]])) {
                id_value <- if (is.null(names(.x))) as.character(i) else names(.x)[i]
                successful_results[[i]][[.id]] <- id_value
            }
        }
    }

    # Combinar en data frame
    do.call(rbind, successful_results)
}

# Funcion auxiliar para map regular con mejor manejo de errores
safe_map <- function(.x, .f, ...) {
    # Crear version segura de la funcion
    safe_f <- purrr::safely(.f, quiet = FALSE)

    # Ejecutar map con version segura
    results <- purrr::map(.x, safe_f, ...)

    # Separar resultados y errores
    transposed <- purrr::transpose(results)

    # Verificar si hay errores
    errors <- transposed$error
    has_errors <- !sapply(errors, is.null)

    if (any(has_errors)) {
        # Encontrar primer error con contexto
        error_indices <- which(has_errors)
        first_error_idx <- error_indices[1]

        # Crear mensaje informativo
        element_name <- if (is.null(names(.x))) paste("elemento", first_error_idx) else names(.x)[first_error_idx]
        original_message <- conditionMessage(errors[[first_error_idx]])

        stop(
            "Error en iteracion de map() - ", element_name, ":\n",
            "Mensaje original: ", original_message, "\n",
            "Total errores: ", length(error_indices), " de ", length(.x), " elementos",
            call. = FALSE
        )
    }

    # Devolver solo los resultados exitosos
    transposed$result
}

# Funcion auxiliar para agregar contexto personalizado a errores
add_error_context <- function(expr, context = NULL, element = NULL) {
    tryCatch(
        expr,
        error = function(e) {
            # Construir mensaje contextualizado
            context_msg <- if (!is.null(context)) paste("Contexto:", context) else ""
            element_msg <- if (!is.null(element)) paste("Elemento:", element) else ""

            # Mensaje original
            original_msg <- conditionMessage(e)

            # Combinar todo
            full_message <- paste(
                c(context_msg, element_msg, paste("Error original:", original_msg)),
                collapse = "\n"
            )

            stop(full_message, call. = FALSE)
        }
    )
}
