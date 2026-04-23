# Tests for core electoral simulation functions

# Helper function to create test transfer matrix with all required values
create_test_mt <- function() {
    # Create matrix with all required recuerdo and idv values
    recuerdo_vals <- c("PSOE", "PP", "Vox", "OTBL", "ABNL", "<18")
    idv_vals <- c("PSOE", "PP", "Vox", "OTBL", "ABNL")

    data.frame(
        sim = 0, # Add sim column
        recuerdo = rep(recuerdo_vals, each = length(idv_vals)),
        idv = rep(idv_vals, length(recuerdo_vals)),
        transfer = c(
            # PSOE recuerdo
            0.60, 0.05, 0.02, 0.10, 0.23,
            # PP recuerdo
            0.03, 0.65, 0.15, 0.10, 0.07,
            # Vox recuerdo
            0.01, 0.08, 0.70, 0.10, 0.11,
            # OTBL recuerdo
            0.15, 0.15, 0.10, 0.20, 0.40,
            # ABNL recuerdo
            0.15, 0.20, 0.10, 0.15, 0.40,
            # <18 recuerdo
            0.25, 0.15, 0.20, 0.15, 0.25
        ),
        n = 50 # Add n column with sample sizes
    )
}

# Helper function to create test previous elections data
create_test_votos_ant <- function() {
    data.frame(
        recuerdo = c("PSOE", "PP", "Vox", "ABNL"),
        votos_ant = c(1000000, 800000, 600000, 300000)
    )
}

test_that("simulate_mt generates correct number of simulations", {
    # Create test data with n column and required structure
    mt_data <- data.frame(
        recuerdo = c("PSOE", "PP", "Vox"),
        idv = c("PSOE", "PP", "Vox"),
        n = c(100, 150, 80),
        pct_original = c(.50, .30, .20)
    )

    nsims <- 5
    result <- simulate_mt(mt_data, nsims = nsims)
    expect_true(is.data.frame(result))
    expect_true("sim" %in% colnames(result))
    expect_equal(max(result$sim), nsims)
    expect_equal(min(result$sim), 0) # includes original (sim 0)
})

test_that("simulate_mt fails with missing required columns", {
    invalid_mt <- data.frame(
        partido = c("PSOE", "PP"),
        votos = c(100, 150)
    )

    expect_error(
        simulate_mt(invalid_mt),
        "mt_data must contain 'idv' column"
    )
})

test_that("simulate_mt fails without n column", {
    invalid_mt <- data.frame(
        idv = c("PSOE", "PP"),
        recuerdo = c("PSOE", "PP")
    )

    expect_error(
        simulate_mt(invalid_mt),
        "Matriz de transferencia debe contener fila 'N'"
    )
})

test_that("vota algorithm processes transfer matrix correctly", {
    mt_data <- create_test_mt()
    votos_ant <- create_test_votos_ant()

    result <- vota(
        mt_simplificada = mt_data,
        tiempo_entre_elecciones = 4,
        factor_correccion_abstencion = 3,
        factor_correccion_jovenes = 2.5,
        factor_correccion_otbl = 2.5,
        small_parties = NULL,
        votos_ant = votos_ant
    )

    expect_true(is.list(result))
    expect_true(is.data.frame(result$estimacion))
    expect_true("idv" %in% colnames(result$estimacion))
    expect_true("votos" %in% colnames(result$estimacion))
    expect_true(nrow(result$estimacion) > 0) # Should have some results
})

test_that("vota fails with invalid mt_simplificada", {
    invalid_mt <- "not a data frame"
    votos_ant <- create_test_votos_ant()

    expect_error(
        vota(
            mt_simplificada = invalid_mt,
            votos_ant = votos_ant
        ),
        "mt_simplificada must be a data.frame"
    )
})

test_that("vota fails with missing required columns in mt", {
    invalid_mt <- data.frame(
        partido = c("PSOE", "PP"),
        transfer = c(0.7, 0.3)
    )
    votos_ant <- create_test_votos_ant()

    expect_error(
        vota(
            mt_simplificada = invalid_mt,
            votos_ant = votos_ant
        ),
        "mt_simplificada must have columns recuerdo, idv and transfer"
    )
})

test_that("vota fails with invalid votos_ant", {
    mt_data <- create_test_mt()
    invalid_votos <- data.frame(
        partido = c("PSOE", "PP"),
        votos = c(1000, 800)
    )

    expect_error(
        vota(
            mt_simplificada = mt_data,
            votos_ant = invalid_votos
        ),
        "votos_ant must be a data.frame with column 'votos_ant'"
    )
})

test_that("vota handles small parties correctly", {
    mt_data <- create_test_mt()
    votos_ant <- create_test_votos_ant()
    small_parties <- data.frame(
        idv = c("ERC", "Compromis"),
        votos = c(50000, 30000)
    )

    result <- vota(
        mt_simplificada = mt_data,
        votos_ant = votos_ant,
        small_parties = small_parties
    )

    expect_true("ERC" %in% result$estimacion$idv)
    expect_true("Compromis" %in% result$estimacion$idv)
    expect_true(result$estimacion$votos[result$estimacion$idv == "ERC"] == 50000)
    expect_true(result$estimacion$votos[result$estimacion$idv == "Compromis"] == 30000)
})

test_that("calculate_n processes matrix correctly", {
    # Create test matrix with N row
    mt_with_n <- data.frame(
        idv = c("PSOE", "PP", "Vox", "N"),
        PSOE = c(70, 5, 2, 100),
        PP = c(3, 75, 8, 150),
        Vox = c(1, 8, 80, 80)
    )

    result <- calculate_n(mt_with_n)

    expect_true(is.data.frame(result))
    expect_true(all(c("recuerdo", "idv", "n") %in% colnames(result)))
    expect_false("N" %in% result$idv) # N row should be removed
})

test_that("calculate_n fails without N row", {
    mt_without_n <- data.frame(
        idv = c("PSOE", "PP", "Vox"),
        PSOE = c(70, 5, 2),
        PP = c(3, 75, 8)
    )

    expect_error(
        calculate_n(mt_without_n),
        "Matrix must include a row with total respondents per party recall \\(N\\)"
    )
})

# test_that("vota validates tiempo_entre_elecciones parameter", {
#     mt_data <- create_test_mt()
#     votos_ant <- create_test_votos_ant()
#
#     expect_error(
#         vota(
#             mt_simplificada = mt_data,
#             votos_ant = votos_ant,
#             tiempo_entre_elecciones = -1
#         ),
#         "tiempo_entre_elecciones debe ser un número positivo"
#     )
# })
