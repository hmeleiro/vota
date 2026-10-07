test_that("deterministic provincial projection uses unperturbed historical patterns", {
  patrones <- data.frame(
    codigo_provincia = rep(c("01", "02", "03"), each = 2),
    idv = rep(c("A", "B"), 3),
    patron = c(2, 0, 1, 3, 1, 1)
  )
  estimacion <- data.frame(
    idv = c("A", "B"),
    votos = c(400, 200)
  )

  set.seed(123)
  rng_state <- .Random.seed
  result <- simulate_prov_votes(
    patrones = patrones,
    estimacion = estimacion,
    method = "deterministic",
    tau = 1,
    seed = 999
  )

  expected <- matrix(
    c(200, 100, 100, 0, 150, 50),
    nrow = 3,
    dimnames = list(c("01", "02", "03"), c("A", "B"))
  )

  expect_equal(result, expected)
  expect_identical(.Random.seed, rng_state)
  expect_equal(result["01", "B"], 0)
})

test_that("deterministic provincial projection validates historical patterns", {
  estimacion <- data.frame(idv = "A", votos = 100)

  expect_error(
    simulate_prov_votes(
      patrones = data.frame(
        codigo_provincia = c("01", "02"),
        idv = "A",
        patron = c(0, 0)
      ),
      estimacion = estimacion,
      method = "deterministic"
    ),
    "No hay un patron provincial positivo"
  )

  expect_error(
    simulate_prov_votes(
      patrones = data.frame(
        codigo_provincia = c("01", "02"),
        idv = "A",
        patron = c(1, -1)
      ),
      estimacion = estimacion,
      method = "deterministic"
    ),
    "valores negativos"
  )
})

test_that("simulation zero is deterministic throughout top-down projection", {
  estimacion <- data.frame(
    sim = rep(0:1, each = 2),
    idv = rep(c("A", "B"), 2),
    votos = rep(c(400, 200), 2)
  )
  patrones <- data.frame(
    codigo_provincia = rep(c("01", "02", "03"), each = 2),
    idv = rep(c("A", "B"), 3),
    patron = c(2, 0, 1, 3, 1, 1)
  )
  n_seats <- data.frame(
    codigo_provincia = c("01", "02", "03"),
    n_diputados = c(2, 3, 4)
  )
  censo <- data.frame(
    codigo_provincia = c("01", "02", "03"),
    censo_real = c(1000, 2000, 3000)
  )

  result_seed_1 <- project_to_districts(
    estimacion_previa_sims = estimacion,
    patrones = patrones,
    n_seats = n_seats,
    seed = 1,
    censo = censo
  )
  result_seed_2 <- project_to_districts(
    estimacion_previa_sims = estimacion,
    patrones = patrones,
    n_seats = n_seats,
    seed = 999,
    censo = censo
  )

  baseline_1 <- result_seed_1$votos_provincias_sims %>%
    dplyr::filter(sim == 0) %>%
    dplyr::arrange(codigo_provincia, partido)
  baseline_2 <- result_seed_2$votos_provincias_sims %>%
    dplyr::filter(sim == 0) %>%
    dplyr::arrange(codigo_provincia, partido)

  expect_equal(baseline_1, baseline_2)
  expect_equal(
    baseline_1 %>%
      dplyr::select(codigo_provincia, partido, votos_salida),
    tibble::tibble(
      codigo_provincia = c("01", "02", "02", "03", "03"),
      partido = c("A", "A", "B", "A", "B"),
      votos_salida = c(1000L, 800L, 1200L, 2000L, 1000L)
    )
  )

  sim_1_alone <- project_to_districts(
    estimacion_previa_sims = dplyr::filter(estimacion, sim == 1),
    patrones = patrones,
    n_seats = n_seats,
    seed = 1,
    censo = censo
  )

  expect_equal(
    result_seed_1$votos_provincias_sims %>%
      dplyr::filter(sim == 1) %>%
      dplyr::arrange(codigo_provincia, partido),
    sim_1_alone$votos_provincias_sims %>%
      dplyr::arrange(codigo_provincia, partido)
  )
})
