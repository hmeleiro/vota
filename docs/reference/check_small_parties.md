# Validar Partidos pequenos

Valida que los codigos de partido en small_parties esten dentro de los
codigos IDV validos.

## Uso

``` r
check_small_parties(small_parties, idv_lvls)
```

## Argumentos

- small_parties:

  Data frame con partidos pequenos

- idv_lvls:

  Vector con codigos IDV validos

## Valor

Invisible(TRUE) si es valida, o error si no
