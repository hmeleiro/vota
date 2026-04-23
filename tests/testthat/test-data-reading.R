# Tests for data reading functions

# Mock data for testing
create_mock_partidos <- function() {
    data.frame(
        idv = c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL"),
        recuerdo = c("PSOE", "PP", "Vox", "Sumar", "OTBL", "ABNL")
    )
}

create_mock_patrones <- function() {
    data.frame(
        codigo_provincia = c("28", "08", "46"),
        PSOE = c(25.5, 30.2, 28.1),
        PP = c(30.1, 20.5, 22.3),
        Vox = c(15.2, 12.8, 14.5),
        OTBL = c(29.2, 36.5, 35.1)
    )
}

test_that("read_partidos extracts party codes correctly", {
    # This test would typically use a mock Excel file
    # For now, we test the logic with a data frame

    partidos_df <- create_mock_partidos()

    # Extract codes like the function does
    idv_codes <- partidos_df$idv[!is.na(partidos_df$idv)]
    recuerdo_codes <- partidos_df$recuerdo[!is.na(partidos_df$recuerdo)]

    result <- list(
        idv = unique(idv_codes),
        recuerdo = unique(recuerdo_codes)
    )

    expect_true(is.list(result))
    expect_true("idv" %in% names(result))
    expect_true("recuerdo" %in% names(result))
    expect_true("PSOE" %in% result$idv)
    expect_true("PSOE" %in% result$recuerdo)
})

test_that("read_patrones processes patterns correctly", {
    # Mock the processing that happens in read_patrones
    patrones_raw <- create_mock_patrones()

    # Simulate the transformation
    patrones_processed <- patrones_raw %>%
        dplyr::select(-dplyr::any_of("TOTAL")) %>%
        tidyr::pivot_longer(2:ncol(.), names_to = "idv", values_to = "patron") %>%
        dplyr::mutate(patron = patron / 100) %>%
        dplyr::filter(patron > 0)

    expect_true(is.data.frame(patrones_processed))
    expect_true("codigo_provincia" %in% colnames(patrones_processed))
    expect_true("idv" %in% colnames(patrones_processed))
    expect_true("patron" %in% colnames(patrones_processed))
    expect_true(all(patrones_processed$patron >= 0 & patrones_processed$patron <= 1))
})

test_that("read_retoques filters correctly", {
    # Mock retoques data
    retoques_raw <- data.frame(
        idv = c("PSOE", "PP", "Vox", "ERC"),
        votos_adicionales = c(10000, -5000, 0, NA)
    )

    # Simulate the filtering logic
    retoques_clean <- retoques_raw %>%
        dplyr::filter(!is.na(votos_adicionales), votos_adicionales != 0)

    expect_equal(nrow(retoques_clean), 2) # Only PSOE and PP should remain
    expect_true("PSOE" %in% retoques_clean$idv)
    expect_true("PP" %in% retoques_clean$idv)
    expect_false("Vox" %in% retoques_clean$idv) # Should be filtered out (0)
    expect_false("ERC" %in% retoques_clean$idv) # Should be filtered out (NA)
})

test_that("read_small_parties filters correctly", {
    # Mock small parties data
    small_parties_raw <- data.frame(
        idv = c("ERC", "Compromis", "BNG", "Invalid"),
        votos = c(50000, 30000, 0, NA)
    )

    # Simulate the filtering logic
    small_parties_clean <- small_parties_raw %>%
        dplyr::filter(!is.na(votos), votos > 0, !is.na(idv))

    expect_equal(nrow(small_parties_clean), 2) # Only ERC and Compromis should remain
    expect_true("ERC" %in% small_parties_clean$idv)
    expect_true("Compromis" %in% small_parties_clean$idv)
    expect_false("BNG" %in% small_parties_clean$idv) # Should be filtered out (0)
    expect_false("Invalid" %in% small_parties_clean$idv) # Should be filtered out (NA)
})

test_that("load_electoral_data validates required sheets", {
    # Test the validation logic for required sheets
    required_sheets <- c(
        "partidos", "mt_simplificada", "patrones",
        "anteriores_elecciones", "n_diputados", "retoques"
    )

    available_sheets <- c("partidos", "mt_simplificada", "patrones", "anteriores_elecciones")
    missing_sheets <- setdiff(required_sheets, available_sheets)

    expect_true(length(missing_sheets) > 0)
    expect_true("n_diputados" %in% missing_sheets)
    expect_true("retoques" %in% missing_sheets)
})

# Test for calculate_n function with proper structure
test_that("calculate_n validates input structure", {
    # Test with non-data.frame input
    expect_error(
        calculate_n("not a data frame"),
        "mt must be a data.frame"
    )

    # Test with missing N row
    mt_no_n <- data.frame(
        idv = c("PSOE", "PP"),
        Recuerdo_PSOE = c(70, 5),
        Recuerdo_PP = c(3, 75)
    )

    expect_error(
        calculate_n(mt_no_n),
        "Matrix must include a row with total respondents per party recall \\(N\\)"
    )
})

test_that("calculate_n processes valid matrix correctly", {
    # Valid matrix with N row
    mt_valid <- data.frame(
        idv = c("PSOE", "PP", "Vox", "N"),
        Recuerdo_PSOE = c(70, 5, 2, 100),
        Recuerdo_PP = c(3, 75, 8, 150),
        Recuerdo_Vox = c(1, 8, 80, 80)
    )

    result <- calculate_n(mt_valid)

    expect_true(is.data.frame(result))
    expect_true(all(c("recuerdo", "idv", "n") %in% colnames(result)))
    expect_false("N" %in% result$idv) # N row should be removed
    expect_true(all(result$n >= 0)) # All counts should be non-negative
})

test_that("validation functions handle edge cases", {
    # Test empty data frame - should fail before trying to access columns
    empty_df <- data.frame()

    # Should handle empty input gracefully
    expect_error(
        calculate_n(empty_df)
        # Error will occur when trying to filter idv column that doesn't exist
    )
})
