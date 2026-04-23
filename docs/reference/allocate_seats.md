# Allocate Seats to Parties in Each Province Allocates seats to parties in each province using the D'Hondt method, applying electoral thresholds to determine which parties are eligible for seat allocation.

Allocate Seats to Parties in Each Province Allocates seats to parties in
each province using the D'Hondt method, applying electoral thresholds to
determine which parties are eligible for seat allocation.

## Uso

``` r
allocate_seats(
  votos_provincias_sims,
  n_seats,
  umbral = 0.03,
  tipo_umbral = "provincial"
)
```

## Argumentos

- votos_provincias_sims:

  Data frame with simulated votes by province and party

- n_seats:

  Data frame with number of seats per province

- umbral:

  Electoral threshold (default 0.03)

- tipo_umbral:

  Type of threshold: "provincial", "autonomico" or "mixto" (default
  "provincial")

## Valor

List with two data frames:

- votos_provincias_sims:

  Data frame with votes and assigned seats for each party in each
  province and simulation

- dhondt_output:

  Detailed output from D'Hondt allocation including assigned seats and
  margins for next seats

@keywords internal
