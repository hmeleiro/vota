# Tests for data validation functions

# Test data setup
create_test_data <- function() {
    recuerdo_lvls <- c("PSOE", "PP", "Vox", "OTBL", "ABNL", "<18")
    idv_lvls <- c("PSOE", "PP", "Vox", "OTBL", "ABNL")

    # Valid matrix of transfer
    mt_valid <- data.frame(
        recuerdo = c("PSOE", "PP", "Vox", "PSOE", "PP", "Vox", "Vox", "OTBL", "ABNL", "<18"),
        idv = c("PSOE", "PSOE", "PSOE", "PP", "PP", "PP", "Vox", "OTBL", "ABNL", "OTBL"),
        n = c(100, 5, 2, 10, 150, 20, 10, 30, 40, 30)
    )

    # Valid patterns
    patrones_valid <- data.frame(
        codigo_provincia = c("28", "08"),
        PSOE = c(25, 30),
        PP = c(30, 20),
        Vox = c(15, 12),
        OTBL = c(20, 25),
        ABNL = c(10, 13)
    ) %>%
        tidyr::pivot_longer(cols = -codigo_provincia, names_to = "idv", values_to = "patron") %>%
        dplyr::mutate(patron = patron / 100)

    # Valid previous elections
    votos_ant_valid <- data.frame(
        recuerdo = c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL"),
        votos_ant = c(1000000, 800000, 600000, 400000, 200000, 300000)
    )

    # Valid seats by province
    n_diputados_valid <- data.frame(
        codigo_provincia = c("28", "08"),
        n_diputados = c(37, 32)
    )

    # Valid retoques
    retoques_valid <- data.frame(
        idv = c("PSOE", "PP"),
        votos_adicionales = c(10000, -5000)
    )

    list(
        recuerdo_lvls = recuerdo_lvls,
        idv_lvls = idv_lvls,
        mt_simplificada = mt_valid,
        patrones = patrones_valid,
        anteriores_elecciones = votos_ant_valid,
        n_diputados = n_diputados_valid,
        retoques = retoques_valid
    )
}

test_that("validate_input_data works with valid data", {
    test_data <- create_test_data()

    result <- validate_input_data(
        data_list = test_data[c("mt_simplificada", "patrones", "anteriores_elecciones", "n_diputados", "retoques")],
        recuerdo_lvls = test_data$recuerdo_lvls,
        idv_lvls = test_data$idv_lvls,
        uncertainty_method = "mcmc", strategy = "top_down"
    )

    expect_true(result)
})

test_that("validate_input_data fails with missing elements", {
    test_data <- create_test_data()

    # Remove required element
    incomplete_data <- test_data[c("mt_simplificada", "patrones")]

    expect_error(
        validate_input_data(
            data_list = incomplete_data,
            recuerdo_lvls = test_data$recuerdo_lvls,
            idv_lvls = test_data$idv_lvls,
            uncertainty_method = "mcmc", strategy = "top_down"
        ),
        "Missing elements in input data"
    )
})

test_that("check_mt validates matrix of transfer correctly", {
    test_data <- create_test_data()

    # Valid case should not throw error
    expect_silent(
        check_mt(
            mt = test_data$mt_simplificada,
            recuerdo_lvls = test_data$recuerdo_lvls,
            idv_lvls = test_data$idv_lvls
        )
    )
})

test_that("check_patrones validates patterns correctly", {
    test_data <- create_test_data()

    expect_silent(
        check_patrones(
            patrones = test_data$patrones,
            idv_lvls = test_data$idv_lvls
        )
    )
})

test_that("check_votos_ant validates previous elections correctly", {
    test_data <- create_test_data()

    expect_silent(
        check_votos_ant(
            votos_ant = test_data$anteriores_elecciones,
            recuerdo_lvls = setdiff(test_data$recuerdo_lvls, "<18")
        )
    )
})

test_that("check_votos_ant fails with missing columns", {
    invalid_votos <- data.frame(
        partido = c("PSOE", "PP"),
        votos = c(1000, 800)
    )

    expect_error(
        check_votos_ant(
            votos_ant = invalid_votos,
            recuerdo_lvls = c("PSOE", "PP")
        ),
        "votos_ant debe contener las columnas"
    )
})

test_that("check_nseats validates seats correspondence", {
    test_data <- create_test_data()

    expect_silent(
        check_nseats(
            n_seats = test_data$n_diputados,
            patrones = test_data$patrones
        )
    )
})

test_that("check_retoques validates manual adjustments", {
    test_data <- create_test_data()

    expect_silent(
        check_retoques(
            retoques = test_data$retoques,
            idv_lvls = test_data$idv_lvls
        )
    )
})

# test_that("check_retoques fails with invalid party codes", {
#     invalid_retoques <- data.frame(
#         idv = c("INVALID_PARTY"),
#         votos_adicionales = c(1000)
#     )
#
#     expect_error(
#         check_retoques(
#             retoques = invalid_retoques,
#             idv_lvls = c("PSOE", "PP", "Vox")
#         ),
#         "Hay partidos en retoques que no están en idv_lvls"
#     )
# })

test_that("check_factor_lvls validates factor levels correctly", {
    # Valid case - should not throw error
    expect_silent(
        check_factor_lvls(
            recuerdo_var = c("PSOE", "PP", "Vox", "Sumar"),
            recuerdo_lvls = c("PSOE", "PP", "Vox", "Sumar"),
            idv_var = c("PSOE", "PP", "Vox"),
            idv_lvls = c("PSOE", "PP", "Vox")
        )
    )
})

test_that("check_factor_lvls fails with unexpected levels", {
    expect_error(
        check_factor_lvls(
            idv_var = c("PSOE", "INVALID_PARTY"),
            idv_lvls = c("PSOE", "PP", "Vox")
        ),
        "Hay niveles de idv no previstos"
    )
})
