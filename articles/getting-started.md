# Getting Started with vota

## Introduction

**vota** is an R package for simulating Spanish electoral outcomes.
Starting from national survey data (transfer matrices), it projects vote
intentions to provincial seat assignments using the D’Hondt method – the
same allocation system used in Spanish elections.

This vignette walks you through the basic setup and a minimal simulation
using the package’s included datasets.

## Installation

``` r
# Install from GitHub
devtools::install_github("hmeleiro/vota")
```

``` r
library(vota)
```

## Included Datasets

The package includes real data from the Spanish general elections of
July 23, 2023. These datasets serve as both examples and ready-to-use
inputs:

### Transfer Matrix (`mt`)

The transfer matrix captures how voters from the last election intend to
vote now. Each row represents a combination of past party recall
(`recuerdo`) and current vote intention (`idv`), along with the
percentage transferring between them.

``` r
data(mt)
head(mt)
#> # A tibble: 6 × 8
#>   idv       PSOE     PP    Vox  Sumar  OTBL   ABNL `<18`
#>   <chr>    <dbl>  <dbl>  <dbl>  <dbl> <dbl>  <dbl> <dbl>
#> 1 PSOE    67.7    0.898  0     11.4    4.95 10.4   17.2 
#> 2 PP       2.57  68.8    3.68   1.31   5.48  8.62   6.87
#> 3 Vox      1.28  12.7   78.4    0.106  2.11 11.5   19.2 
#> 4 Sumar    2.81   0      0.586 37.4    2.34  1.29   4.30
#> 5 Podemos  1.22   0      0.110 22.5    2.30  0.872  1.34
#> 6 ERC      0.187  0      0      1.04  10.9   0.365  1.33
```

### Previous Election Results (`votos_23J`)

Official vote totals from the 23J election, used as the base for
demographic adjustments and voter redistribution.

``` r
data(votos_23J)
votos_23J
#> # A tibble: 6 × 2
#>   recuerdo votos_ant
#>   <chr>        <dbl>
#> 1 PSOE       7760970
#> 2 PP         8091840
#> 3 Vox        3033744
#> 4 Sumar      3014006
#> 5 OTBL       2581974
#> 6 ABNL      10663528
```

### Provincial Voting Patterns (`patrones_23J`)

Historical voting distributions by province, used to project national
estimates to the provincial level.

``` r
data(patrones_23J)
head(patrones_23J)
#> # A tibble: 6 × 17
#>   codigo_provincia  PSOE    PP   Vox Sumar   ERC Junts   CUP   PNV `EH Bildu`
#>   <chr>            <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>      <dbl>
#> 1 01               0.599 0.373 0.210 0.710     0     0     0  10.1       9.85
#> 2 02               0.979 1.10  1.18  0.520     0     0     0   0         0   
#> 3 03               3.69  4.09  4.70  3.81      0     0     0   0         0   
#> 4 04               1.19  1.63  2.19  0.701     0     0     0   0         0   
#> 5 05               0.341 0.524 0.484 0.164     0     0     0   0         0   
#> 6 06               1.97  1.84  1.72  0.882     0     0     0   0         0   
#> # ℹ 7 more variables: UPN <dbl>, BNG <dbl>, CCa <dbl>, SALF <dbl>,
#> #   Podemos <dbl>, OTBL <dbl>, ABNL <dbl>
```

### Seats per Province (`n_seats`)

The number of Congressional seats allocated to each of Spain’s 52
electoral districts.

``` r
data(n_seats)
head(n_seats)
#> # A tibble: 6 × 2
#>   codigo_provincia n_diputados
#>   <chr>                  <dbl>
#> 1 01                         4
#> 2 02                         4
#> 3 03                        12
#> 4 04                         6
#> 5 05                         3
#> 6 06                         5
```

### Manual Adjustments (`retoques`)

Optional expert adjustments – add or subtract votes from specific
parties based on external knowledge.

``` r
data(retoques)
retoques
#> # A tibble: 2 × 2
#>   idv   votos_adicionales
#>   <chr>             <dbl>
#> 1 Vox             -230000
#> 2 CCa               24000
```

### Small Parties (`small_parties`)

Vote estimates for parties too small to model in the transfer matrix but
relevant for the overall picture.

``` r
data(small_parties)
small_parties
#> # A tibble: 3 × 2
#>   idv    votos
#>   <chr>  <dbl>
#> 1 BNG   152327
#> 2 CCa   114718
#> 3 UPN    51764
```

## Setting Up a Project

The easiest way to start a simulation is to scaffold a project
directory:

``` r
setup_electoral_project("my_simulation_2024")
```

This creates:

- `input/input.xlsx` – An Excel template pre-filled with example data
- `output/` – Directory for simulation results
- `scripts/main.R` – A starter script

Alternatively, generate just the Excel template:

``` r
create_input_template("input/input.xlsx")
```

## Running a Simulation

Once you have your input data in an Excel file, run the full pipeline
with
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md):

``` r
results <- run_vota(
  input_path = "input/input.xlsx",
  output_file = "output/results.rds",
  uncertainty_method = "mcmc",
  nsims = 100,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  tiempo_entre_elecciones = 0.1,
  tau = 300,
  umbral = 0.03,
  seed = 42,
  verbose = TRUE
)
```

The function returns an `electo_fit` object containing:

- **`estimacion`** – National estimates with confidence intervals (vote
  % and seats)
- **`estimacion_sims`** – All simulation results
- **`estimacion_provincias_sims`** – Provincial-level simulation results
- **`dhondt_output`** – Detailed D’Hondt allocation
- **`mt_sims_pct`** / **`mt_sims_electores`** – Transfer matrix
  simulations
- **`participacion_media`** – Estimated mean turnout
- **`metadata`** – Execution parameters

## Inspecting Results

``` r
# Quick overview
print(results)

# Detailed summary with win probabilities
summary(results)

# Access the national estimates table
results$estimacion
```

## Visualizing Results

The `electo_fit` object has a dedicated
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) method with
four visualization types:

``` r
# National vote shares with confidence intervals
plot(results, "nacional")

# Distribution of seats across simulations (by party)
plot(results, "seats_dist")

# Seats per province for a specific party
plot(results, "provincia", partido = "PP")

# Seat fragility: margin of last D'Hondt quotient
plot(results, "dhondt_margin")
```

## Next Steps

- **[The VOTA
  Methodology](https://vota.spainelectoralproject.com/articles/methodology.md)**
  – Understand the five corrections and the statistical model
- **[Step-by-step
  Tutorial](https://vota.spainelectoralproject.com/articles/tutorial.md)**
  – Walk through each function in the pipeline using the internal
  datasets
