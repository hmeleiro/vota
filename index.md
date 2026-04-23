# vota

[Leer en español](https://vota.spainelectoralproject.com/README.es.md)

**vota** is an R package for simulating Spanish electoral outcomes. It
projects national survey data to provincial seat assignments using
transfer matrices, Monte Carlo methods, and bootstrapping. It implements
the *VOTA* (**V**ote **O**utcome **T**ransfer-based **A**lgorithm),
specifically designed for the Spanish electoral system with the D’Hondt
method.

## Installation

You can install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("hmeleiro/vota")
```

## Overview

The package implements a complete electoral simulation pipeline:

1.  **Data loading & validation** – Read multi-sheet Excel input and
    validate consistency across sheets
2.  **Transfer matrix simulation** – Generate uncertainty via MCMC
    (multinomial resampling) or bootstrap
3.  **VOTA algorithm** – Apply five sequential corrections (abstention,
    new voters, undecided redistribution, small parties, manual
    adjustments)
4.  **Provincial projection** – Project national estimates to provinces
    using historical voting patterns and Dirichlet simulation
5.  **D’Hondt seat allocation** – Vectorized seat assignment across all
    provinces and simulations
6.  **Aggregation & reporting** – Confidence intervals, probability of
    winning, and visualizations

## Quick Start

### Set up a project

``` r
library(vota)

# Create a new electoral project with template files
setup_electoral_project("my_simulation")
# Creates: input/input.xlsx, output/, scripts/main.R
```

### Run a simulation

``` r
# Run the full pipeline
results <- run_vota(
  input_path = "input/input.xlsx",
  output_file = "output/results.rds",
  uncertainty_method = "mcmc",
  nsims = 100,
  seed = 42
)

# Inspect results
print(results)
summary(results)
```

### Visualize results

``` r
# National vote share estimates with confidence intervals
plot(results, "nacional")

# Seat distribution across simulations
plot(results, "seats_dist")

# Seats per province for a specific party
plot(results, "provincia", partido = "PP")

# D'Hondt margin analysis (seat fragility)
plot(results, "dhondt_margin")
```

## Included Datasets

The package ships with example data from the Spanish general elections
of July 23, 2023 (23J):

| Dataset         | Description                                            |
|-----------------|--------------------------------------------------------|
| `mt`            | Example transfer matrix (recuerdo x intención de voto) |
| `votos_23J`     | Official vote totals from the 23J election             |
| `patrones_23J`  | Historical voting patterns by province (23J)           |
| `n_seats`       | Number of seats per Spanish province (52 districts)    |
| `retoques`      | Example manual adjustments                             |
| `small_parties` | Example small party estimates                          |

``` r
# Explore the included data
data(mt)
data(votos_23J)
data(patrones_23J)
data(n_seats)
```

## Key Functions

| Function                                                                                                   | Purpose                                              |
|------------------------------------------------------------------------------------------------------------|------------------------------------------------------|
| [`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)                               | Run full simulation pipeline                         |
| [`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)                                       | Core VOTA algorithm with 5 corrections               |
| [`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)                         | Vectorized D’Hondt seat allocation                   |
| [`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md)                         | Monte Carlo transfer matrix simulations              |
| [`simulate_prov_votes()`](https://vota.spainelectoralproject.com/reference/simulate_prov_votes.md)         | Provincial vote simulations (Dirichlet/logit-normal) |
| [`draw_mt()`](https://vota.spainelectoralproject.com/reference/draw_mt.md)                                 | Orchestrate transfer matrix generation               |
| [`project_to_districts()`](https://vota.spainelectoralproject.com/reference/project_to_districts.md)       | Project national estimates to provinces              |
| [`setup_electoral_project()`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md) | Scaffold a new simulation project                    |
| [`create_input_template()`](https://vota.spainelectoralproject.com/reference/create_input_template.md)     | Generate Excel input template                        |
| [`plot.electo_fit()`](https://vota.spainelectoralproject.com/reference/plot.electo_fit.md)                 | Visualize simulation results                         |
| [`summary.electo_fit()`](https://vota.spainelectoralproject.com/reference/summary.electo_fit.md)           | Summary statistics and win probabilities             |

## Input Data Format

The simulation expects an Excel file (`.xlsx`) with these sheets:

| Sheet                      | Required Columns                  | Description                                          |
|----------------------------|-----------------------------------|------------------------------------------------------|
| `partidos`                 | `recuerdo`, `idv`                 | Party code mapping (past recall → current intention) |
| `mt_simplificada`          | `idv` + party columns             | Transfer matrix with row `N` for sample sizes        |
| `patrones`                 | `codigo_provincia`, party columns | Provincial voting patterns (proportions)             |
| `anteriores_elecciones`    | `recuerdo`, `votos_ant`           | Previous election results                            |
| `n_diputados`              | `codigo_provincia`, `n_diputados` | Seats per province                                   |
| `retoques` (optional)      | `idv`, `votos_adicionales`        | Manual vote adjustments                              |
| `small_parties` (optional) | `idv`, `votos`                    | Small party vote estimates                           |

Use
[`create_input_template()`](https://vota.spainelectoralproject.com/reference/create_input_template.md)
to generate a correctly formatted template with example data.

## Parameters

Key parameters for
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md):

| Parameter                      | Default        | Description                                                  |
|--------------------------------|----------------|--------------------------------------------------------------|
| `uncertainty_method`           | `"mcmc"`       | `"mcmc"` or `"bootstrap"`                                    |
| `strategy`                     | `"top_down"`   | `"top_down"` or `"bottom_up"`                                |
| `nsims`                        | `100`          | Number of Monte Carlo simulations                            |
| `factor_correccion_abstencion` | `3`            | Abstention correction factor                                 |
| `factor_correccion_jovenes`    | `2.5`          | New voters correction factor                                 |
| `factor_correccion_otbl`       | `3`            | Other/blank votes correction factor                          |
| `tiempo_entre_elecciones`      | `0.1`          | Years between elections (for demographic adjustment)         |
| `tau`                          | `300`          | Dirichlet concentration for provincial projection            |
| `umbral`                       | `0.03`         | Minimum vote threshold for seat assignment (3%)              |
| `tipo_umbral`                  | `"provincial"` | Threshold type: `"provincial"`, `"autonomico"`, or `"mixto"` |
| `interval_level`               | `0.9`          | Confidence level for uncertainty intervals                   |
| `seed`                         | `NULL`         | Seed for reproducibility                                     |

## Vignettes

- [Getting
  Started](https://vota.spainelectoralproject.com/vignettes/getting-started.Rmd)
  / [Primeros
  pasos](https://vota.spainelectoralproject.com/vignettes/primeros-pasos.Rmd)
- [The VOTA
  Methodology](https://vota.spainelectoralproject.com/vignettes/methodology.Rmd)
  / [Metodología
  VOTA](https://vota.spainelectoralproject.com/vignettes/metodologia.Rmd)
- [Step-by-step
  Tutorial](https://vota.spainelectoralproject.com/vignettes/tutorial.Rmd)
  / [Tutorial paso a
  paso](https://vota.spainelectoralproject.com/vignettes/tutorial-es.Rmd)

## License

MIT
