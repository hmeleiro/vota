# Cargar Datos Electorales Bottom-Down desde Excel

Carga todos los datos necesarios desde un archivo Excel con multiples
hojas

## Uso

``` r
load_electoral_data_bottom_up(input_path, uncertainty_method)
```

## Argumentos

- input_path:

  Ruta al archivo Excel de entrada

- uncertainty_method:

  Solo puede ser "bootstrap"

## Valor

Lista con todos los datos de entrada validados

## Detalles

Hojas requeridas en el Excel:

- anteriores_elecciones: resultados electorales anteriores

- n_diputados: escanos por provincia

- retoques: ajustes manuales (opcional)

- small_parties: partidos pequenos (opcional)
