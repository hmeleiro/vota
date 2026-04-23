# Read Manual Adjustments

Reads manual adjustments from the 'retoques' sheet of the Excel file.

## Uso

``` r
read_retoques(path, strategy = c("top_down", "bottom_up"))
```

## Argumentos

- path:

  Path to Excel file

## Valor

Data frame with valid adjustments containing columns: idv,
votos_adicionales

## Detalles

The 'retoques' sheet must contain:

- Column 'idv' with party names

- Column 'votos_adicionales' with adjustments (positive or negative)

- Column 'codigo_provincia' if strategy is "bottom_up"

- Only rows with votos_adicionales != 0 and != NA are included
