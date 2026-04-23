# Read Small Parties

Reads small parties data from the 'small_parties' sheet of the Excel
file.

## Uso

``` r
read_small_parties(path, strategy = c("top_down", "bottom_up"))
```

## Argumentos

- path:

  Path to Excel file

- strategy:

  Modeling strategy: "top_down" or "bottom_up"

## Valor

Data frame with valid small parties containing columns: idv, votos (and
codigo_provincia if strategy is "bottom_up")

## Detalles

The 'small_parties' sheet must contain:

- Column 'idv' with party codes

- Column 'votos' with vote estimates

- Column 'codigo_provincia' if strategy is "bottom_up"

- Only rows with votos != 0 and != NA are included
