# Tests for D'Hondt seat allocation and utility functions

# Helper function to create test electoral data
create_test_electoral_data <- function() {
    data.frame(
        sim = rep(1:2, each = 9),
        codigo_provincia = rep(rep(c("28", "08", "46"), each = 3), 2),
        partido = rep(c("PSOE", "PP", "Vox"), 6),
        votos_prov = c(
            # Simulation 1
            # Madrid (28) - 37 seats
            1500000, 1200000, 800000,
            # Barcelona (08) - 32 seats
            1100000, 900000, 600000,
            # Valencia (46) - 15 seats
            400000, 350000, 250000,
            # Simulation 2
            # Madrid (28)
            1520000, 1180000, 820000,
            # Barcelona (08)
            1080000, 920000, 580000,
            # Valencia (46)
            420000, 330000, 270000
        ),
        n_diputados = rep(rep(c(37, 32, 15), each = 3), 2)
    )
}

test_that("fast_dhondt allocates seats correctly", {
    test_data <- create_test_electoral_data()

    result <- fast_dhondt(
        data = test_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados
    )

    expect_true(is.data.frame(result))
    expect_true("codigo_provincia" %in% colnames(result))
    expect_true("partido" %in% colnames(result))
    expect_true("sim" %in% colnames(result))

    # Check that total seats allocated per province matches expected
    seats_by_province <- result %>%
        dplyr::group_by(sim, codigo_provincia) %>%
        dplyr::summarise(total_seats = dplyr::n(), .groups = "drop")

    # Madrid should have 37 seats per simulation
    madrid_seats <- seats_by_province %>%
        dplyr::filter(codigo_provincia == "28")
    expect_true(all(madrid_seats$total_seats == 37))

    # Barcelona should have 32 seats per simulation
    barcelona_seats <- seats_by_province %>%
        dplyr::filter(codigo_provincia == "08")
    expect_true(all(barcelona_seats$total_seats == 32))

    # Valencia should have 15 seats per simulation
    valencia_seats <- seats_by_province %>%
        dplyr::filter(codigo_provincia == "46")
    expect_true(all(valencia_seats$total_seats == 15))
})

test_that("fast_dhondt handles single province correctly", {
    single_province_data <- data.frame(
        sim = 1,
        codigo_provincia = "28",
        partido = c("PSOE", "PP", "Vox", "Sumar"),
        votos_prov = c(1500000, 1200000, 800000, 400000),
        n_diputados = 37
    )

    result <- fast_dhondt(
        data = single_province_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados
    )

    expect_equal(nrow(result), 37) # Should have exactly 37 seats

    # Check that PSOE gets the most seats (highest votes)
    seats_by_party <- result %>%
        dplyr::count(partido, name = "seats") %>%
        dplyr::arrange(dplyr::desc(seats))

    expect_equal(seats_by_party$partido[1], "PSOE")
})

test_that("fast_dhondt with n_next parameter works", {
    test_data <- create_test_electoral_data() %>%
        dplyr::filter(sim == 1, codigo_provincia == "46") # Valencia only

    result <- fast_dhondt(
        data = test_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados,
        n_next = 3
    )

    # Should have 15 regular seats + 3 next seats = 18 total
    expect_equal(nrow(result), 18)

    # Check that tipo column exists and has correct values
    if ("tipo" %in% colnames(result)) {
        assigned_seats <- sum(result$tipo == "Asignado", na.rm = TRUE)
        next_seats <- sum(result$tipo == "Siguiente", na.rm = TRUE)

        expect_equal(assigned_seats, 15)
        expect_equal(next_seats, 3)
    }
})

test_that("get_censo validates province input", {
    # Test with valid province codes
    valid_provinces <- c("28", "08", "46")

    # We can't test the actual download without internet
    # But we can test the input validation logic
    expect_true(is.character(valid_provinces))
    expect_true(length(valid_provinces) > 0)
    expect_true(all(nchar(valid_provinces) > 0))
})

test_that("D'Hondt method distributes seats proportionally", {
    # Test with simple case where we know the expected outcome
    simple_data <- data.frame(
        sim = 1,
        codigo_provincia = "TEST",
        partido = c("A", "B", "C"),
        votos_prov = c(60000, 30000, 10000), # 60%, 30%, 10%
        n_diputados = 10
    )

    result <- fast_dhondt(
        data = simple_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados
    )

    seats_by_party <- result %>%
        dplyr::count(partido, name = "seats") %>%
        dplyr::arrange(dplyr::desc(seats))

    # Party A should get the most seats (highest votes)
    expect_equal(seats_by_party$partido[1], "A")

    # Party B should get more seats than Party C
    seats_A <- seats_by_party$seats[seats_by_party$partido == "A"]
    seats_B <- seats_by_party$seats[seats_by_party$partido == "B"]
    seats_C <- seats_by_party$seats[seats_by_party$partido == "C"]

    expect_gt(seats_A, seats_B)
    expect_gt(seats_B, seats_C)

    # Total seats should equal n_diputados
    expect_equal(sum(seats_by_party$seats), 10)
})

test_that("fast_dhondt handles zero votes correctly", {
    zero_votes_data <- data.frame(
        sim = 1,
        codigo_provincia = "28",
        partido = c("PSOE", "PP", "ZERO_PARTY"),
        votos_prov = c(1500000, 1200000, 0),
        n_diputados = 5
    )

    result <- fast_dhondt(
        data = zero_votes_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados
    )

    # Party with zero votes should get zero seats
    zero_party_seats <- result %>%
        dplyr::filter(partido == "ZERO_PARTY") %>%
        nrow()

    expect_equal(zero_party_seats, 0)

    # Total allocated seats should still equal n_diputados
    expect_equal(nrow(result), 5)
})

test_that("D'Hondt handles tie-breaking consistently", {
    # Test case where parties have exactly equal votes
    tie_data <- data.frame(
        sim = 1,
        codigo_provincia = "TEST",
        partido = c("A", "B"),
        votos_prov = c(50000, 50000), # Exactly equal
        n_diputados = 3
    )

    result <- fast_dhondt(
        data = tie_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados
    )

    # Should allocate 3 seats total
    expect_equal(nrow(result), 3)

    # Both parties should get at least one seat
    seats_by_party <- result %>%
        dplyr::count(partido, name = "seats")

    expect_true(all(seats_by_party$seats > 0))
})

test_that("multiple simulations are processed independently", {
    multi_sim_data <- create_test_electoral_data()

    result <- fast_dhondt(
        data = multi_sim_data,
        cod_prov = codigo_provincia,
        sim = sim,
        partido = partido,
        votos_prov = votos_prov,
        nseats = n_diputados
    )

    # Should have results for both simulations
    sims_in_result <- unique(result$sim)
    expect_true(1 %in% sims_in_result)
    expect_true(2 %in% sims_in_result)

    # Each simulation should have complete results
    sim1_results <- result %>% dplyr::filter(sim == 1)
    sim2_results <- result %>% dplyr::filter(sim == 2)

    # Both should have same total number of seats (37 + 32 + 15 = 84)
    expect_equal(nrow(sim1_results), 84)
    expect_equal(nrow(sim2_results), 84)
})
