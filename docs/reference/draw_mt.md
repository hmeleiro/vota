# Generate transfer matrix simulations

Generates simulated transfer matrices using MCMC or bootstrapping

## Uso

``` r
draw_mt(
  data,
  district_col,
  uncertainty_method = c("bootstrap", "mcmc"),
  strategy = c("top_down", "bottom_up"),
  nsims,
  calib_vars = NULL,
  weights = NULL,
  seed,
  verbose = T
)
```

## Argumentos

- data:

  Data frame with transfer matrix. When using bootstrapping, sample data
  should be provided where each row represents an individual. If
  uncertainty_method = 'mcmc', an aggregated transfer matrix should be
  provided.

- district_col:

  Column name for district identifier (used in bottom-up strategy)

- uncertainty_method:

  Uncertainty method: "mcmc" or "bootstrap"

- strategy:

  Strategy for transfer matrix: "top_down" or "bottom_up"

- nsims:

  Number of simulations to generate

- calib_vars:

  Variables for calibration (vector of column names, optional)

- weights:

  Name of column with reference weights for calibration (optional)

- seed:

  Seed for reproducibility (optional)

- verbose:

  Show progress messages (default TRUE)

## Valor

Data frame with transfer matrix simulations

## Ver también

Other data-functions:
[`load_and_validate()`](https://vota.spainelectoralproject.com/reference/load_and_validate.md),
[`validate_input_data()`](https://vota.spainelectoralproject.com/reference/validate_input_data.md)
