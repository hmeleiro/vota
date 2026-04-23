# Validate Previous Election Data

Validates that previous election data contains all necessary party
codes.

## Uso

``` r
check_votos_ant(votos_ant, recuerdo_lvls)
```

## Argumentos

- votos_ant:

  Data frame with previous electoral results

- recuerdo_lvls:

  Vector with valid 'recuerdo' codes

## Valor

Invisible(TRUE) si es valida, o error si no
