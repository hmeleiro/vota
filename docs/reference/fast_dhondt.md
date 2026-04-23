# Vectorized D'Hondt Allocation

Optimized implementation of the D'Hondt method for seat allocation
across multiple provinces and simulations simultaneously.

## Uso

``` r
fast_dhondt(
  data,
  cod_prov = codigo_provincia,
  sim = sim,
  partido = partido,
  votos_prov,
  nseats = n_diputados,
  n_next = 0
)
```

## Argumentos

- data:

  Data frame with electoral data

- cod_prov:

  Column identifying the electoral district (default codigo_provincia)

- sim:

  Column identifying the simulation (default sim)

- partido:

  Column identifying the party (default partido)

- votos_prov:

  Column with votes in the electoral district

- nseats:

  Column with number of seats per electoral district (default
  n_diputados)

- n_next:

  Number of additional seats to calculate. This is useful for analyzing
  the battle for the last seat (default 0)

## Valor

Data frame with assigned seats. One row per assigned seat.

## Detalles

This vectorized implementation efficiently processes thousands of
simulations, applying the standard D'Hondt method used in Spain.
Includes calculation of next seats for sensitivity analysis.

## Ver también

Other core-algorithms:
[`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
