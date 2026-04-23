# Set up electoral project

Creates directory structure and template files for a new electoral
project.

## Uso

``` r
setup_electoral_project(project_dir)
```

## Argumentos

- project_dir:

  Project directory (will be created if it doesn't exist)

## Valor

Invisible(NULL). Function is executed for its side effects.

## Detalles

This function:

- Creates input/, output/ and scripts/ folders

- Generates an Excel file with all sheets required by the pipeline

- Creates a main example script in scripts/main.R

## Ver también

Other utility-functions:
[`create_input_template()`](https://vota.spainelectoralproject.com/reference/create_input_template.md)

Other project-setup:
[`create_input_template()`](https://vota.spainelectoralproject.com/reference/create_input_template.md)

## Ejemplos

``` r
if (FALSE) { # \dontrun{
setup_electoral_project("my_simulation_2023")
} # }
```
