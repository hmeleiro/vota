# Integration tests for the complete electoral pipeline

# Helper function to create complete test dataset
create_complete_test_data <- function() {
  # Party codes
  recuerdo_lvls <- c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL", "<18")
  idv_lvls <- c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL")

  # Transfer matrix with n column for simulate_mt
  mt_simplificada <- expand.grid(
    recuerdo = recuerdo_lvls,
    idv = idv_lvls,
    stringsAsFactors = FALSE
  ) %>%
    dplyr::mutate(
      pct_original = dplyr::case_when(
        recuerdo == idv ~ 0.746,
        recuerdo == "ABNL" ~ 0.034,
        recuerdo == "<18" ~ 0.165,
        TRUE ~ 0.03
      )
    ) %>%
    dplyr::group_by(recuerdo) %>%
    dplyr::mutate(pct_original = pct_original / sum(pct_original)) %>%
    dplyr::ungroup() %>%
    # Add n column with sample sizes
    dplyr::mutate(
      n = dplyr::case_when(
        recuerdo == "PSOE" ~ round(pct_original * 1000),
        recuerdo == "PP" ~ round(pct_original * 800),
        recuerdo == "Vox" ~ round(pct_original * 600),
        recuerdo == "Sumar" ~ round(pct_original * 400),
        recuerdo == "OTBL" ~ round(pct_original * 300),
        recuerdo == "ABNL" ~ round(pct_original * 200),
        recuerdo == "<18" ~ round(pct_original * 150),
        TRUE ~ 10
      )
    )

  # Provincial patterns
  patrones <- data.frame(
    codigo_provincia = rep(c("28", "08", "46"), each = length(idv_lvls)),
    idv = rep(idv_lvls, 3),
    patron = c(
      # Madrid (28)
      0.25, 0.30, 0.15, 0.12, 0.08, 0.10,
      # Barcelona (08)
      0.30, 0.20, 0.12, 0.15, 0.13, 0.10,
      # Valencia (46)
      0.28, 0.22, 0.14, 0.14, 0.12, 0.10
    )
  )

  # Previous elections
  anteriores_elecciones <- data.frame(
    recuerdo = c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL"),
    votos_ant = c(1500000, 1200000, 800000, 600000, 400000, 500000)
  )

  # Seats by province
  n_diputados <- data.frame(
    codigo_provincia = c("28", "08", "46"),
    n_diputados = c(37, 32, 15)
  )

  # Optional adjustments
  retoques <- data.frame(
    idv = c("PSOE", "PP"),
    votos_adicionales = c(10000, -5000)
  )

  small_parties <- data.frame(
    idv = c("ERC", "Compromis"),
    votos = c(50000, 30000)
  )

  list(
    recuerdo_lvls = recuerdo_lvls,
    idv_lvls = idv_lvls,
    mt_simplificada = mt_simplificada,
    patrones = patrones,
    anteriores_elecciones = anteriores_elecciones,
    n_diputados = n_diputados,
    retoques = retoques,
    small_parties = small_parties
  )
}

# test_that("complete pipeline runs without errors", {
#   test_data <- create_complete_test_data()
#
#   # Test data validation (expect success message)
#   expect_message(
#     validate_input_data(
#       data_list = test_data[c("mt_simplificada", "patrones", "anteriores_elecciones", "n_diputados", "retoques")],
#       recuerdo_lvls = test_data$recuerdo_lvls,
#       idv_lvls = test_data$idv_lvls
#     ),
#     "Validación de datos completada exitosamente"
#   )
#
#   # Test matrix simulation
#   mt_sims <- simulate_mt(test_data$mt_simplificada, nsims = 3)
#   expect_true(is.data.frame(mt_sims))
#   expect_true(max(mt_sims$sim) == 3)
#
#   # Test vota algorithm on simulated matrices
#   for (sim_id in unique(mt_sims$sim)) {
#     mt_sim <- mt_sims %>% dplyr::filter(sim == sim_id)
#
#     result <- vota(
#       mt_simplificada = mt_sim,
#       tiempo_entre_elecciones = 4,
#       small_parties = test_data$small_parties,
#       votos_ant = test_data$anteriores_elecciones
#     )
#
#     expect_true(is.data.frame(result))
#     expect_true("idv" %in% colnames(result))
#     expect_true("votos" %in% colnames(result))
#     expect_true(all(result$votos >= 0))
#   }
# })

test_that("pipeline produces consistent results across simulations", {
  test_data <- create_complete_test_data()

  # Run multiple times and check consistency
  results <- list()
  for (i in 1:3) {
    mt_sims <- simulate_mt(test_data$mt_simplificada, nsims = 2)
    mt_sim <- mt_sims %>% dplyr::filter(sim == 1) # Use same simulation

    result <- vota(
      mt_simplificada = mt_sim,
      tiempo_entre_elecciones = 4,
      small_parties = test_data$small_parties,
      votos_ant = test_data$anteriores_elecciones
    )

    results[[i]] <- result
  }

  # All results should have same structure
  expect_true(all(sapply(results, function(x) "idv" %in% colnames(x$estimacion))))
  expect_true(all(sapply(results, function(x) "votos" %in% colnames(x$estimacion))))

  # Should include small parties
  expect_true(all(sapply(results, function(x) "ERC" %in% x$estimacion$idv)))
  expect_true(all(sapply(results, function(x) "Compromis" %in% x$estimacion$idv)))
})

test_that("D'Hondt integration with pipeline data", {
  test_data <- create_complete_test_data()

  # Simulate national results
  mt_sims <- simulate_mt(test_data$mt_simplificada, nsims = 2)

  national_results <- map_df(unique(mt_sims$sim), function(sim_id) {
    mt_sim <- mt_sims %>% dplyr::filter(sim == sim_id)

    result <- vota(
      mt_simplificada = mt_sim,
      tiempo_entre_elecciones = 4,
      small_parties = test_data$small_parties,
      votos_ant = test_data$anteriores_elecciones
    )

    result$estimacion$sim <- sim_id
    return(result$estimacion)
  })

  # Project to provinces (simplified)
  provincial_data <- national_results %>%
    dplyr::left_join(test_data$patrones, by = "idv", relationship = "many-to-many") %>%
    dplyr::mutate(votos_prov = votos * patron) %>%
    dplyr::left_join(test_data$n_diputados, by = "codigo_provincia") %>%
    dplyr::select(sim, codigo_provincia, partido = idv, votos_prov, n_diputados) %>%
    dplyr::filter(!is.na(votos_prov), !is.na(n_diputados))

  # Apply D'Hondt
  if (nrow(provincial_data) > 0) {
    seats_result <- fast_dhondt(
      data = provincial_data,
      cod_prov = codigo_provincia,
      sim = sim,
      partido = partido,
      votos_prov = votos_prov,
      nseats = n_diputados
    )

    expect_true(is.data.frame(seats_result))

    # Check total seats by province
    total_seats <- seats_result %>%
      dplyr::group_by(sim, codigo_provincia) %>%
      dplyr::summarise(total = dplyr::n(), .groups = "drop") %>%
      dplyr::left_join(test_data$n_diputados, by = "codigo_provincia")

    expect_true(all(total_seats$total == total_seats$n_diputados))
  }
})

test_that("pipeline handles edge cases gracefully", {
  test_data <- create_complete_test_data()

  # Test with minimal but valid transfer matrix (include required values)
  minimal_mt <- data.frame(
    sim = "0",
    recuerdo = c("PSOE", "PP", "OTBL", "ABNL", "<18"),
    idv = c("PSOE", "PP", "OTBL", "ABNL", "OTBL"),
    transfer = c(1.0, 1.0, 1.0, 1.0, 1.0),
    n = c(100, 60, 60, 20, 4)
  )

  # This should work
  result <- vota(
    mt_simplificada = minimal_mt,
    tiempo_entre_elecciones = 0,
    votos_ant = data.frame(
      recuerdo = c("PSOE", "PP", "OTBL", "ABNL"),
      votos_ant = c(1000, 800, 200, 150)
    )
  )

  expect_true(is.list(result))
  expect_true(is.data.frame(result$estimacion))
})

test_that("pipeline validates data consistency throughout", {
  test_data <- create_complete_test_data()

  # Test that validation catches inconsistencies
  # Create invalid patrones with wrong IDV values
  invalid_patrones <- data.frame(
    codigo_provincia = c("28"),
    idv = c("INVALID_PARTY_CODE"),
    patron = c(1.0)
  )

  expect_error(
    validate_input_data(
      data_list = list(
        mt_simplificada = test_data$mt_simplificada,
        patrones = invalid_patrones,
        anteriores_elecciones = test_data$anteriores_elecciones,
        n_diputados = test_data$n_diputados,
        retoques = test_data$retoques
      ),
      recuerdo_lvls = test_data$recuerdo_lvls,
      idv_lvls = test_data$idv_lvls,
      uncertainty_method = "mcmc", strategy = "top_down"
    ),
    "Hay niveles de idv no previstos"
  )
})

test_that("complete workflow with project setup", {
  # Test that project setup creates functional structure
  temp_dir <- tempfile("integration_test")
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Create project
  setup_electoral_project(temp_dir)

  # Verify structure
  expect_true(dir.exists(temp_dir))
  expect_true(file.exists(file.path(temp_dir, "input", "input.xlsx")))
  expect_true(file.exists(file.path(temp_dir, "scripts", "main.R")))

  # Check that main script is valid R code
  main_script <- file.path(temp_dir, "scripts", "main.R")
  script_content <- readLines(main_script)

  # Should be parseable R code
  expect_silent(parse(text = script_content))
})

test_that("pipeline error handling and recovery", {
  test_data <- create_complete_test_data()

  # Test with problematic data that should be handled gracefully
  problematic_mt <- test_data$mt_simplificada
  problematic_mt$pct_original[1:5] <- NA # Introduce NAs

  # Should handle NAs gracefully or provide clear error
  expect_error(
    vota(
      mt_simplificada = problematic_mt,
      votos_ant = test_data$anteriores_elecciones
    )
  )
})

