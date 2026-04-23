# vota: Vote Outcome Transfer-based Algorithm

The vota package implements the VOTA (Vote Outcome Transfer-based
Algorithm) for simulating Spanish electoral outcomes using transfer
matrices and Monte Carlo methods. It transforms national survey data
into provincial seat assignments via the D'Hondt method, with built-in
corrections for abstention, new voters, and manual adjustments.

## Main Functions

The core simulation pipeline:

- [`run_vota`](https://vota.spainelectoralproject.com/reference/run_vota.md):

  Execute complete electoral simulation pipeline

- [`vota`](https://vota.spainelectoralproject.com/reference/vota.md):

  Core electoral projection algorithm

- [`fast_dhondt`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md):

  Vectorized D'Hondt seat allocation

## Data Processing Functions

Load, validate and prepare electoral data:

- [`load_and_validate`](https://vota.spainelectoralproject.com/reference/load_and_validate.md):

  Load and validate Excel input data

- [`validate_input_data`](https://vota.spainelectoralproject.com/reference/validate_input_data.md):

  Comprehensive data validation

- [`draw_mt`](https://vota.spainelectoralproject.com/reference/draw_mt.md):

  Generate transfer matrix simulations

## Project Setup Functions

Initialize and configure electoral projects:

- [`setup_electoral_project`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md):

  Create project directory structure

- [`create_input_template`](https://vota.spainelectoralproject.com/reference/create_input_template.md):

  Generate Excel template files

## Visualization Functions

Display and format simulation results:

- [`plot.electo_fit`](https://vota.spainelectoralproject.com/reference/plot.electo_fit.md):

  Generate plots from simulation results

## Key Features

- Monte Carlo uncertainty quantification

- Provincial projection with historical patterns

- Demographic corrections (abstention, new voters)

- Manual adjustment capabilities

- Professional visualization and reporting

- Comprehensive input validation

## Workflow

A typical electoral simulation workflow:

1.  Use
    [`setup_electoral_project`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md)
    to create project structure

2.  Edit the generated Excel template with your data

3.  Run
    [`run_vota`](https://vota.spainelectoralproject.com/reference/run_vota.md)
    to execute the simulation

4.  Analyze results using
    [`plot.electo_fit`](https://vota.spainelectoralproject.com/reference/plot.electo_fit.md)
    and
    [`summary.electo_fit`](https://vota.spainelectoralproject.com/reference/summary.electo_fit.md)

## Data Requirements

The package requires an Excel file with specific sheets:

- **partidos**: Party codes for recuerdo and IDV

- **mt_simplificada**: Transfer matrices with 'N' row

- **patrones**: Historical patterns by province

- **anteriores_elecciones**: Previous electoral results

- **n_diputados**: Seats per province

- **retoques**: Manual adjustments (optional)

- **small_parties**: Small parties data (optional)

## Autor-a

**Maintainer**: HÃ©ctor Meleiro <hmeleiros@gmail.com>
