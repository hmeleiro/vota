#' Generate transfer matrix simulations
#'
#' Generates simulated transfer matrices using MCMC or bootstrapping
#'
#' @param data Data frame with transfer matrix. When using bootstrapping,
#' sample data should be provided where each row represents an individual.
#' If uncertainty_method = 'mcmc', an aggregated transfer matrix should be provided.
#' @param district_col Column name for district identifier (used in bottom-up strategy)
#' @param strategy Strategy for transfer matrix: "top_down" or "bottom_up"
#' @param uncertainty_method Uncertainty method: "mcmc" or "bootstrap"
#' @param nsims Number of simulations to generate
#' @param calib_vars Variables for calibration (vector of column names, optional)
#' @param weights Name of column with reference weights for calibration (optional)
#' @param seed Seed for reproducibility (optional)
#' @param verbose Show progress messages (default TRUE)
#'
#' @return Data frame with transfer matrix simulations
#'
#' @family simulation-functions
#' @family data-functions
#' @export
draw_mt <- function(data, district_col, uncertainty_method = c("bootstrap", "mcmc"),
                    strategy = c("top_down", "bottom_up"), nsims,
                    calib_vars = NULL, weights = NULL, seed, verbose = T) {
  match.arg(uncertainty_method)
  match.arg(strategy)

  if (uncertainty_method == "mcmc") {
    if (verbose) message(emoji(0x1F3B2), " Generating Monte Carlo simulations (MCMC)...")
    mt_sims <- simulate_mt(
      mt_data = data,
      nsims = nsims,
      seed = derive_seed(seed, 1)
    )
  } else if (uncertainty_method == "bootstrap") {
    if (verbose) message(emoji(0x1F97E), " Bootstrapping...", emoji(0x1F501))
    bootstrap_replicas <- bootstrap(data, nsims, calib_vars, weights)

    if (strategy == "bottom_up") {
      mt_sims <-
        bootstrap_replicas %>%
        group_by(sim, !!sym(district_col), recuerdo, idv) %>%
        tally(w_rep) %>%
        mutate(transfer = n / sum(n))
    } else {
      mt_sims <-
        bootstrap_replicas %>%
        group_by(sim, recuerdo, idv) %>%
        tally(w_rep) %>%
        mutate(transfer = n / sum(n))
    }
  }
  return(mt_sims)
}


draw_mt_bottom_up <- function(data, uncertainty_method = c("bootstrap", "mcmc"),
                              nsims, calib_vars, weights, seed, verbose = T) {
  match.arg(uncertainty_method)

  if (uncertainty_method == "mcmc") {
    if (verbose) message(emoji(0x1f3b2), " Generando simulaciones Monte Carlo (MCMC)...")
    mt_sims <- simulate_mt(
      mt_data = data,
      nsims = nsims,
      seed = derive_seed(seed, 1)
    )
  } else if (uncertainty_method == "bootstrap") {
    mt_sims <- bootstrap(data, nsims, calib_vars, weights)
  }
  return(mt_sims)
}


#' Simulaciones Monte Carlo de Matrices de Transferencia
#'
#' Genera simulaciones multinomiales de matrices de transferencia preservando
#' las distribuciones marginales observadas.
#'
#' @param mt_data Data frame con matriz de transferencia
#' @param nsims Numero de simulaciones a generar (por defecto 10)
#' @param seed Semilla para reproducibilidad (opcional)
#'
#' @return Data frame con simulaciones de matrices de transferencia
#'
#' @details
#' Esta funcion implementa simulacion multinomial para generar variabilidad
#' en las matrices de transferencia, manteniendo la estructura de dependencia
#' entre intencion de voto y recuerdo de voto anterior.
#'
#' @export
simulate_mt <- function(mt_data, nsims = 10, seed = NULL) {
  # Establecer semilla si se proporciona
  if (!is.null(seed)) set.seed(seed)

  # Validar entrada
  if (!is.data.frame(mt_data)) {
    stop("mt_data must be a data.frame")
  }

  required_cols <- c("idv")
  if (!all(required_cols %in% names(mt_data))) {
    stop("mt_data must contain 'idv' column")
  }

  # Extraer columna n (tamanos de muestra)
  if (!"n" %in% colnames(mt_data)) {
    stop("Matriz de transferencia debe contener fila 'N' con tamanos de muestra")
  }

  N <- sum(mt_data$n)

  mt_cero <-
    mt_data %>%
    mutate(sim = 0) %>%
    transmute(sim, recuerdo, idv, n, transfer = pct_original / 100)

  mt_sims <-
    rmultinom(nsims, N, mt_data$n) %>%
    as.data.frame() %>%
    mutate(recuerdo = mt_data$recuerdo, idv = mt_data$idv, .before = 1) %>%
    pivot_longer(3:ncol(.), names_to = "sim", values_to = "n") %>%
    mutate(sim = as.numeric(gsub("V", "", sim))) %>%
    arrange(sim, recuerdo, idv) %>%
    group_by(sim, recuerdo) %>%
    mutate(transfer = n / sum(n)) %>%
    ungroup() %>%
    relocate(sim, .before = 1)


  mt_sims <- rbind(mt_cero, mt_sims) %>%
    mutate(transfer = if_else(is.nan(transfer), 0, transfer))

  return(mt_sims)
}

#' Simulaciones Monte Carlo de matrices de provincia x partido
#'
#' Genera simulaciones multinomiales de resultados de cada partido en cada provincia
#'
#' @param patrones data frame con patrones provinciales (columnas: codigo_provincia, idv, patron)
#' @param estimacion vector con votos nacionales por partido (nombres = colnames(patrones))
#' @param method Metodo de simulacion: "dirichlet" o "logitnorm"
#' @param tau Concentracion para Dirichlet (escalar o vector por partido)
#' @param sigma Desviacion estandar del ruido en log-escala para Logistic-normal
#' @param Sigma Matriz de covarianza opcional (PxP) para correlacion espacial
#' @param eps Smoothing para evitar ceros exactos en patrones
#' @param seed Semilla para reproducibilidad (por defecto NULL)
#'
#' @return Matriz con simulacion de votos por provincia (filas = provincias, columnas = partidos)
#' @export
simulate_prov_votes <- function(patrones, estimacion, method = c("dirichlet", "logitnorm"),
                                tau = 300, sigma = 0.15, Sigma = NULL, eps = 1e-12, seed = NULL) {
  softmax <- function(x) {
    e <- exp(x - max(x))
    e / sum(e)
  }

  method <- match.arg(method)
  if (!is.null(seed)) set.seed(seed)

  patrones <- patrones %>%
    pivot_wider(names_from = idv, values_from = patron, values_fill = 0)

  codigos_provincias <- patrones$codigo_provincia
  partidos <- estimacion$idv
  votos <- estimacion$votos
  votos <- setNames(votos, partidos)

  if (!all(names(votos) %in% colnames(patrones))) {
    missing_parties <- names(votos)[!names(votos) %in% colnames(patrones)]
    stop(
      "Los siguientes partidos de 'estimacion' no estan en 'patrones': ",
      paste(missing_parties, collapse = ", ")
    )
  }

  patrones <- as.matrix(patrones[, names(votos), drop = FALSE])
  rownames(patrones) <- codigos_provincias
  votos <- votos[colnames(patrones)]
  P <- nrow(patrones)
  K <- ncol(patrones)

  # Smoothing para evitar ceros exactos
  patrones <- pmax(patrones, eps)
  patrones <- sweep(patrones, 2, colSums(patrones), "/")

  patt_draw <- matrix(NA_real_, nrow = P, ncol = K, dimnames = dimnames(patrones))

  if (method == "dirichlet") {
    # tau puede ser escalar o vector con longitud K
    if (length(tau) == 1L) {
      tau <- rep(tau, K)
    }
    for (k in seq_len(K)) {
      alpha <- tau[k] * patrones[, k]
      patt_draw[, k] <- as.numeric(rdirichlet(1, alpha))
    }
  } else {
    # Logistic-normal: mete ruido gaussiano en log-shares y re-normaliza con softmax
    # Puedes permitir correlación espacial con Sigma (PxP). Si es NULL -> I
    if (is.null(Sigma)) Sigma <- diag(P)
    # proyección para que el centro no cambie: quitamos componente de suma-constante
    One <- matrix(1 / P, P, P)
    Proj <- diag(P) - One
    # Cholesky (robusto)
    cholS <- chol(Sigma + 1e-10 * diag(P))
    for (k in seq_len(K)) {
      mu <- log(patrones[, k])
      z <- rnorm(P) # ruido básico
      epsL <- sigma * (cholS %*% z)
      eta <- mu + as.vector(Proj %*% epsL) # quita deriva común (mantiene suma)
      patt_draw[, k] <- softmax(eta)
    }
  }

  # Multinomial conjunta global (una sola sobre todas las celdas)
  N_total <- round(sum(votos))
  pi_mat <- sweep(patt_draw, 2, votos, "*") # pondera por fuerza nacional
  pi_vec <- as.vector(pi_mat)
  pi_vec <- pi_vec / sum(pi_vec)
  draw_vec <- as.vector(rmultinom(1, size = N_total, prob = pi_vec))
  matrix(draw_vec, nrow = P, ncol = K, dimnames = dimnames(patrones))
}

#' Bootstrapping de datos de encuesta
#'
#' Genera replicas de datos de encuesta usando bootstrapping con reemplazo
#'
#' @param data Data frame con datos de encuesta (columnas: recuerdo, idv, ponde)
#' @param B Numero de replicas a generar
#' @param calib_vars Variables para calibracion (vector de nombres de columnas)
#' @param weights Nombre de la columna con pesos de referencia para calibracion
#'
#' @return Data frame con replicas de datos de encuesta
#'
#'
#' @keywords internal
bootstrap <- function(data, B, calib_vars, weights) {
  if (!is.null(calib_vars) & !is.null(weights)) {
    des <- svydesign(ids = ~1, data = data, weights = data[[weights]])
    des_rep <- as.svrepdesign(des, type = "bootstrap", replicates = B)

    formula <- stats::reformulate(calib_vars, intercept = FALSE)
    mm <- stats::model.matrix(formula, data = data)
    # Totales objetivo = suma ponderada por 'weights' de cada dummy
    pop_totals <- as.numeric(colSums(mm * data[[weights]], na.rm = TRUE))
    names(pop_totals) <- colnames(mm)
    pop_totals <- pop_totals[pop_totals > 0]

    des_rep <- calibrate(
      des_rep,
      formula    = formula,
      population = pop_totals, # o un named vector en el mismo orden de columnas de model.matrix
      calfun     = "raking" # o "linear", "logit"
    )
  } else {
    des <- svydesign(ids = ~1, data = data)
    des_rep <- as.svrepdesign(des, type = "bootstrap", replicates = B)
  }

  bootstrap_replicas <-
    map(1:B, ~ get_replica_df(des_rep, .x)) %>%
    bind_rows()

  return(bootstrap_replicas)
}


#' Extrae una replica de un objeto svrepdesign
#'
#' @param des_rep Objeto svrepdesign con replicas
#' @param j Numero de replica a extraer
#'
#' @return Data frame con datos de la replica j
#'
#' @keywords internal
get_replica_df <- function(des_rep, j) {
  df <- des_rep$variables
  RWc <- as.matrix(des_rep$repweights)
  w_base <- weights(des_rep, type = "sampling")
  W_rep_full <- RWc * w_base

  df$w_rep <- W_rep_full[, j]
  df$sim <- j
  return(df)
}
