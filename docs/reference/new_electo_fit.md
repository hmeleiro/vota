# Crea un objeto electo_fit

Crea un objeto electo_fit

## Uso

``` r
new_electo_fit(results)
```

## Argumentos

- results:

  Lista con los resultados del ajuste, que debe incluir los siguientes
  elementos:

  estimacion

  :   Data frame con las estimaciones finales, debe incluir columnas
      'partido', 'pct_m', 'seats_m'

  estimacion_sims

  :   (Opcional) Data frame con las simulaciones detalladas por partido
      y provincia

  estimacion_provincias_sims

  :   (Opcional) Data frame con las simulaciones detalladas por partido
      y provincia

  mt_sims_pct

  :   (Opcional) Matriz de transferencias simuladas en porcentaje de
      voto sobre recuerdo

  mt_sims_electores

  :   (Opcional) Matriz de transferencias simuladas en número de
      electores

  dhondt_output

  :   (Opcional) Resultado del método D'Hondt aplicado a las
      simulaciones

  participacion_media

  :   (Opcional) Valor numérico con la participación media estimada

  metadata

  :   Lista con metadatos del ajuste, como 'nsims', 'tau', 'umbral',
      etc.

## Valor

Objeto de clase electo_fit
