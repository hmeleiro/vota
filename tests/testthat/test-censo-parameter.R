# Tests for the censo parameter across the pipeline

# --- Helper: create minimal data for allocate_seats ---
create_allocate_seats_data <- function() {
    # votos_provincias_sims: columns sim, codigo_provincia, idv, votos

    votos <- data.frame(
        sim = rep(1, 8),
        codigo_provincia = rep(c("28", "08"), each = 4),
        idv = rep(c("PSOE", "PP", "Vox", "ABNL"), 2),
        votos = c(
            0.40, 0.30, 0.20, 0.10,
            0.35, 0.25, 0.25, 0.15
        )
    )

    n_seats <- data.frame(
        codigo_provincia = c("28", "08"),
        n_diputados = c(37, 32)
    )

    censo <- data.frame(
        codigo_provincia = c("28", "08"),
        censo_real = c(4500000, 4000000)
    )

    list(votos = votos, n_seats = n_seats, censo = censo)
}


# -------------------------------------------------------
# 1. validate_params: censo validation
# -------------------------------------------------------

test_that("validate_params accepts NULL censo (default)", {
    tmp <- tempfile(fileext = ".xlsx")
    file.create(tmp)
    on.exit(unlink(tmp))

    params <- validate_params(
        input_path = tmp,
        uncertainty_method = "mcmc",
        strategy = "top_down",
        censo = NULL,
        verbose = FALSE
    )
    expect_null(params$data$censo)
})

test_that("validate_params accepts valid censo data frame", {
    tmp <- tempfile(fileext = ".xlsx")
    file.create(tmp)
    on.exit(unlink(tmp))

    censo <- data.frame(
        codigo_provincia = c("28", "08"),
        censo_real = c(4500000, 4000000)
    )

    params <- validate_params(
        input_path = tmp,
        uncertainty_method = "mcmc",
        strategy = "top_down",
        censo = censo,
        verbose = FALSE
    )
    expect_equal(params$data$censo, censo)
})

test_that("validate_params rejects non-data.frame censo", {
    tmp <- tempfile(fileext = ".xlsx")
    file.create(tmp)
    on.exit(unlink(tmp))

    expect_error(
        validate_params(
            input_path = tmp,
            uncertainty_method = "mcmc",
            strategy = "top_down",
            censo = list(codigo_provincia = "28", censo_real = 100),
            verbose = FALSE
        ),
        "censo must be a data.frame"
    )
})

test_that("validate_params rejects censo with missing columns", {
    tmp <- tempfile(fileext = ".xlsx")
    file.create(tmp)
    on.exit(unlink(tmp))

    bad_censo <- data.frame(
        provincia = c("28", "08"),
        censo_real = c(4500000, 4000000)
    )

    expect_error(
        validate_params(
            input_path = tmp,
            uncertainty_method = "mcmc",
            strategy = "top_down",
            censo = bad_censo,
            verbose = FALSE
        ),
        "censo must have columns"
    )
})


# -------------------------------------------------------
# 2. project_to_districts: censo parameter acceptance
# -------------------------------------------------------

test_that("project_to_districts uses provided censo", {
    # estimacion_previa_sims needs columns: sim, idv, votos
    estimacion <- data.frame(
        sim = rep(1, 4),
        idv = c("PSOE", "PP", "Vox", "ABNL"),
        votos = c(4000000, 3000000, 2000000, 1000000)
    )

    patrones <- data.frame(
        codigo_provincia = rep(c("28", "08"), each = 4),
        idv = rep(c("PSOE", "PP", "Vox", "ABNL"), 2),
        patron = c(
            0.38, 0.32, 0.20, 0.10,
            0.35, 0.25, 0.25, 0.15
        )
    )

    n_seats <- data.frame(
        codigo_provincia = c("28", "08"),
        n_diputados = c(37, 32)
    )

    censo <- data.frame(
        codigo_provincia = c("28", "08"),
        censo_real = c(4500000, 4000000)
    )

    # Should work without internet
    result <- project_to_districts(
        estimacion_previa_sims = estimacion,
        patrones = patrones,
        n_seats = n_seats,
        tau = 300,
        umbral = 0.03,
        tipo_umbral = "provincial",
        seed = 42,
        censo = censo
    )

    expect_type(result, "list")
    expect_true("votos_provincias_sims" %in% names(result))
    expect_true("dhondt_output" %in% names(result))
})


# -------------------------------------------------------
# 3. prepare_pipeline_args: censo is threaded through
# -------------------------------------------------------

test_that("prepare_pipeline_args includes censo in output", {
    tmp <- tempfile(fileext = ".xlsx")
    file.create(tmp)
    on.exit(unlink(tmp))

    censo <- data.frame(
        codigo_provincia = c("28"),
        censo_real = c(4500000)
    )

    params <- validate_params(
        input_path = tmp,
        uncertainty_method = "mcmc",
        strategy = "top_down",
        censo = censo,
        verbose = FALSE
    )

    pipeline_args <- prepare_pipeline_args(params)
    expect_true("censo" %in% names(pipeline_args))
    expect_equal(pipeline_args$censo, censo)
})

test_that("prepare_pipeline_args passes NULL censo when not provided", {
    tmp <- tempfile(fileext = ".xlsx")
    file.create(tmp)
    on.exit(unlink(tmp))

    params <- validate_params(
        input_path = tmp,
        uncertainty_method = "mcmc",
        strategy = "top_down",
        censo = NULL,
        verbose = FALSE
    )

    pipeline_args <- prepare_pipeline_args(params)
    expect_true("censo" %in% names(pipeline_args))
    expect_null(pipeline_args$censo)
})

