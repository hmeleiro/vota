# Generate plots from electo_fit objects

Generate plots from electo_fit objects

## Usage

``` r
# S3 method for class 'electo_fit'
plot(
  x,
  kind = c("nacional", "seats_dist", "provincia", "dhondt_margin"),
  partido = NULL,
  ...
)
```

## Arguments

- x:

  Objeto electo_fit

- kind:

  "nacional", "seats_dist", "provincia", "dhondt_margin"

- partido:

  Party to highlight (used when kind="provincia")

- ...:

  Additional arguments (not used)
