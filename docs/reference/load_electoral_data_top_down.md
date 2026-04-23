# Cargar Datos Electorales Top-Down desde Excel

Carga todos los datos necesarios desde un archivo Excel con multiples
hojas

## Uso

``` r
load_electoral_data_top_down(
  input_path,
  uncertainty_method = c("mcmc", "bootstrap")
)
```

## Argumentos

- input_path:

  Ruta al archivo Excel de entrada

- uncertainty_method:

  Tipo de datos de entrada: "mcmc" (por defecto) o "bootstrap"

## Valor

Lista con todos los datos de entrada validados

## Detalles

Hojas requeridas en el Excel:

- partidos: codigos de partidos para recuerdo e IDV

- mt_simplificada: matrices de transferencia con fila 'N' (solo
  necesario si uncertainty_method es "mcmc")

- patrones: patrones historicos por provincia

- anteriores_elecciones: resultados electorales anteriores

- n_diputados: escanos por provincia

- retoques: ajustes manuales (opcional)

- small_parties: partidos pequenos (opcional)
