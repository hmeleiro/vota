# Download Electoral Census Data

Downloads electoral census data from INE for specified provinces.

## Uso

``` r
get_censo(provincias)
```

## Argumentos

- provincias:

  Vector with province codes to obtain census data for

## Valor

Data frame with columns codigo_provincia and censo_real

## Detalles

This function automatically downloads the census file from INE and
extracts data for requested provinces. Requires internet connection.

## Ejemplos

``` r
if (FALSE) { # \dontrun{
# Get census data for Madrid, Barcelona and Valencia
censo <- get_censo(c("28", "08", "46"))
} # }
```
