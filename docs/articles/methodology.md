# The VOTA Methodology

``` r

library(vota)
```

## Overview

The *VOTA* algorithm is the core projection method in vota. It
transforms a transfer matrix (who voters previously supported vs. who
they intend to vote for now) into national vote estimates, applying five
sequential corrections to improve realism. These estimates are then
projected to provincial level and converted to seats using the D’Hondt
method.

This vignette explains each stage of the methodology.

## The Transfer Matrix

The transfer matrix is the fundamental input. It is a cross-tabulation
of:

- **Rows:** Past party recall (`recuerdo`) – which party voters say they
  voted for last time
- **Columns:** Current vote intention (`idv`) – which party they intend
  to vote for now

Each cell contains the proportion of voters transferring from one party
to another. Special categories include:

- **ABNL** (Abstención / Nulo): Abstention or null votes
- **OTBL** (Otros / Blanco): Other parties or blank votes
- **\<18**: Voters who were under 18 in the previous election (new
  voters)
- **Indecisos**: Undecided voters

``` r

data(mt)
str(mt)
#> tibble [15 × 8] (S3: tbl_df/tbl/data.frame)
#>  $ idv  : chr [1:15] "PSOE" "PP" "Vox" "Sumar" ...
#>  $ PSOE : num [1:15] 67.74 2.57 1.28 2.81 1.22 ...
#>  $ PP   : num [1:15] 0.898 68.754 12.677 0 0 ...
#>  $ Vox  : num [1:15] 0 3.677 78.412 0.586 0.11 ...
#>  $ Sumar: num [1:15] 11.425 1.313 0.106 37.397 22.545 ...
#>  $ OTBL : num [1:15] 4.95 5.48 2.11 2.34 2.3 ...
#>  $ ABNL : num [1:15] 10.365 8.622 11.495 1.286 0.872 ...
#>  $ <18  : num [1:15] 17.18 6.87 19.21 4.3 1.34 ...
```

## The Five Corrections

The [`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
function applies five corrections in sequence. Each builds on the output
of the previous one.

### 1. Abstention Correction

Voters who abstained in the previous election (`ABNL` recall) tend to
have unreliable transfer patterns. The correction downscales transfer
probabilities from ABNL by dividing them by
`factor_correccion_abstencion` (default: 3), then renormalizes.

**Rationale:** Previous non-voters who now say they’ll vote for a
specific party are historically less likely to actually do so. Dividing
by 3 means only ~1/3 of their stated intention is credited.

### 2. New Voters Correction

Voters under 18 during the previous election (`<18` recall) are a new
demographic cohort. Their transfer probabilities are similarly
downscaled by `factor_correccion_jovenes` (default: 2.5).

The number of new voters is estimated as:

``` math
\text{New voters} = \text{Total previous votes} \times 0.01 \times \text{years between elections}
```

A corresponding mortality adjustment is applied to existing voter groups
proportionally.

**Rationale:** Young voters who haven’t voted before tend to overstate
their intention to vote and to have less stable preferences.

### 3. Undecided Redistribution

Voters classified as “Indecisos” (undecided) are redistributed across
all parties proportionally to the existing transfer pattern. This is
equivalent to assuming that undecided voters will ultimately distribute
themselves in the same proportions as decided voters.

### 4. Small Parties Incorporation

Small parties not included in the main transfer matrix are injected via
the `small_parties` parameter. Their estimated total votes are added
directly, and any overlapping party codes are replaced.

**Rationale:** Very small parties (e.g., regional parties with \<1%
nationally) are difficult to model via transfer matrices due to small
sample sizes. External estimates (from regional polls or expert
judgment) are more reliable.

### 5. Manual Adjustments

Expert adjustments (`retoques`) add or subtract votes from specific
parties. These are applied last, as a final discretionary correction.

**Rationale:** Analysts may have information not captured by survey data
(e.g., last-minute campaign effects, mobilization signals).

## Uncertainty Quantification

### MCMC Method

When `uncertainty_method = "mcmc"`, the package generates `nsims`
simulated transfer matrices using multinomial resampling. The process:

1.  Takes the observed transfer matrix with sample sizes (`n`)
2.  Draws `nsims` multinomial samples of the same total size
3.  Converts each draw back to proportions
4.  Runs the full VOTA algorithm on each simulated matrix

This produces a distribution of national estimates, capturing sampling
uncertainty.

### Bootstrap Method

When `uncertainty_method = "bootstrap"`, individual-level survey data is
resampled with replacement. Optionally, survey weights and calibration
variables can be used to produce calibrated bootstrap replicas
([`survey::calibrate()`](https://rdrr.io/pkg/survey/man/calibrate.html)).

## Provincial Projection

National estimates are projected to provinces using the
[`project_to_districts()`](https://vota.spainelectoralproject.com/reference/project_to_districts.md)
function:

1.  **Historical patterns** from `patrones_23J` define the expected
    provincial distribution of each party
2.  **Dirichlet simulation** adds variability: for each party,
    provincial shares are drawn from a Dirichlet distribution centered
    on the historical pattern, with concentration parameter `tau`
    - Higher `tau` (e.g., 500) = less provincial variability
    - Lower `tau` (e.g., 100) = more provincial variability
3.  **Multinomial allocation** distributes total national votes across
    province-party cells

``` r

data(patrones_23J)
# Provincial patterns: each party's historical vote share by province
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

## D’Hondt Seat Allocation

The
[`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)
function implements the D’Hondt method, vectorized for simultaneous
processing of all provinces and simulations:

1.  Each party’s provincial votes are divided by 1, 2, 3, …, up to the
    total number of seats
2.  Seats are assigned to the highest quotients
3.  An electoral threshold (`umbral`, default 3%) is applied – parties
    below this threshold in a district receive no seats

The threshold can be applied at three levels:

- **`provincial`** – each province independently (standard for national
  elections)
- **`autonomico`** – share calculated over the entire autonomous
  community
- **`mixto`** – party qualifies if it passes either the provincial or
  regional threshold

``` r

data(n_seats)
# 52 districts with varying number of seats
summary(n_seats$n_diputados)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   1.000   4.000   5.000   6.731   7.000  37.000
```

## The `electo_fit` Object

All results are packaged into an S3 object of class `electo_fit`, with
methods for:

- [`print()`](https://rdrr.io/r/base/print.html) – Quick overview of top
  parties by votes and seats
- [`summary()`](https://rdrr.io/r/base/summary.html) – Aggregated
  estimates with confidence intervals and win probabilities
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) – Four
  visualization types (nacional, seats_dist, provincia, dhondt_margin)

## Parameter Sensitivity

Key parameters and their effects:

| Parameter | Effect of increasing |
|----|----|
| `nsims` | More stable uncertainty estimates, slower computation |
| `tau` | Less provincial variability, tighter around historical patterns |
| `factor_correccion_abstencion` | More discounting of abstainers’ stated intentions |
| `factor_correccion_jovenes` | More discounting of new voters’ stated intentions |
| `factor_correccion_otbl` | More discounting of other/blank voters’ stated intentions |
| `tiempo_entre_elecciones` | Larger new-voter cohort, larger mortality adjustment |
| `umbral` | Higher threshold to earn seats (filters out smaller parties) |

## Pipeline Summary

    Survey Data (Excel)
           |
           v
    load_and_validate()           -- Read & validate input
           |
           v
    draw_mt() / simulate_mt()    -- Generate nsims transfer matrices
           |
           v
    vota()  [x nsims]           -- Apply 5 corrections per simulation
           |
           v
    project_to_districts()        -- National -> Provincial (Dirichlet)
           |
           v
    umbral_electoral()            -- Apply electoral threshold
           |
           v
    fast_dhondt()                 -- Allocate seats (D'Hondt)
           |
           v
    aggregate_results()           -- Medians, CIs, win probabilities
           |
           v
    new_electo_fit()              -- Package into electo_fit object

## Further Reading

- **[Getting
  Started](https://vota.spainelectoralproject.com/articles/getting-started.md)**
  – Installation and quick start
- **[Step-by-step
  Tutorial](https://vota.spainelectoralproject.com/articles/tutorial.md)**
  – Hands-on walkthrough with internal data
