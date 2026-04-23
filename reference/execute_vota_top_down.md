# Execute VOTA algorithm using top-down strategy This function executes the VOTA algorithm using a top-down approach. It processes the simulated transfer matrices and applies the VOTA corrections to estimate national vote shares.

Execute VOTA algorithm using top-down strategy This function executes
the VOTA algorithm using a top-down approach. It processes the simulated
transfer matrices and applies the VOTA corrections to estimate national
vote shares.

## Usage

``` r
execute_vota_top_down(
  mt_sims,
  factor_correccion_abstencion,
  factor_correccion_jovenes,
  factor_correccion_otbl,
  tiempo_entre_elecciones,
  retoques,
  small_parties,
  votos_ant,
  ...
)
```

## Arguments

- mt_sims:

  Data frame with simulated transfer matrices.

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

- ...:

  Additional arguments (not used)

## Value

A list containing the estimated national vote shares and the adjusted
transfer matrices.
