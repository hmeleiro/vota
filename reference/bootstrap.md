# Bootstrapping de datos de encuesta

Genera replicas de datos de encuesta usando bootstrapping con reemplazo

## Usage

``` r
bootstrap(data, B, calib_vars, weights)
```

## Arguments

- data:

  Data frame con datos de encuesta (columnas: recuerdo, idv, ponde)

- B:

  Numero de replicas a generar

- calib_vars:

  Variables para calibracion (vector de nombres de columnas)

- weights:

  Nombre de la columna con pesos de referencia para calibracion

## Value

Data frame con replicas de datos de encuesta
