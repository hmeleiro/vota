# Validate Vote Transfer Matrix

Validates that party codes in the transfer matrix correspond to expected
categories.

## Usage

``` r
check_mt(mt, recuerdo_lvls, idv_lvls)
```

## Arguments

- mt:

  Data frame with transfer matrix

- recuerdo_lvls:

  Vector with valid recuerdo codes

- idv_lvls:

  Vector with valid IDV codes

## Value

Invisible(TRUE) if valid, or error if not
