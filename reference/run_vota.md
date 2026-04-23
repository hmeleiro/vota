# Run Complete Electoral Simulation

This function executes the complete VOTA system pipeline for Spanish
electoral simulation, starting from national-level data.

## Usage

``` r
run_vota(
  survey_data = NULL,
  input_path,
  output_file,
  uncertainty_method = c("mcmc", "bootstrap"),
  strategy = "top_down",
  nsims = 100,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 3,
  tiempo_entre_elecciones = 0.1,
  district_col,
  tau = 300,
  umbral = 0.03,
  tipo_umbral = "provincial",
  interval_level = 0.9,
  censo = NULL,
  verbose = TRUE,
  seed = NULL,
  ...
)
```

## Arguments

- survey_data:

  Data frame with individual survey data (required if uncertainty_method
  is "bootstrap")

- input_path:

  Path to Excel input file with multiple sheets

- output_file:

  Path to the output RDS file where the electo_fit object will be saved
  (e.g., "output/results.rds")

- uncertainty_method:

  Type of input data: "bootstrap" or "mcmc"

- strategy:

  Projection strategy: "top_down" or "bottom_up"

- nsims:

  Number of Monte Carlo simulations for transfer matrices (or bootstrap
  replications if uncertainty_method is "bootstrap")

- factor_correccion_abstencion:

  Abstention correction factor (default 3)

- factor_correccion_jovenes:

  New voters correction factor (default 2.5)

- factor_correccion_otbl:

  Other+blank votes intention correction factor (default 3)

- tiempo_entre_elecciones:

  Years between elections for demographic adjustments

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
  codigo_provincia, censo_real). If NULL (default), census data is
  downloaded from INE using
  [`get_censo()`](https://vota.spainelectoralproject.com/reference/get_censo.md).

- verbose:

  Show progress messages (default TRUE)

- seed:

  Seed for reproducibility (default NULL)

- ...:

  Additional arguments for bootstrap internal function. The current
  accepted parameters are calib_vars and weights. Only used when
  uncertainty_method is "bootstrap"

## Value

Object of class electo_fit with simulation results including:

- estimacion:

  National vote estimates by party

- estimacion_sims:

  National vote estimates simulations by party

- estimacion_provincias_sims:

  Provincial results with assigned seats

- mt_sims_pct:

  Transfer matrix simulations (percentages)

- mt_sims_electores:

  Transfer matrix simulations (number of voters)

- dhondt_output:

  Detailed D'Hondt allocation results

- participacion_media:

  Estimated turnout percentage

- metadata:

  Execution metadata

## See also

Other main-functions:
[`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
