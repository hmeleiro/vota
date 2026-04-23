# Generate plots from electo_fit objects

Generate plots from electo_fit objects

## Uso

``` r
# Método S3 para la clase 'electo_fit'
plot(
  x,
  kind = c("nacional", "seats_dist", "provincia", "dhondt_margin"),
  partido = NULL,
  ...
)
```

## Argumentos

- x:

  Objeto electo_fit

- kind:

  "nacional", "seats_dist", "provincia", "dhondt_margin"

- partido:

  Party to highlight (used when kind="provincia")

- ...:

  Additional arguments (not used)
