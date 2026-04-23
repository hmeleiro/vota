# Copilot Instructions for vota

## Project Overview

- **vota** is an R package for simulating Spanish electoral outcomes
  using transfer matrices and Monte Carlo methods.
- The pipeline transforms national survey data into provincial seat
  assignments via the D’Hondt method, with built-in corrections for
  abstention, new voters, and manual adjustments.

## Key Architecture & Data Flow

- **Main pipeline:**
  1.  Excel input (multi-sheet)
  2.  Data validation (`validate_input_data`)
  3.  Monte Carlo simulations of transfer matrices (`simulate_mt`)
  4.  Central projection algorithm (`vota`)
  5.  Provincial projection
  6.  D’Hondt seat assignment (`fast_dhondt`)
  7.  Results aggregation
- **Core functions:**
  - `run_vota`: Orchestrates the full pipeline
  - `vota`: Implements sequential corrections and projections
  - `fast_dhondt`: Vectorized seat allocation
  - `simulate_mt`, `load_electoral_data`, `validate_input_data`: Data
    prep and simulation
- **Data conventions:**
  - Input is a single Excel file with 7+ sheets (see README for details)
  - Party codes and transfer matrices are regionally flexible; avoid
    hardcoding party names

## Developer Workflows

- **Build/Reload:** Use `devtools::load_all("path/to/vota")` for local
  development
- **Testing:**
  - Run all tests:
    [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
  - Run specific test:
    `testthat::test_file("tests/testthat/test-core-functions.R")`
  - Coverage:
    [`covr::package_coverage()`](http://covr.r-lib.org/reference/package_coverage.md)
- **Project setup:**
  - Use
    [`setup_electoral_project()`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md)
    to scaffold new simulations
  - Use
    [`create_input_template()`](https://vota.spainelectoralproject.com/reference/create_input_template.md)
    to generate Excel templates

## Project-Specific Patterns

- **Corrections:** Five sequential corrections in `vota` (abstention,
  new voters, indecisive redistribution, small parties, manual tweaks)
- **Vectorization:** All major computations (especially D’Hondt) are
  vectorized for performance
- **Validation:** Automatic consistency checks between Excel sheets
- **Regionalization:** All party codes and transfer logic are
  parameterized for reuse across elections/regions

## Directory Structure

- `R/`: Source code (see `run_vota.R`, `vota.R`, `fast_dhondt.R`)
- `data/`: Example datasets
- `tests/`: Unit tests (testthat)
- `man/`: Function documentation
- `vignettes/`: Extended documentation

## Integration Points

- **External dependencies:** Relies on R packages: `devtools`,
  `testthat`, `covr`, and Excel reading/writing packages
- **No hardcoded party names:** Always use codes from input files
- **Results:** Output is structured as lists with national/provincial
  estimates and metadata

## Example: Minimal Simulation

``` r

resultados <- run_vota(
  input_path = "input/input.xlsx",
  nsims_mt = 10,
  nsims_prov = 100
)
```

## Tips for AI Agents

- Always validate input data before running simulations
- Use provided setup and template functions for new projects
- Reference README and vignettes for advanced usage and edge cases
- Prefer vectorized operations and avoid hardcoding region/party
  specifics

------------------------------------------------------------------------

If any section is unclear or missing, please provide feedback to improve
these instructions.
