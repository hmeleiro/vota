# VOTA: Vote Outcome Transfer-based Algorithm

Applies the central electoral projection algorithm with corrections of
abstention, new voters and redistribution of undecided voters to the
probability transfer matrix.

## Usage

``` r
vota(
  mt_simplificada,
  tiempo_entre_elecciones = 4,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  retoques = NULL,
  small_parties = NULL,
  votos_ant
)
```

## Arguments

- mt_simplificada:

  Data frame with transfer matrix with columns recuerdo, idv, transfer

- tiempo_entre_elecciones:

  Years between elections for demographic adjustments (default 4)

- factor_correccion_abstencion:

  Abstention correction factor (default 3)

- factor_correccion_jovenes:

  New voters correction factor (default 2.5)

- factor_correccion_otbl:

  Other blank/null votes correction factor (default 2.5)

- retoques:

  Optional data frame with manual adjustments (column votos_adicionales)

- small_parties:

  Optional data frame with small party votes

- votos_ant:

  Data frame with previous electoral results (column votos_ant)

## Value

Data frame with national vote estimates by party

## Details

The VOTA algorithm implements the following corrections:

1.  Abstention correction: adjusts votes from those who abstained in
    previous elections

2.  New voters correction: adjusts votes from those not of age in
    previous elections

3.  Undecided redistribution: distributes according to transfer patterns
    the votes of undecided voters

4.  Small parties incorporation: adds external estimates for small
    parties not included in the transfer matrix or dificult to model

5.  Manual adjustments application: manual discretionary expert
    adjustments to the estimates based on additional information or
    judgement

## See also

Other main-functions:
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)

Other core-algorithms:
[`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)
