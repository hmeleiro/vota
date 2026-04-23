# Execute VOTA algorithm based on the selected strategy

This function executes the VOTA algorithm using either a top-down or
bottom-up approach, depending on the specified strategy. It captures and
validates additional arguments and calls the appropriate internal
function to perform the simulation.

## Uso

``` r
execute_vota(strategy = c("top_down", "bottom_up"), ...)
```

## Argumentos

- strategy:

  Strategy for simulation ("top_down" or "bottom_up").

- ...:

  Additional arguments to be passed to the internal functions.

## Valor

A list containing the results of the VOTA algorithm execution.
