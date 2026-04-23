# Download Electoral Census Data

Downloads electoral census data from INE for specified provinces.

## Usage

``` r
get_censo(provincias)
```

## Arguments

- provincias:

  Vector with province codes to obtain census data for

## Value

Data frame with columns codigo_provincia and censo_real

## Details

This function automatically downloads the census file from INE and
extracts data for requested provinces. Requires internet connection.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get census data for Madrid, Barcelona and Valencia
censo <- get_censo(c("28", "08", "46"))
} # }
```
