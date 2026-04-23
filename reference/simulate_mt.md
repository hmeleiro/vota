# Simulaciones Monte Carlo de Matrices de Transferencia

Genera simulaciones multinomiales de matrices de transferencia
preservando las distribuciones marginales observadas.

## Usage

``` r
simulate_mt(mt_data, nsims = 10, seed = NULL)
```

## Arguments

- mt_data:

  Data frame con matriz de transferencia

- nsims:

  Numero de simulaciones a generar (por defecto 10)

- seed:

  Semilla para reproducibilidad (opcional)

## Value

Data frame con simulaciones de matrices de transferencia

## Details

Esta funcion implementa simulacion multinomial para generar variabilidad
en las matrices de transferencia, manteniendo la estructura de
dependencia entre intencion de voto y recuerdo de voto anterior.
