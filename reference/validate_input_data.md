# Validate Input Data

Validates the consistency and completeness of all input data for the
electoral pipeline.

## Usage

``` r
validate_input_data(
  data_list,
  recuerdo_lvls,
  idv_lvls,
  uncertainty_method = c("mcmc", "bootstrap"),
  strategy = c("top_down", "bottom_up")
)
```

## Arguments

- data_list:

  List with data loaded from Excel

- recuerdo_lvls:

  Vector with valid recuerdo codes

- idv_lvls:

  Vector with valid IDV codes

- uncertainty_method:

  Type of input data: "mcmc" or "bootstrap"

- strategy:

  Modeling strategy: "top_down" or "bottom_up"

## Value

TRUE if all data is valid, or stops execution with error

## Details

Performs the following validations:

- Verifies presence of required elements in data_list

- Validates party codes in transfer matrices

- Verifies consistency between provincial patterns and IDV codes

- Validates previous election data

- Verifies province correspondence between seats and patterns sheets

- Validates adjustments and small parties if present

## See also

Other data-functions:
[`draw_mt()`](https://vota.spainelectoralproject.com/reference/draw_mt.md),
[`load_and_validate()`](https://vota.spainelectoralproject.com/reference/load_and_validate.md)
