#' Validate Parameters
#'
#' Validates and organizes input parameters for the electoral simulation pipeline.
#'
#' @param survey_data Data frame with individual survey data (required if uncertainty_method is "bootstrap")
#' @param input_path Path to Excel input file with multiple sheets
#' @param output_file Path to the output RDS file where results will be saved (e.g., "output/results.rds")
#' @param uncertainty_method Type of input data: "bootstrap" or "mcmc"
#' @param strategy Projection strategy: "top_down" or "bottom_up"
#' @param nsims Number of Monte Carlo simulations for transfer matrices (or bootstrap replications if uncertainty_method is "bootstrap")
#' @param factor_correccion_abstencion Abstention correction factor (default 3)
#' @param factor_correccion_jovenes New voters correction factor (default 2.5)
#' @param factor_correccion_otbl Other+blank votes intention correction factor (default 3)
#' @param tiempo_entre_elecciones Years between elections for demographic adjustments
#' @param district_col Name of column in survey_data indicating province or electoral district
#' @param tau Parameter to control variability level of provincial party projection patterns (only needed if strategy is "top_down")
#' @param umbral Minimum vote threshold for seat assignment (default 0.03)
#' @param tipo_umbral Threshold type: "provincial", "autonomico" or "mixto" (default "provincial")
#' @param interval_level Confidence level for uncertainty intervals (default 0.9)
#' @param seed Seed for reproducibility (default NULL)
#' @param ... Additional arguments for bootstrap internal function. The current accepted parameters are calib_vars and weights. Only used when uncertainty_method is "bootstrap"
#' @param verbose Show progress messages (default TRUE)
#'
#' @return List with organized and validated parameters for the simulation pipeline
#'
#' @keywords internal
validate_params <- function(survey_data = NULL,
                            input_path,
                            output_file = NULL,
                            uncertainty_method = c("mcmc", "bootstrap"),
                            strategy = c("top_down", "bottom_up"),
                            nsims = 100,
                            factor_correccion_abstencion = 3,
                            factor_correccion_jovenes = 2.5,
                            factor_correccion_otbl = 3,
                            tiempo_entre_elecciones = 0.1,
                            district_col = "codigo_provincia",
                            tau = 300,
                            umbral = .03,
                            tipo_umbral = "provincial",
                            interval_level = .9,
                            censo = NULL,
                            verbose = TRUE,
                            seed = NULL, ...) {
  if (missing(survey_data) & uncertainty_method == "bootstrap") {
    stop("survey_data is required when uncertainty_method is 'bootstrap'")
  }

  # Validate input file
  if (!file.exists(input_path)) {
    stop("Input file not found: ", input_path)
  }
  if (!is.null(output_file) && !grepl("\\.rds$", output_file, ignore.case = TRUE)) {
    stop("output_file must have a .rds extension")
  }

  match.arg(uncertainty_method)
  match.arg(strategy)

  if (nsims <= 0 || !is.numeric(nsims)) {
    stop("nsims must be a positive number")
  }

  if (tau <= 0 || !is.numeric(tau)) {
    stop("tau must be a positive number")
  }

  # Configurar seed
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1) {
      stop("seed must be a single number")
    }
    set.seed(seed)
  } else if (verbose) {
    message("No seed provided - results will not be reproducible")
  }


  if (uncertainty_method == "bootstrap") {
    data <- survey_data
  } else {
    data <- NULL
  }

  # Validate censo if provided
  if (!is.null(censo)) {
    if (!is.data.frame(censo)) {
      stop("censo must be a data.frame")
    }
    if (!all(c("codigo_provincia", "censo_real") %in% names(censo))) {
      stop("censo must have columns 'codigo_provincia' and 'censo_real'")
    }
  }

  params <- list(
    data = list(
      input_data = data,
      input_path = input_path,
      district_col = district_col,
      censo = censo
    ),
    seats_allocation = list(
      umbral = umbral,
      tipo_umbral = tipo_umbral
    ),
    correction_params = list(
      factor_correccion_abstencion = factor_correccion_abstencion,
      factor_correccion_jovenes = factor_correccion_jovenes,
      factor_correccion_otbl = factor_correccion_otbl,
      tiempo_entre_elecciones = tiempo_entre_elecciones
    ),
    simulation = list(
      uncertainty_method = uncertainty_method,
      interval_level = interval_level,
      strategy = strategy,
      nsims = nsims,
      tau = tau,
      seed = seed
    ),
    output = list(
      output_file = output_file
    ),
    runtime = list(
      verbose = verbose
    )
  )
  return(params)
}




#' Load and validate electoral data from Excel
#'
#' Loads all necessary data from an Excel file with multiple sheets, validates it,
#' and returns input data in a list.
#'
#' @param input_path Path to input Excel file
#' @param uncertainty_method Type of input data: "mcmc" or "bootstrap"
#' @param strategy Modeling strategy: "top_down" or "bottom_up"
#' @param verbose Show progress messages (default TRUE)
#'
#' @return List with all validated input data
#'
#' @details
#' Required sheets in Excel:
#' - partidos: party codes for recuerdo and IDV
#' - mt_simplificada: transfer matrices with 'N' row
#' - patrones: historical patterns by province
#' - anteriores_elecciones: previous electoral results
#' - n_diputados: seats per province
#' - retoques: manual adjustments (optional)
#' - small_parties: small parties (optional)
#'
#' @family data-functions
#' @export
load_and_validate <- function(input_path, uncertainty_method, strategy, verbose = TRUE) {
  # Cargar codigos de partidos desde Excel
  partidos_data <- read_partidos(input_path)
  recuerdo_lvls <- partidos_data$recuerdo
  idv_lvls <- partidos_data$idv

  # Cargar datos principales
  data_list <- load_electoral_data(input_path, uncertainty_method, strategy)

  # 2. Validaciones
  if (verbose) message(emoji(0x2705), " Validating input data consistency...")
  validate_input_data(data_list, recuerdo_lvls, idv_lvls, uncertainty_method, strategy)

  return(data_list)
}

#' Cargar Datos Electorales desde Excel
#'
#' Carga todos los datos necesarios desde un archivo Excel con multiples hojas.
#'
#' @param input_path Ruta al archivo Excel de entrada
#' @param uncertainty_method Tipo de datos de entrada: "mcmc" (por defecto) o "bootstrap"
#'
#' @return Lista con todos los datos de entrada validados
#'
#' @details
#' Hojas requeridas en el Excel:
#' - partidos: codigos de partidos para recuerdo e IDV
#' - mt_simplificada: matrices de transferencia con fila 'N'
#' - patrones: patrones historicos por provincia
#' - anteriores_elecciones: resultados electorales anteriores
#' - n_diputados: escanos por provincia
#' - retoques: ajustes manuales (opcional)
#' - small_parties: partidos pequenos (opcional)
#'
#' @keywords internal
#'
load_electoral_data <- function(input_path,
                                uncertainty_method = c("mcmc", "bootstrap"),
                                strategy = c("top_down", "bottom_up")) {
  match.arg(strategy)

  if (strategy == "top_down") {
    return(load_electoral_data_top_down(input_path, uncertainty_method))
  } else {
    return(load_electoral_data_bottom_up(input_path, uncertainty_method))
  }
}

#' Cargar Datos Electorales Top-Down desde Excel
#'
#' Carga todos los datos necesarios desde un archivo Excel con multiples hojas
#'
#' @param input_path Ruta al archivo Excel de entrada
#' @param uncertainty_method Tipo de datos de entrada: "mcmc" (por defecto) o "bootstrap"
#' @return Lista con todos los datos de entrada validados
#' @details
#' Hojas requeridas en el Excel:
#' - partidos: codigos de partidos para recuerdo e IDV
#' - mt_simplificada: matrices de transferencia con fila 'N' (solo necesario si uncertainty_method es "mcmc")
#' - patrones: patrones historicos por provincia
#' - anteriores_elecciones: resultados electorales anteriores
#' - n_diputados: escanos por provincia
#' - retoques: ajustes manuales (opcional)
#' - small_parties: partidos pequenos (opcional)
#'
#' @keywords internal
#'
load_electoral_data_top_down <- function(input_path, uncertainty_method = c("mcmc", "bootstrap")) {
  # Verificar archivo existe
  if (!file.exists(input_path)) {
    stop("Archivo no encontrado: ", input_path)
  }

  match.arg(uncertainty_method)

  if (uncertainty_method == "mcmc") {
    required_sheets <- c(
      "partidos", "mt_simplificada", "patrones",
      "anteriores_elecciones", "n_diputados", "retoques"
    )
  } else {
    required_sheets <- c(
      "partidos", "patrones",
      "anteriores_elecciones", "n_diputados", "retoques"
    )
  }

  available_sheets <- excel_sheets(input_path)
  missing_sheets <- setdiff(required_sheets, available_sheets)

  if (length(missing_sheets) > 0) {
    stop("Missing sheets in ", input_path, ": ", paste(missing_sheets, collapse = ", "))
  }

  # Load main data
  result <- list(
    patrones = read_patrones(input_path),
    anteriores_elecciones = read_xlsx(input_path, sheet = "anteriores_elecciones"),
    n_diputados = read_xlsx(input_path, sheet = "n_diputados"),
    retoques = read_retoques(input_path, strategy = "top_down"),
    small_parties = read_small_parties(input_path, strategy = "top_down")
  )

  if (uncertainty_method == "mcmc") {
    partidos <- read_partidos(input_path)
    result$mt_simplificada <- read_mt(input_path, partidos$recuerdo, partidos$idv)
  }

  return(result)
}


#' Cargar Datos Electorales Bottom-Down desde Excel
#'
#' Carga todos los datos necesarios desde un archivo Excel con multiples hojas
#'
#' @param input_path Ruta al archivo Excel de entrada
#' @param uncertainty_method Solo puede ser "bootstrap"
#' @return Lista con todos los datos de entrada validados
#' @details
#' Hojas requeridas en el Excel:
#' - anteriores_elecciones: resultados electorales anteriores
#' - n_diputados: escanos por provincia
#' - retoques: ajustes manuales (opcional)
#' - small_parties: partidos pequenos (opcional)
#'
#' @keywords internal
#'
load_electoral_data_bottom_up <- function(input_path, uncertainty_method) {
  if (uncertainty_method != "bootstrap") {
    stop("For 'bottom_up' strategy, uncertainty_method must be 'bootstrap'")
  }

  # Verificar archivo existe
  if (!file.exists(input_path)) {
    stop("Archivo no encontrado: ", input_path)
  }

  # Verificar hojas requeridas
  required_sheets <- c(
    "partidos", "anteriores_elecciones",
    "n_diputados", "retoques"
  )

  available_sheets <- readxl::excel_sheets(input_path)
  missing_sheets <- setdiff(required_sheets, available_sheets)

  if (length(missing_sheets) > 0) {
    stop("Missing sheets in ", input_path, ": ", paste(missing_sheets, collapse = ", "))
  }

  # Load main data
  result <- list(
    anteriores_elecciones = read_xlsx(input_path, sheet = "anteriores_elecciones"),
    n_diputados = read_xlsx(input_path, sheet = "n_diputados"),
    retoques = read_retoques(input_path, strategy = "bottom_up"),
    small_parties = read_small_parties(input_path, strategy = "bottom_up")
  )
  return(result)
}


















#' Cargar codigos de Partidos
#'
#' Extrae los codigos de partidos desde la hoja 'partidos' del Excel.
#'
#' @param input_path Ruta al archivo Excel
#'
#' @return Lista con vectores 'recuerdo' e 'idv' de codigos de partidos
#'
#' @export
read_partidos <- function(input_path) {
  partidos_df <- readxl::read_xlsx(input_path, sheet = "partidos")

  # Validar estructura
  required_cols <- c("idv", "recuerdo")
  missing_cols <- setdiff(required_cols, names(partidos_df))

  if (length(missing_cols) > 0) {
    stop("Missing columns in 'partidos' sheet: ", paste(missing_cols, collapse = ", "))
  }

  # Extraer codigos unicos manteniendo orden
  idv_codes <- partidos_df$idv[!is.na(partidos_df$idv)]
  recuerdo_codes <- partidos_df$recuerdo[!is.na(partidos_df$recuerdo)]

  return(list(
    idv = unique(idv_codes),
    recuerdo = unique(recuerdo_codes)
  ))
}

#' Leer Matriz de Transferencia
#'
#' Lee la matriz de transferencia desde la hoja 'mt_simplificada' del archivo Excel
#' y la procesa para uso en simulaciones.
#'
#' @param path Ruta al archivo Excel
#' @param recuerdo_lvls Vector con codigos de recuerdo validos
#' @param idv_lvls Vector con codigos IDV validos
#'
#' @return Data frame con matriz de transferencia procesada con columnas:
#'   recuerdo, idv, n (numero de encuestados)
#'
#' @details
#' La hoja 'mt_simplificada' debe contener:
#' - Columna 'idv' con codigos de intencion de voto
#' - Columnas con codigos de recuerdo (porcentajes)
#' - Fila 'N' con tamanos de muestra por columna de recuerdo
#'
#' @export
read_mt <- function(path, recuerdo_lvls, idv_lvls) {
  mt <- read_xlsx(path, sheet = "mt_simplificada")

  first_col <- colnames(mt)[1]
  if (first_col != "idv") {
    if (tolower(first_col) == "idv_aut") {
      message("Renombrando primera columna 'idv_aut' a 'idv'")
      colnames(mt)[1] <- "idv"
    } else {
      stop("First column of matrix must be called 'idv'")
    }
  }

  mt <- calculate_n(mt) %>%
    mutate(
      recuerdo = factor(recuerdo, levels = recuerdo_lvls),
      idv = factor(idv, levels = unique(c(idv_lvls, "Indecisos")))
    )

  return(mt)
}

#' Read Provincial Patterns
#'
#' Reads district patterns from the 'patrones' sheet of the Excel file.
#'
#' @param path Path to Excel file
#'
#' @return Data frame with district patterns containing columns:
#'   codigo_provincia, idv, patron (proportion 0-1)
#'
#' @details
#' The 'patrones' sheet must contain:
#' - Column 'codigo_provincia' with electoral district codes
#' - Columns with 'idv' names (percentages 0-100)
#' - Patterns are automatically converted to proportions (0-1)
#'
#' @export
read_patrones <- function(path) {
  # Leer y transformar patrones
  patrones <-
    read_xlsx(path, sheet = "patrones")

  # Validate first column
  if (names(patrones)[1] != "codigo_provincia") {
    stop("First column of 'patrones' sheet must be 'codigo_provincia'")
  }

  patrones <- patrones %>%
    select(-any_of("TOTAL")) %>%
    pivot_longer(2:ncol(.), names_to = "idv", values_to = "patron") %>%
    mutate(patron = patron / 100) %>%
    filter(patron > 0)

  return(patrones)
}

#' Read Manual Adjustments
#'
#' Reads manual adjustments from the 'retoques' sheet of the Excel file.
#'
#' @param path Path to Excel file
#'
#' @return Data frame with valid adjustments containing columns:
#'   idv, votos_adicionales
#'
#' @details
#' The 'retoques' sheet must contain:
#' - Column 'idv' with party names
#' - Column 'votos_adicionales' with adjustments (positive or negative)
#' - Column 'codigo_provincia' if strategy is "bottom_up"
#' - Only rows with votos_adicionales != 0 and != NA are included
#'
#' @keywords internal
read_retoques <- function(path, strategy = c("top_down", "bottom_up")) {
  match.arg(strategy)

  if (strategy == "bottom_up") {
    col_types <- c("text", "text", "numeric")
    required_cols <- c("codigo_provincia", "idv", "votos_adicionales")
  } else {
    col_types <- c("text", "numeric")
    required_cols <- c("idv", "votos_adicionales")
  }

  retoques <- readxl::read_xlsx(path, sheet = "retoques", col_types = col_types)

  if (!all(required_cols %in% names(retoques))) {
    stop("Retoques must contain columns: ", paste(required_cols, collapse = ", "))
  }

  # Filter only rows with non-null votos_adicionales
  retoques_clean <- retoques %>%
    filter(!is.na(votos_adicionales), votos_adicionales != 0)

  return(retoques_clean)
}


#' Read Small Parties
#'
#' Reads small parties data from the 'small_parties' sheet of the Excel file.
#'
#' @param path Path to Excel file
#' @param strategy Modeling strategy: "top_down" or "bottom_up"
#'
#' @return Data frame with valid small parties containing columns:
#'  idv, votos (and codigo_provincia if strategy is "bottom_up")
#'
#' @details
#' The 'small_parties' sheet must contain:
#' - Column 'idv' with party codes
#' - Column 'votos' with vote estimates
#' - Column 'codigo_provincia' if strategy is "bottom_up"
#' - Only rows with votos != 0 and != NA are included
#'
#'
#' @keywords internal
read_small_parties <- function(path, strategy = c("top_down", "bottom_up")) {
  match.arg(strategy)

  if (strategy == "bottom_up") {
    col_types <- c("text", "text", "numeric")
    required_cols <- c("codigo_provincia", "idv", "votos")
  } else {
    col_types <- c("text", "numeric")
    required_cols <- c("idv", "votos")
  }

  small_parties <- read_xlsx(path, sheet = "small_parties", col_types = col_types)

  if (!all(required_cols %in% names(small_parties))) {
    stop("'Small parties' sheet must contain columns: ", paste(required_cols, collapse = ", "))
  }

  # Filter only rows with non-null votes
  small_parties_clean <- small_parties %>%
    filter(!is.na(votos), votos != 0)

  return(small_parties_clean)
}


#' Validate Input Data
#'
#' Validates the consistency and completeness of all input data for the electoral pipeline.
#'
#' @param data_list List with data loaded from Excel
#' @param recuerdo_lvls Vector with valid recuerdo codes
#' @param idv_lvls Vector with valid IDV codes
#' @param uncertainty_method Type of input data: "mcmc" or "bootstrap"
#' @param strategy Modeling strategy: "top_down" or "bottom_up"
#'
#' @return TRUE if all data is valid, or stops execution with error
#'
#' @details
#' Performs the following validations:
#' - Verifies presence of required elements in data_list
#' - Validates party codes in transfer matrices
#' - Verifies consistency between provincial patterns and IDV codes
#' - Validates previous election data
#' - Verifies province correspondence between seats and patterns sheets
#' - Validates adjustments and small parties if present
#'
#' @family data-functions
#' @family validation-functions
#' @export
validate_input_data <- function(data_list, recuerdo_lvls, idv_lvls,
                                uncertainty_method = c("mcmc", "bootstrap"),
                                strategy = c("top_down", "bottom_up")) {
  match.arg(uncertainty_method)
  match.arg(strategy)

  if (strategy == "top_down") {
    return(validate_input_data_top_down(
      data_list, recuerdo_lvls, idv_lvls,
      uncertainty_method
    ))
  } else {
    return(validate_input_data_bottom_down(
      data_list, recuerdo_lvls, idv_lvls,
      uncertainty_method
    ))
  }
}


validate_input_data_top_down <- function(data_list, recuerdo_lvls, idv_lvls,
                                         uncertainty_method = c("mcmc", "bootstrap")) {
  match.arg(uncertainty_method)

  # Validar estructura de la lista
  if (uncertainty_method == "mcmc") {
    required_elements <- c("mt_simplificada", "patrones", "anteriores_elecciones", "n_diputados")
  } else {
    required_elements <- c("patrones", "anteriores_elecciones", "n_diputados")
  }
  missing_elements <- setdiff(required_elements, names(data_list))

  if (length(missing_elements) > 0) {
    stop("Missing elements in input data: ", paste(missing_elements, collapse = ", "))
  }

  if (uncertainty_method == "mcmc") {
    # Validate party codes in MT
    check_mt(mt = data_list$mt_simplificada, recuerdo_lvls, idv_lvls)
  }

  # Validate provincial patterns
  if (!"codigo_provincia" %in% names(data_list$patrones)) {
    stop("Patterns must contain 'codigo_provincia' column")
  }
  check_patrones(data_list$patrones, idv_lvls)


  # Validate previous elections
  check_votos_ant(data_list$anteriores_elecciones, recuerdo_lvls)

  # Validate seats per province
  check_nseats(data_list$n_diputados, data_list$patrones, strategy = "top_down")

  check_retoques(data_list$retoques, idv_lvls)

  # check_small_parties(data_list$small_parties, idv_lvls)

  message("Data validation completed successfully")
  return(TRUE)
}



validate_input_data_bottom_down <- function(data_list, recuerdo_lvls, idv_lvls,
                                            uncertainty_method) {
  if (uncertainty_method != "bootstrap") {
    stop("For 'bottom_up' strategy, uncertainty_method must be 'bootstrap'")
  }

  required_elements <- c("anteriores_elecciones", "n_diputados")

  missing_elements <- setdiff(required_elements, names(data_list))

  if (length(missing_elements) > 0) {
    stop("Missing elements in input data: ", paste(missing_elements, collapse = ", "))
  }

  # Validate previous elections
  check_votos_ant(data_list$anteriores_elecciones, recuerdo_lvls)

  # Validate seats per province
  check_nseats(data_list$n_diputados, data_list$patrones, strategy = "bottom_up")

  check_retoques(data_list$retoques, idv_lvls)

  # check_small_parties(data_list$small_parties, idv_lvls)

  message("Data validation completed successfully")
  return(TRUE)
}


#' Validate Vote Transfer Matrix
#'
#' Validates that party codes in the transfer matrix
#' correspond to expected categories.
#'
#' @param mt Data frame with transfer matrix
#' @param recuerdo_lvls Vector with valid recuerdo codes
#' @param idv_lvls Vector with valid IDV codes
#'
#' @return Invisible(TRUE) if valid, or error if not
#' @keywords internal
check_mt <- function(mt, recuerdo_lvls, idv_lvls) {
  recuerdo_values <- unique(mt$recuerdo)
  idv_values <- unique(mt$idv)
  MUST_VALUES <- c("ABNL", "OTBL", "<18")
  if (!all(MUST_VALUES %in% recuerdo_lvls)) {
    recuerdo_lvls <- c(recuerdo_lvls, setdiff(MUST_VALUES, recuerdo_lvls))
  }
  check_factor_lvls(recuerdo_values, recuerdo_lvls, idv_values, idv_lvls)
}

#' Validate District Patterns
#'
#' Validates that IDV names in district patterns are valid.
#'
#' @param patrones Data frame with district patterns
#' @param idv_lvls Vector with valid IDV codes
#'
#' @return Invisible(TRUE) if valid, or error if not
#' @keywords internal
check_patrones <- function(patrones, idv_lvls) {
  idv_lvls <- idv_lvls[!idv_lvls %in% c("ABNL", "Indecisos")]
  check_factor_lvls(idv_var = patrones$idv, idv_lvls = idv_lvls)
}

#' Validate Previous Election Data
#'
#' Validates that previous election data contains
#' all necessary party codes.
#'
#' @param votos_ant Data frame with previous electoral results
#' @param recuerdo_lvls Vector with valid 'recuerdo' codes
#'
#' @return Invisible(TRUE) si es valida, o error si no
#' @keywords internal
check_votos_ant <- function(votos_ant, recuerdo_lvls) {
  MUST_COLS <- c("recuerdo", "votos_ant")
  recuerdo_lvls <- recuerdo_lvls[recuerdo_lvls != "<18"]
  if (!all(MUST_COLS %in% colnames(votos_ant))) {
    stop(sprintf(
      "votos_ant debe contener las columnas: %s",
      paste(MUST_COLS, collapse = ", ")
    ))
  }

  votos_ant <- filter(votos_ant, !is.na(votos_ant))
  recuerdo_votos <- votos_ant$recuerdo

  if (!all(recuerdo_lvls %in% recuerdo_votos)) {
    recuerdo_missing <- recuerdo_lvls[!recuerdo_lvls %in% recuerdo_votos]
    stop(sprintf(
      "Faltan valores en la columna 'recuerdo': %s",
      paste0(recuerdo_missing, collapse = ", ")
    ))
  }
}

#' Validar Niveles de Factores
#'
#' Valida que los valores observados en variables de recuerdo e IDV
#' esten dentro de las categorias esperadas.
#'
#' @param recuerdo_var Vector con valores observados de recuerdo (opcional)
#' @param recuerdo_lvls Vector con niveles validos de recuerdo (opcional)
#' @param idv_var Vector con valores observados de IDV (opcional)
#' @param idv_lvls Vector con niveles validos de IDV (opcional)
#'
#' @return Invisible(TRUE) si es valida, o error si hay valores no previstos
#' @keywords internal
check_factor_lvls <- function(recuerdo_var = NULL, recuerdo_lvls = NULL,
                              idv_var = NULL, idv_lvls = NULL) {
  if (!is.null(recuerdo_var)) {
    recuerdo_var <- unique(recuerdo_var)
    # Check para que la recodificacion coincida con los levels previstos
    if (length(setdiff(recuerdo_lvls, recuerdo_var)) > 0) {
      stop(
        "Hay niveles de recuerdo no previstos: ",
        paste(setdiff(recuerdo_lvls, recuerdo_var), collapse = ", ")
      )
    }
  }
  if (!is.null(idv_var)) {
    idv_var <- unique(idv_var)
    if (length(setdiff(idv_lvls, idv_var)) > 0) {
      stop(
        "Hay niveles de idv no previstos: ",
        paste(setdiff(idv_lvls, idv_var), collapse = ", ")
      )
    }
  }
}

#' Validar Correspondencia de escanos por Provincia
#'
#' Valida que las provincias en los datos de escanos correspondan
#' con las provincias en los patrones provinciales.
#'
#' @param n_seats Data frame con escanos por provincia
#' @param patrones Data frame con patrones provinciales
#'
#' @return Invisible(TRUE) si es valida, warning/error segun corresponda
#' @keywords internal
check_nseats <- function(n_seats, patrones, strategy = "top_down") {
  MUST_COLS <- c("codigo_provincia", "n_diputados")
  if (!all(MUST_COLS %in% colnames(n_seats))) {
    stop(sprintf(
      "n_seats debe contener las columnas: %s",
      paste(MUST_COLS, collapse = ", ")
    ))
  }

  if (strategy == "top_down") {
    provincias_patrones <- unique(patrones$codigo_provincia)
    provincias_nseats <- unique(n_seats$codigo_provincia)

    if (!all(provincias_patrones %in% provincias_nseats)) {
      stop(
        "Hay provincias en patrones que no estan en n_seats: ",
        paste(setdiff(provincias_patrones, provincias_nseats),
          collapse = ", "
        )
      )
    }

    if (!all(provincias_nseats %in% provincias_patrones)) {
      warning(
        "Hay provincias en n_seats que no estan en patrones: ",
        paste(setdiff(provincias_nseats, provincias_patrones),
          collapse = ", "
        )
      )
    }
  }
}

#' Validar Retoques (Ajustes Manuales)
#'
#' Valida que los codigos de partido en retoques esten
#' dentro de los codigos IDV validos.
#'
#' @param retoques Data frame con ajustes manuales
#' @param idv_lvls Vector con codigos IDV validos
#'
#' @return Invisible(TRUE) si es valida, o error si no
#' @keywords internal
check_retoques <- function(retoques, idv_lvls) {
  idv_retoques <- retoques$idv
  if (!all(idv_retoques %in% idv_lvls)) {
    stop(
      "Hay partidos en retoques que no estan en idv_lvls: ",
      paste(setdiff(idv_retoques, idv_lvls), collapse = ", ")
    )
  }
}

#' Validar Partidos pequenos
#'
#' Valida que los codigos de partido en small_parties esten
#' dentro de los codigos IDV validos.
#'
#' @param small_parties Data frame con partidos pequenos
#' @param idv_lvls Vector con codigos IDV validos
#'
#' @return Invisible(TRUE) si es valida, o error si no
#' @keywords internal
check_small_parties <- function(small_parties, idv_lvls) {
  idv_small_parties <- small_parties$idv
  if (!all(idv_small_parties %in% idv_lvls)) {
    stop(
      "Hay partidos en small_parties que no estan en idv_lvls: ",
      paste(setdiff(idv_small_parties, idv_lvls), collapse = ", ")
    )
  }
}
