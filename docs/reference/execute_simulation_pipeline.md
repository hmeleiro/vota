# Execute the full simulation pipeline

This function orchestrates the complete electoral simulation process,
from drawing simulated vote shares to allocating seats and aggregating
results.

## Uso

``` r
execute_simulation_pipeline(
  data,
  retoques,
  small_parties,
  votos_ant,
  patrones,
  n_seats,
  uncertainty_method,
  strategy,
  nsims,
  factor_correccion_abstencion,
  factor_correccion_jovenes,
  factor_correccion_otbl,
  tiempo_entre_elecciones,
  district_col,
  tau,
  umbral,
  tipo_umbral,
  interval_level,
  censo = NULL,
  verbose,
  seed,
  ...
)
```

## Argumentos

- data:

  Data frame with polling data.

- retoques:

  Data frame with adjustments to be applied.

- small_parties:

  Data frame with small party votes.

- votos_ant:

  Data frame with previous electoral results (column votos_ant).

- patrones:

  Data frame with district-level voting patterns.

- n_seats:

  Data frame with number of seats per district.

- uncertainty_method:

  Method for introducing uncertainty in simulations (e.g., "mcmc",
  "bootstrap").

- strategy:

  Strategy for simulation ("top_down" or "bottom_up").

- nsims:

  Number of simulations to run.

- factor_correccion_abstencion:

  Correction factor for abstention.

- factor_correccion_jovenes:

  Correction factor for new voters.

- factor_correccion_otbl:

  Correction factor for other blank/null votes.

- tiempo_entre_elecciones:

  Years between elections for demographic adjustments.

- district_col:

  Name of column in survey_data indicating province or electoral
  district

- tau:

  Parameter to control variability level of provincial party projection
  patterns (only needed if strategy is "top_down")

- umbral:

  Minimum vote threshold for seat assignment (default 0.03)

- tipo_umbral:

  Threshold type: "provincial", "autonomico" or "mixto" (default
  "provincial")

- interval_level:

  Confidence level for uncertainty intervals (default 0.9)

- censo:

  Optional data frame with census data per province (columns:
  codigo_provincia, censo_real). If NULL (default), downloaded from INE.

- verbose:

  Show progress messages (default TRUE)

- seed:

  Seed for reproducibility (default NULL)

- ...:

  Additional arguments for bootstrap internal function. The current
  accepted parameters are calib_vars and weights. Only used when
  uncertainty_method is "bootstrap"

## Valor

A list with simulation results and metadata.
