# Leer Matriz de Transferencia

Lee la matriz de transferencia desde la hoja 'mt_simplificada' del
archivo Excel y la procesa para uso en simulaciones.

## Usage

``` r
read_mt(path, recuerdo_lvls, idv_lvls)
```

## Arguments

- path:

  Ruta al archivo Excel

- recuerdo_lvls:

  Vector con codigos de recuerdo validos

- idv_lvls:

  Vector con codigos IDV validos

## Value

Data frame con matriz de transferencia procesada con columnas: recuerdo,
idv, n (numero de encuestados)

## Details

La hoja 'mt_simplificada' debe contener:

- Columna 'idv' con codigos de intencion de voto

- Columnas con codigos de recuerdo (porcentajes)

- Fila 'N' con tamanos de muestra por columna de recuerdo
