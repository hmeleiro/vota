# Cargar Datos Electorales desde Excel

Carga todos los datos necesarios desde un archivo Excel con multiples
hojas.

## Usage

``` r
load_electoral_data(
  input_path,
  uncertainty_method = c("mcmc", "bootstrap"),
  strategy = c("top_down", "bottom_up")
)
```

## Arguments

- input_path:

  Ruta al archivo Excel de entrada

- uncertainty_method:

  Tipo de datos de entrada: "mcmc" (por defecto) o "bootstrap"

## Value

Lista con todos los datos de entrada validados

## Details

Hojas requeridas en el Excel:

- partidos: codigos de partidos para recuerdo e IDV

- mt_simplificada: matrices de transferencia con fila 'N'

- patrones: patrones historicos por provincia

- anteriores_elecciones: resultados electorales anteriores

- n_diputados: escanos por provincia

- retoques: ajustes manuales (opcional)

- small_parties: partidos pequenos (opcional)
