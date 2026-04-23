# Apply Corrections to Vote Transfer Matrix

Auxiliary function that applies corrections for abstention, new voters
and other blank/null votes to the transfer matrix.

## Uso

``` r
mt_correction(
  mt_simplificada,
  factor_correccion_otbl,
  factor_correccion_abstencion,
  factor_correccion_jovenes
)
```

## Argumentos

- mt_simplificada:

  Data frame with vote transfer matrix

- factor_correccion_otbl:

  Correction factor for other blank/null votes

- factor_correccion_abstencion:

  Correction factor for abstention

- factor_correccion_jovenes:

  Correction factor for new voters

## Valor

Data frame with corrected transfer matrix
