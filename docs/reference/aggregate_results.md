# Agregar Resultados Nacionales desede Simulaciones Provinciales

Agrega los resultados de votos y escaños a nivel nacional

## Uso

``` r
aggregate_results(votos_provincias_sims, interval_level = 0.9)
```

## Argumentos

- votos_provincias_sims:

  Data frame con resultados provinciales por simulacion

- interval_level:

  Nivel de confianza para los intervalos (default 0.9)

## Valor

Data frame con resultados nacionales agregados
