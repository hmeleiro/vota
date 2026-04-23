# Validar Correspondencia de escanos por Provincia

Valida que las provincias en los datos de escanos correspondan con las
provincias en los patrones provinciales.

## Uso

``` r
check_nseats(n_seats, patrones, strategy = "top_down")
```

## Argumentos

- n_seats:

  Data frame con escanos por provincia

- patrones:

  Data frame con patrones provinciales

## Valor

Invisible(TRUE) si es valida, warning/error segun corresponda
