#' Set up electoral project
#'
#' Creates directory structure and template files for a new electoral project.
#'
#' @param project_dir Project directory (will be created if it doesn't exist)
#'
#' @return Invisible(NULL). Function is executed for its side effects.
#'
#' @details
#' This function:
#' - Creates input/, output/ and scripts/ folders
#' - Generates an Excel file with all sheets required by the pipeline
#' - Creates a main example script in scripts/main.R
#'
#' @examples
#' \dontrun{
#' setup_electoral_project("my_simulation_2023")
#' }
#'
#' @family utility-functions
#' @family project-setup
#' @export
setup_electoral_project <- function(project_dir) {
  stopifnot(is.character(project_dir), nchar(project_dir) > 0)

  # Create directory structure
  dir.create(file.path(project_dir, "input"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(project_dir, "output"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(project_dir, "scripts"), recursive = TRUE, showWarnings = FALSE)

  # Create data template
  create_input_template(file.path(project_dir, "input", "input.xlsx"))

  # Create main script
  main_script <- paste0(
    "# Electoral Simulation\n",
    "library(vota)\n\n",
    "# Run complete simulation\n",
    "resultados <- run_vota(\n",
    "  input_path = \"input/input.xlsx\",\n",
    "  output_file = \"output/results.rds\",\n",
    "  uncertainty_method = \"mcmc\",\n",
    "  nsims = 100,\n",
    "  factor_correccion_abstencion = 3,\n",
    "  factor_correccion_jovenes = 2.5,\n",
    "  factor_correccion_otbl = 2.5,\n",
    "  tiempo_entre_elecciones = 0.1,\n",
    "  verbose = TRUE\n",
    ")\n\n",
    "# View results\n",
    "print(resultados)\n",
    "summary(resultados)\n",
    "plot(resultados, 'nacional')\n",
    "plot(resultados, 'seats_dist')\n",
    "plot(resultados, 'provincia', partido = 'PSOE')\n",
    "plot(resultados, 'dhondt_margin')\n"
  )

  writeLines(main_script, file.path(project_dir, "scripts", "main.R"))

  # message("✓ Proyecto electoral configurado en: ", normalizePath(project_dir, winslash = "/", mustWork = FALSE))
  # message("✓ Directorios creados: input/, output/, scripts/")
  # message("✓ Plantilla de datos creada: input/input.xlsx")
  # message("✓ Script principal creado: scripts/main.R")
}


#' Crear plantilla de archivos de entrada
#'
#' Genera un archivo Excel con todas las hojas necesarias para el analisis electoral.
#'
#' Sheets created and minimum columns required by package:
#' - partidos: idv, recuerdo
#' - mt_simplificada: idv + recuerdo columns + 'N' row
#' - patrones: codigo_provincia + party columns (percentage 0-100)
#' - anteriores_elecciones: recuerdo, votos_ant
#' - n_diputados: codigo_provincia, n_diputados
#' - retoques: idv, votos_adicionales
#' - small_parties: idv, votos
#'
#' @param file_path Path of Excel file to create
#' @return Returns (invisibly) path to created file
#'
#' @family utility-functions
#' @family project-setup
#' @export
create_input_template <- function(file_path = "input/input.xlsx") {
  stopifnot(is.character(file_path), nchar(file_path) > 0)

  # Create workbook
  wb <- openxlsx::createWorkbook()

  # Example encodings (consistent with readers)
  # recuerdo_lvls <- c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL", "<18")
  # idv_lvls <- c("PSOE", "PP", "Vox", "Sumar", "Podemos", "ERC", "SALF", "Junts",
  #               "PNV", "EH Bildu", "CCa", "OTBL", "ABNL")

  # Hoja 1: Partidos
  openxlsx::addWorksheet(wb, "partidos")
  openxlsx::writeData(wb, "partidos", c("recuerdo", partidos$recuerdo), startCol = 1)
  openxlsx::writeData(wb, "partidos", c("idv", partidos$idv), startCol = 2)

  # Hoja 2: MT simplificada (ejemplo ancho con fila N)
  openxlsx::addWorksheet(wb, "mt_simplificada")
  openxlsx::writeData(wb, "mt_simplificada", mt)

  # Hoja 3: Patrones provinciales (porcentajes 0-100)
  openxlsx::addWorksheet(wb, "patrones")
  openxlsx::writeData(wb, "patrones", patrones_23J)

  # Hoja 4: Anteriores elecciones
  openxlsx::addWorksheet(wb, "anteriores_elecciones")
  openxlsx::writeData(wb, "anteriores_elecciones", votos_23J)

  # Hoja 5: n_diputados
  openxlsx::addWorksheet(wb, "n_diputados")
  openxlsx::writeData(wb, "n_diputados", n_seats)

  # Hoja 6: Retoques
  openxlsx::addWorksheet(wb, "retoques")
  openxlsx::writeData(wb, "retoques", retoques)

  # Hoja 7: Partidos pequenos (opcional)
  openxlsx::addWorksheet(wb, "small_parties")
  openxlsx::writeData(wb, "small_parties", small_parties)

  # Guardar archivo
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)

  message("Plantilla creada: ", normalizePath(file_path, winslash = "/", mustWork = FALSE))
  invisible(file_path)
}

#' Crear proyecto desde plantilla
#'
#' funcion de conveniencia para crear un proyecto completo con datos de ejemplo.
#'
#' @param name Nombre del proyecto (usado para el directorio)
#' @param path Directorio donde crear el proyecto (por defecto ".")
#'
#' @return Devuelve (invisiblemente) la ruta del proyecto creado
#'
#' @details
#' Esta funcion es un wrapper de `setup_electoral_project()` que ademas
#' proporciona mensajes informativos sobre como usar el proyecto creado.
#'
#' @examples
#' \dontrun{
#' # Crear proyecto en directorio actual
#' create_vota_project("elecciones_2023")
#'
#' # Crear proyecto en ubicacion especifica
#' create_vota_project("valencia_2023", path = "/proyectos/")
#' }
#'
#' @export
create_vota_project <- function(name = "", path = ".") {
  stopifnot(is.character(name), nchar(name) > 0)

  project_dir <- file.path(path, name)
  if (dir.exists(project_dir)) {
    stop("Directory '", project_dir, "' already exists.")
  }

  setup_electoral_project(project_dir)

  message("Proyecto '", name, "' creado exitosamente")
  message("Ubicacion: ", normalizePath(project_dir, winslash = "/", mustWork = FALSE))
  message("Edita: ", file.path(project_dir, "input", "input.xlsx"))
  message("Ejecuta: source(\"", file.path(project_dir, "scripts", "main.R"), "\")")

  invisible(project_dir)
}
