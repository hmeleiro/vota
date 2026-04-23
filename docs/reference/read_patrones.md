# Read Provincial Patterns

Reads district patterns from the 'patrones' sheet of the Excel file.

## Uso

``` r
read_patrones(path)
```

## Argumentos

- path:

  Path to Excel file

## Valor

Data frame with district patterns containing columns: codigo_provincia,
idv, patron (proportion 0-1)

## Detalles

The 'patrones' sheet must contain:

- Column 'codigo_provincia' with electoral district codes

- Columns with 'idv' names (percentages 0-100)

- Patterns are automatically converted to proportions (0-1)
