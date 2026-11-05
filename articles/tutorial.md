# Step-by-step Tutorial

## Introduction

This tutorial walks through the vota pipeline step by step, using only
the datasets included in the package. Instead of running
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
as a black box, we’ll call each function individually to understand what
happens at each stage.

``` r

library(vota)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(tidyr)
```

## Step 1: Explore the Internal Data

### The Transfer Matrix

The `mt` dataset is an example transfer matrix in wide format. Each row
is a vote intention party (`idv`), and each column is a previous vote
recall party. The last column (`idv == "N"`) provides the sample size
for each column (vote recall).

``` r

data(mt)
mt
#> # A tibble: 15 × 8
#>    idv            PSOE      PP     Vox   Sumar    OTBL     ABNL  `<18`
#>    <chr>         <dbl>   <dbl>   <dbl>   <dbl>   <dbl>    <dbl>  <dbl>
#>  1 PSOE        67.7      0.898   0      11.4     4.95   10.4     17.2 
#>  2 PP           2.57    68.8     3.68    1.31    5.48    8.62     6.87
#>  3 Vox          1.28    12.7    78.4     0.106   2.11   11.5     19.2 
#>  4 Sumar        2.81     0       0.586  37.4     2.34    1.29     4.30
#>  5 Podemos      1.22     0       0.110  22.5     2.30    0.872    1.34
#>  6 ERC          0.187    0       0       1.04   10.9     0.365    1.33
#>  7 SALF         0.156    0.817   7.76    0       0.620   1.24     0   
#>  8 Junts        0.0382   0       0       0       5.76    0.0915   0   
#>  9 PNV          0.0487   0       0       0       3.05    0        0   
#> 10 EH Bildu     0.183    0       0       0.433   5.51    0.692    0   
#> 11 CCa          0.0480   0       0       0       0.564   0        0   
#> 12 OTBL         5.11     5.79    1.62    7.92   32.0     6.85    12.1 
#> 13 ABNL         3.45     2.05    2.71    1.23    4.12   44.4     17.1 
#> 14 Indecisos   15.2      9.02    5.12   16.6    20.3    13.7     20.6 
#> 15 N         1188.     771.    390.    423.    354.    547.     119.
```

The columns represent parties from the *previous* election (recuerdo):
PSOE, PP, Vox, Sumar, OTBL (other/blank), and ABNL (abstention/null).
The `idv` column shows who these voters now intend to vote for. For
example, the row where `idv = "PP"` shows how many voters of each
previous party now intend to vote PP.

### Previous Election Results

`votos_23J` contains the official total votes per party from the 23J
2023 election:

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

These totals are used to convert transfer percentages into absolute vote
counts.

### Provincial Patterns

`patrones_23J` contains each party’s historical vote share by province
(as a proportion between 0 and 1):

``` r

data(patrones_23J)
head(patrones_23J, 12)
#> # A tibble: 12 × 17
#>    codigo_provincia   PSOE    PP   Vox  Sumar   ERC Junts   CUP   PNV `EH Bildu`
#>    <chr>             <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>      <dbl>
#>  1 01                0.599 0.373 0.210  0.710   0     0     0    10.1       9.85
#>  2 02                0.979 1.10  1.18   0.520   0     0     0     0         0   
#>  3 03                3.69  4.09  4.70   3.81    0     0     0     0         0   
#>  4 04                1.19  1.63  2.19   0.701   0     0     0     0         0   
#>  5 05                0.341 0.524 0.484  0.164   0     0     0     0         0   
#>  6 06                1.97  1.84  1.72   0.882   0     0     0     0         0   
#>  7 07                1.95  2.22  2.46   2.76    0     0     0     0         0   
#>  8 08               12.2   4.53  6.46  13.4    70.5  65.3  67.5   0         0   
#>  9 09                0.890 1.02  0.825  0.572   0     0     0     0         0   
#> 10 10                1.17  1.11  1.03   0.536   0     0     0     0         0   
#> 11 11                2.71  2.75  3.11   2.71    0     0     0     0         0   
#> 12 12                1.29  1.34  1.57   1.45    0     0     0     0         0   
#> # ℹ 7 more variables: UPN <dbl>, BNG <dbl>, CCa <dbl>, SALF <dbl>,
#> #   Podemos <dbl>, OTBL <dbl>, ABNL <dbl>

# How many provinces and parties?
cat("Provinces:", length(unique(patrones_23J$codigo_provincia)), "\n")
#> Provinces: 52
cat("Parties:", length(unique(patrones_23J$partido)), "\n")
#> Warning: Unknown or uninitialised column: `partido`.
#> Parties: 0
```

### Seats per Province

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
cat("Total seats:", sum(n_seats$n_diputados), "\n")
#> Total seats: 350
```

### Optional: Adjustments and Small Parties

``` r

data(retoques)
retoques
#> # A tibble: 2 × 2
#>   idv   votos_adicionales
#>   <chr>             <dbl>
#> 1 Vox             -230000
#> 2 CCa               24000

data(small_parties)
small_parties
#> # A tibble: 3 × 2
#>   idv    votos
#>   <chr>  <dbl>
#> 1 BNG   152327
#> 2 CCa   114718
#> 3 UPN    51764
```

## Step 2: Prepare the Transfer Matrix

The
[`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md)
function needs the transfer matrix in long format with columns
`recuerdo`, `idv`, `n`, and `pct_original`. Let’s prepare it from the
wide `mt` dataset.

``` r

# Convert wide mt to long format
party_cols <- setdiff(names(mt), c("idv", "n"))

mt_long_raw <- 
  mt %>%
  pivot_longer(
    cols = party_cols,
    names_to = "recuerdo",
    values_to = "pct_original"
  ) 
#> Warning: Using an external vector in selections was deprecated in tidyselect 1.1.0.
#> ℹ Please use `all_of()` or `any_of()` instead.
#>   # Was:
#>   data %>% select(party_cols)
#> 
#>   # Now:
#>   data %>% select(all_of(party_cols))
#> 
#> See <https://tidyselect.r-lib.org/reference/faq-external-vector.html>.
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

mt_long <- 
  mt_long_raw %>% 
  filter(idv != "N") %>% 
  left_join(
    mt_long_raw %>% 
      filter(idv == "N") %>% 
      select(recuerdo, n = pct_original), 
    by = join_by(recuerdo)
  ) %>%
  select(recuerdo, idv, n, pct_original)

head(mt_long)
#> # A tibble: 6 × 4
#>   recuerdo idv       n pct_original
#>   <chr>    <chr> <dbl>        <dbl>
#> 1 PSOE     PSOE  1188.       67.7  
#> 2 PP       PSOE   771.        0.898
#> 3 Vox      PSOE   390.        0    
#> 4 Sumar    PSOE   423.       11.4  
#> 5 OTBL     PSOE   354.        4.95 
#> 6 ABNL     PSOE   547.       10.4
```

The `pct_original` column contains the transfer percentage for each
recuerdo-idv pair, and `n` contains the number of survey respondents in
that cell.

## Step 3: Simulate Transfer Matrices

Using
[`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md),
we generate multiple simulated transfer matrices via multinomial
resampling. Each simulation draws from the sample distribution, creating
natural variability.

``` r

mt_sims <- simulate_mt(mt_long, nsims = 5, seed = 42)

# sim = 0 is the original (unperturbed) matrix
head(mt_sims)
#> # A tibble: 6 × 5
#>     sim recuerdo idv       n transfer
#>   <dbl> <chr>    <chr> <dbl>    <dbl>
#> 1     0 PSOE     PSOE  1188.  0.677  
#> 2     0 PP       PSOE   771.  0.00898
#> 3     0 Vox      PSOE   390.  0      
#> 4     0 Sumar    PSOE   423.  0.114  
#> 5     0 OTBL     PSOE   354.  0.0495 
#> 6     0 ABNL     PSOE   547.  0.104
cat("Number of simulations (including original):", length(unique(mt_sims$sim)), "\n")
#> Number of simulations (including original): 6
```

Each simulation (`sim = 1, 2, ...`) is a plausible transfer matrix.
`sim = 0` is the original observed matrix.

## Step 4: Run the VOTA Algorithm

The [`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
function takes a single transfer matrix (in long format with `recuerdo`,
`idv`, `transfer` columns) and returns national vote estimates. Let’s
run it on the original matrix (`sim = 0`):

``` r

# Get the original (sim=0) transfer matrix
mt_original <- mt_sims %>% filter(sim == 0)

result <- vota(
  mt_simplificada = mt_original,
  tiempo_entre_elecciones = 0.1,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  retoques = retoques,
  small_parties = small_parties,
  votos_ant = votos_23J
)

# National vote estimates
result$estimacion %>% 
  arrange(desc(votos))
#> # A tibble: 15 × 2
#>    idv          votos
#>    <chr>        <dbl>
#>  1 ABNL     11836387.
#>  2 PSOE      7068734.
#>  3 PP        6943188.
#>  4 Vox       3998990.
#>  5 Sumar     1703765.
#>  6 OTBL      1018487.
#>  7 Podemos   1008165.
#>  8 ERC        405482.
#>  9 SALF       398480.
#> 10 EH Bildu   228060.
#> 11 Junts      185460.
#> 12 BNG        152327 
#> 13 CCa        114718 
#> 14 PNV         99090.
#> 15 UPN         51764
```

The output is a data frame with estimated votes per party (`idv`). These
are absolute vote counts.

We can compute vote percentages:

``` r

estimacion <- result$estimacion %>%
  mutate(pct = votos / sum(votos) * 100) %>%
  arrange(desc(pct))

estimacion
#> # A tibble: 15 × 3
#>    idv          votos    pct
#>    <chr>        <dbl>  <dbl>
#>  1 ABNL     11836387. 33.6  
#>  2 PSOE      7068734. 20.1  
#>  3 PP        6943188. 19.7  
#>  4 Vox       3998990. 11.4  
#>  5 Sumar     1703765.  4.84 
#>  6 OTBL      1018487.  2.89 
#>  7 Podemos   1008165.  2.86 
#>  8 ERC        405482.  1.15 
#>  9 SALF       398480.  1.13 
#> 10 EH Bildu   228060.  0.648
#> 11 Junts      185460.  0.527
#> 12 BNG        152327   0.433
#> 13 CCa        114718   0.326
#> 14 PNV         99090.  0.281
#> 15 UPN         51764   0.147
```

## Step 5: Run VOTA Across All Simulations

To quantify uncertainty, we run
[`vota()`](https://vota.spainelectoralproject.com/reference/vota.md) on
each simulated transfer matrix:

``` r

all_estimates <- lapply(unique(mt_sims$sim), function(s) {
  mt_s <- mt_sims %>% filter(sim == s)
  res <- vota(
    mt_simplificada = mt_s,
    tiempo_entre_elecciones = 0.1,
    factor_correccion_abstencion = 3,
    factor_correccion_jovenes = 2.5,
    factor_correccion_otbl = 2.5,
    retoques = retoques,
    small_parties = small_parties,
    votos_ant = votos_23J
  )
  res$estimacion %>% mutate(sim = s)
})

all_estimates <- bind_rows(all_estimates)

# Compute percentages per simulation
all_estimates <- all_estimates %>%
  group_by(sim) %>%
  mutate(pct = votos / sum(votos) * 100) %>%
  ungroup()

head(all_estimates, n = 20)
#> # A tibble: 20 × 4
#>    idv          votos   sim    pct
#>    <chr>        <dbl> <dbl>  <dbl>
#>  1 ABNL     11836387.     0 33.6  
#>  2 EH Bildu   228060.     0  0.648
#>  3 ERC        405482.     0  1.15 
#>  4 Junts      185460.     0  0.527
#>  5 OTBL      1018487.     0  2.89 
#>  6 PNV         99090.     0  0.281
#>  7 PP        6943188.     0 19.7  
#>  8 PSOE      7068734.     0 20.1  
#>  9 Podemos   1008165.     0  2.86 
#> 10 SALF       398480.     0  1.13 
#> 11 Sumar     1703765.     0  4.84 
#> 12 Vox       3998990.     0 11.4  
#> 13 BNG        152327      0  0.433
#> 14 CCa        114718      0  0.326
#> 15 UPN         51764      0  0.147
#> 16 ABNL     10854879.     1 32.8  
#> 17 EH Bildu  2091588.     1  6.33 
#> 18 ERC       2157660.     1  6.53 
#> 19 Junts     2098097.     1  6.34 
#> 20 OTBL       857199.     1  2.59
```

Now we can see how estimates vary across simulations:

``` r

summary_stats <- all_estimates %>%
  group_by(idv) %>%
  summarise(
    pct_median = median(pct),
    pct_lwr = quantile(pct, 0.05),
    pct_upr = quantile(pct, 0.95),
    .groups = "drop"
  ) %>%
  arrange(desc(pct_median))

summary_stats
#> # A tibble: 15 × 4
#>    idv      pct_median pct_lwr pct_upr
#>    <chr>         <dbl>   <dbl>   <dbl>
#>  1 ABNL         32.7    32.6    33.4  
#>  2 SALF          6.51    2.46    6.60 
#>  3 ERC           6.46    2.46    6.67 
#>  4 PSOE          6.46    6.42   16.7  
#>  5 PNV           6.44    1.82    6.58 
#>  6 PP            6.42    6.39   16.5  
#>  7 Sumar         6.42    5.22    6.53 
#>  8 Podemos       6.37    3.72    6.52 
#>  9 Junts         6.37    1.98    6.58 
#> 10 EH Bildu      6.33    2.04    6.42 
#> 11 Vox           5.64    5.54   10.00 
#> 12 OTBL          2.60    2.56    2.82 
#> 13 BNG           0.460   0.439   0.461
#> 14 CCa           0.346   0.331   0.347
#> 15 UPN           0.156   0.149   0.157
```

## Step 6: Provincial Projection

National estimates need to be distributed across Spain’s 52 provinces
using historical voting patterns. For `sim = 0`,
[`simulate_prov_votes()`](https://vota.spainelectoralproject.com/reference/simulate_prov_votes.md)
uses the deterministic method: it applies the original patterns without
perturbation and without Dirichlet or multinomial draws.

``` r

# Use the point estimate (sim=0)
estimacion_nacional <- result$estimacion

# Filter patterns to only include parties in our estimation
parties_in_estimation <- estimacion_nacional$idv
patrones_filtrados <- patrones_23J %>%
  pivot_longer(
    all_of(parties_in_estimation), 
    names_to = "idv", 
    values_to = "patron"
  ) %>%
  mutate(patron = patron / 100) %>%
  filter(patron > 0)

# Project the point estimate deterministically
prov_votes <- simulate_prov_votes(
  patrones = patrones_filtrados,
  estimacion = estimacion_nacional,
  method = "deterministic"
)

# Result is a matrix: provinces (rows) x parties (columns)
dim(prov_votes)
#> [1] 52 15
head(prov_votes[, 1:4])
#>         ABNL EH Bildu ERC Junts
#> 01  93388.82 22469.27   0     0
#> 02  88394.42     0.00   0     0
#> 03 406544.56     0.00   0     0
#> 04 170208.56     0.00   0     0
#> 05  34689.63     0.00   0     0
#> 06 165111.91     0.00   0     0
```

Each cell contains the expected number of votes for that party in that
province. The result does not depend on `seed`, `tau`, or the
random-number generator state. For `sim > 0`, the pipeline continues to
use the Dirichlet method and multinomial allocation; in those
simulations, `tau` controls how closely the provincial distribution
follows the historical pattern (higher = less variability).

## Step 7: D’Hondt Seat Allocation

Finally, we allocate seats using the D’Hondt method. First, we prepare
the data in the format expected by
[`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md):

``` r

# Convert provincial votes matrix to long format
prov_df <- as.data.frame(prov_votes) %>%
  mutate(codigo_provincia = rownames(prov_votes)) %>%
  pivot_longer(
    cols = -codigo_provincia,
    names_to = "partido",
    values_to = "votos_prov"
  ) %>%
  # Add seat counts

  left_join(n_seats, by = "codigo_provincia") %>%
  # Add simulation identifier
  mutate(sim = 0L) %>%
  # Calculate vote percentage per province
  group_by(sim, codigo_provincia) %>%
  mutate(
    votos_validos = sum(votos_prov),
    pct_sobre_validos = votos_prov / votos_validos
  ) %>%
  ungroup()

head(prov_df)
#> # A tibble: 6 × 7
#>   codigo_provincia partido  votos_prov n_diputados   sim votos_validos
#>   <chr>            <chr>         <dbl>       <dbl> <int>         <dbl>
#> 1 01               ABNL         93389.           4     0       227027.
#> 2 01               EH Bildu     22469.           4     0       227027.
#> 3 01               ERC              0            4     0       227027.
#> 4 01               Junts            0            4     0       227027.
#> 5 01               OTBL          4428.           4     0       227027.
#> 6 01               PNV          10038.           4     0       227027.
#> # ℹ 1 more variable: pct_sobre_validos <dbl>
```

Apply the electoral threshold (3%) and run D’Hondt:

``` r

# Filter parties that pass the threshold
prov_above_threshold <- prov_df %>%
  filter(!partido %in% c("OTBL", "ABNL"), pct_sobre_validos >= 0.03)

# Run D'Hondt allocation
dhondt_result <- fast_dhondt(
  data = prov_above_threshold,
  cod_prov = codigo_provincia,
  sim = sim,
  partido = partido,
  votos_prov = votos_prov,
  nseats = n_diputados
)

head(dhondt_result)
#> # A tibble: 6 × 13
#>   codigo_provincia partido  votos_prov n_diputados   sim votos_validos
#>   <chr>            <chr>         <dbl>       <dbl> <int>         <dbl>
#> 1 01               PSOE         42331.           4     0       227027.
#> 2 01               PP           25896.           4     0       227027.
#> 3 01               EH Bildu     22469.           4     0       227027.
#> 4 01               PSOE         42331.           4     0       227027.
#> 5 02               PP           76123.           4     0       305854.
#> 6 02               PSOE         69193.           4     0       305854.
#> # ℹ 7 more variables: pct_sobre_validos <dbl>, divisor <int>, cociente <dbl>,
#> #   order <int>, tipo <chr>, col <dbl>, dif <dbl>
```

Aggregate to get total seats per party:

``` r

seats_by_party <- dhondt_result %>%
  filter(tipo == "Asignado") %>%
  count(partido, name = "seats") %>%
  arrange(desc(seats))

seats_by_party
#> # A tibble: 12 × 2
#>    partido  seats
#>    <chr>    <int>
#>  1 PP         126
#>  2 PSOE       125
#>  3 Vox         61
#>  4 Sumar       12
#>  5 ERC          7
#>  6 EH Bildu     6
#>  7 Podemos      5
#>  8 BNG          2
#>  9 Junts        2
#> 10 PNV          2
#> 11 CCa          1
#> 12 UPN          1
cat("Total seats assigned:", sum(seats_by_party$seats), "\n")
#> Total seats assigned: 350
```

## Step 8: The Full Pipeline with `run_vota()`

In practice, you would use
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
which orchestrates all of the above steps automatically. It reads from
an Excel file, so let’s create one using the template function:

``` r

# Create a temporary project
tmp_dir <- tempdir()
project_dir <- file.path(tmp_dir, "tutorial_project")
setup_electoral_project(project_dir)

# Run the full pipeline
results <- run_vota(
  input_path = file.path(project_dir, "input", "input.xlsx"),
  output_file = file.path(project_dir, "output", "results.rds"),
  uncertainty_method = "mcmc",
  nsims = 50,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  tiempo_entre_elecciones = 0.1,
  tau = 300,
  umbral = 0.03,
  seed = 42,
  verbose = TRUE
)

# View results
print(results)
summary(results)

# Visualize
plot(results, "nacional")
plot(results, "seats_dist")
```

## Summary

In this tutorial we walked through each step of the electoral
simulation:

1.  **Data exploration** – Understanding the transfer matrix, previous
    results, and provincial patterns
2.  **Transfer matrix simulation** –
    [`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md)
    for multinomial uncertainty
3.  **VOTA algorithm** –
    [`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
    with five sequential corrections
4.  **Provincial projection** –
    [`simulate_prov_votes()`](https://vota.spainelectoralproject.com/reference/simulate_prov_votes.md)
    with Dirichlet variability
5.  **Seat allocation** –
    [`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)
    for vectorized D’Hondt
6.  **Full pipeline** –
    [`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
    tying everything together

## Further Reading

- **[Getting
  Started](https://vota.spainelectoralproject.com/articles/getting-started.md)**
  – Quick setup guide
- **[The VOTA
  Methodology](https://vota.spainelectoralproject.com/articles/methodology.md)**
  – Statistical details of the algorithm
