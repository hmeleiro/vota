# Validate Vote Transfer Matrix

Validates that party codes in the transfer matrix correspond to expected
categories.

## Uso

``` r
check_mt(mt, recuerdo_lvls, idv_lvls)
```

## Argumentos

- mt:

  Data frame with transfer matrix

- recuerdo_lvls:

  Vector with valid recuerdo codes

- idv_lvls:

  Vector with valid IDV codes

## Valor

Invisible(TRUE) if valid, or error if not
