# Execute VOTA algorithm using bottom-up strategy This function executes the VOTA algorithm using a bottom-up approach. It processes the simulated transfer matrices and applies the VOTA corrections to estimate national vote shares.

Execute VOTA algorithm using bottom-up strategy This function executes
the VOTA algorithm using a bottom-up approach. It processes the
simulated transfer matrices and applies the VOTA corrections to estimate
national vote shares.

## Usage

``` r
execute_vota_bottom_up(
  mt_sims,
  district_col,
  factor_correccion_abstencion,
  factor_correccion_jovenes,
  factor_correccion_otbl,
  tiempo_entre_elecciones,
  retoques,
  small_parties,
  votos_ant
)
```

## Arguments

- mt_sims:

  Data frame with simulated transfer matrices.

- district_col:

  Name of column in survey_data indicating province or electoral
  district

- factor_correccion_abstencion:

  Correction factor for abstention.

- factor_correccion_jovenes:

  Correction factor for new voters.

- factor_correccion_otbl:

  Correction factor for other blank/null votes.

- tiempo_entre_elecciones:

  Years between elections for demographic adjustments.

- retoques:

  Data frame with adjustments to be applied.

- small_parties:

  Data frame with small party votes.

- votos_ant:

  Data frame with previous electoral results (column votos_ant).

## Value

A list containing the estimated national vote shares and the adjusted
transfer matrices.
