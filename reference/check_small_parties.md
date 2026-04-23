# Validar Partidos pequenos

Valida que los codigos de partido en small_parties esten dentro de los
codigos IDV validos.

## Usage

``` r
check_small_parties(small_parties, idv_lvls)
```

## Arguments

- small_parties:

  Data frame con partidos pequenos

- idv_lvls:

  Vector con codigos IDV validos

## Value

Invisible(TRUE) si es valida, o error si no
