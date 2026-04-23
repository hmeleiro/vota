# Load and validate electoral data from Excel

Loads all necessary data from an Excel file with multiple sheets,
validates it, and returns input data in a list.

## Usage

``` r
load_and_validate(input_path, uncertainty_method, strategy, verbose = TRUE)
```

## Arguments

- input_path:

  Path to input Excel file

- uncertainty_method:

  Type of input data: "mcmc" or "bootstrap"

- strategy:

  Modeling strategy: "top_down" or "bottom_up"

- verbose:

  Show progress messages (default TRUE)

## Value

List with all validated input data

## Details

Required sheets in Excel:

- partidos: party codes for recuerdo and IDV

- mt_simplificada: transfer matrices with 'N' row

- patrones: historical patterns by province

- anteriores_elecciones: previous electoral results

- n_diputados: seats per province

- retoques: manual adjustments (optional)

- small_parties: small parties (optional)

## See also

Other data-functions:
[`draw_mt()`](https://vota.spainelectoralproject.com/reference/draw_mt.md),
[`validate_input_data()`](https://vota.spainelectoralproject.com/reference/validate_input_data.md)
