# Validar Niveles de Factores

Valida que los valores observados en variables de recuerdo e IDV esten
dentro de las categorias esperadas.

## Usage

``` r
check_factor_lvls(
  recuerdo_var = NULL,
  recuerdo_lvls = NULL,
  idv_var = NULL,
  idv_lvls = NULL
)
```

## Arguments

- recuerdo_var:

  Vector con valores observados de recuerdo (opcional)

- recuerdo_lvls:

  Vector con niveles validos de recuerdo (opcional)

- idv_var:

  Vector con valores observados de IDV (opcional)

- idv_lvls:

  Vector con niveles validos de IDV (opcional)

## Value

Invisible(TRUE) si es valida, o error si hay valores no previstos
