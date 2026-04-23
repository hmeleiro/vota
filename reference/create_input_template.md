# Crear plantilla de archivos de entrada

Genera un archivo Excel con todas las hojas necesarias para el analisis
electoral.

## Usage

``` r
create_input_template(file_path = "input/input.xlsx")
```

## Arguments

- file_path:

  Path of Excel file to create

## Value

Returns (invisibly) path to created file

## Details

Sheets created and minimum columns required by package:

- partidos: idv, recuerdo

- mt_simplificada: idv + recuerdo columns + 'N' row

- patrones: codigo_provincia + party columns (percentage 0-100)

- anteriores_elecciones: recuerdo, votos_ant

- n_diputados: codigo_provincia, n_diputados

- retoques: idv, votos_adicionales

- small_parties: idv, votos

## See also

Other utility-functions:
[`setup_electoral_project()`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md)

Other project-setup:
[`setup_electoral_project()`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md)
