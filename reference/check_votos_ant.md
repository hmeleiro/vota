# Validate Previous Election Data

Validates that previous election data contains all necessary party
codes.

## Usage

``` r
check_votos_ant(votos_ant, recuerdo_lvls)
```

## Arguments

- votos_ant:

  Data frame with previous electoral results

- recuerdo_lvls:

  Vector with valid 'recuerdo' codes

## Value

Invisible(TRUE) si es valida, o error si no
