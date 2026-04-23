# Project Estimates to Electoral District Level Projects national vote estimates to electoral district level using historical patterns and electoral census data.

Project Estimates to Electoral District Level Projects national vote
estimates to electoral district level using historical patterns and
electoral census data.

## Uso

``` r
project_to_districts(
  estimacion_previa_sims,
  patrones,
  n_seats,
  tau = 300,
  umbral = 0.03,
  tipo_umbral = "provincial",
  seed = NULL,
  censo = NULL
)
```

## Argumentos

- estimacion_previa_sims:

  Data frame with national estimates by simulation

- patrones:

  Data frame with electoral district patterns

- n_seats:

  Data frame with number of seats per province

- tau:

  Smoothing parameter for multinomial simulation (default 300)

- seed:

  Seed for reproducibility (optional)

- censo:

  Optional data frame with census data (columns: codigo_provincia,
  censo_real). If NULL, downloaded from INE.

- idv_lvls:

  Vector with IDV codes

## Valor

Data frame with electoral district results including uncertainty
simulations

## Detalles

This process:

1.  Applies district historical patterns to national estimates

2.  Adjusts by real electoral census of each district

3.  Generates additional simulations with multinomial uncertainty

4.  Prepares data for D'Hondt allocation
