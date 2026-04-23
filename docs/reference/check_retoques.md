# Validar Retoques (Ajustes Manuales)

Valida que los codigos de partido en retoques esten dentro de los
codigos IDV validos.

## Uso

``` r
check_retoques(retoques, idv_lvls)
```

## Argumentos

- retoques:

  Data frame con ajustes manuales

- idv_lvls:

  Vector con codigos IDV validos

## Valor

Invisible(TRUE) si es valida, o error si no
