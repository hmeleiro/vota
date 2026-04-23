# Primeros pasos con vota

## Introducción

**vota** es un paquete de R para simular resultados electorales en
España. Partiendo de datos de encuesta nacionales (matrices de
transferencia), proyecta las intenciones de voto a asignaciones de
escaños provinciales usando el método D’Hondt – el mismo sistema de
reparto utilizado en las elecciones españolas.

Esta viñeta te guía a través de la configuración básica y una simulación
mínima usando los datasets incluidos en el paquete.

## Instalación

``` r

# Instalar desde GitHub
devtools::install_github("hmeleiro/vota")
```

``` r

library(vota)
```

## Datasets Incluidos

El paquete incluye datos reales de las elecciones generales españolas
del 23 de julio de 2023. Estos datasets sirven tanto como ejemplos como
entradas listas para usar:

### Matriz de transferencia (`mt`)

La matriz de transferencia captura cómo los votantes de la última
elección piensan votar ahora. Cada fila representa una combinación de
recuerdo de voto (`recuerdo`) e intención de voto actual (`idv`), junto
con el porcentaje de transferencia entre ambos.

``` r

data(mt)
head(mt)
#> # A tibble: 6 × 8
#>   idv       PSOE     PP    Vox  Sumar  OTBL   ABNL `<18`
#>   <chr>    <dbl>  <dbl>  <dbl>  <dbl> <dbl>  <dbl> <dbl>
#> 1 PSOE    67.7    0.898  0     11.4    4.95 10.4   17.2 
#> 2 PP       2.57  68.8    3.68   1.31   5.48  8.62   6.87
#> 3 Vox      1.28  12.7   78.4    0.106  2.11 11.5   19.2 
#> 4 Sumar    2.81   0      0.586 37.4    2.34  1.29   4.30
#> 5 Podemos  1.22   0      0.110 22.5    2.30  0.872  1.34
#> 6 ERC      0.187  0      0      1.04  10.9   0.365  1.33
```

### Resultados de la elección anterior (`votos_23J`)

Totales oficiales de votos de las elecciones 23J, usados como base para
los ajustes demográficos y la redistribución de votantes.

``` r

data(votos_23J)
votos_23J
#> # A tibble: 6 × 2
#>   recuerdo votos_ant
#>   <chr>        <dbl>
#> 1 PSOE       7760970
#> 2 PP         8091840
#> 3 Vox        3033744
#> 4 Sumar      3014006
#> 5 OTBL       2581974
#> 6 ABNL      10663528
```

### Patrones de voto provincial (`patrones_23J`)

Distribuciones históricas de voto por provincia, usadas para proyectar
estimaciones nacionales al nivel provincial.

``` r

data(patrones_23J)
head(patrones_23J)
#> # A tibble: 6 × 17
#>   codigo_provincia  PSOE    PP   Vox Sumar   ERC Junts   CUP   PNV `EH Bildu`
#>   <chr>            <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>      <dbl>
#> 1 01               0.599 0.373 0.210 0.710     0     0     0  10.1       9.85
#> 2 02               0.979 1.10  1.18  0.520     0     0     0   0         0   
#> 3 03               3.69  4.09  4.70  3.81      0     0     0   0         0   
#> 4 04               1.19  1.63  2.19  0.701     0     0     0   0         0   
#> 5 05               0.341 0.524 0.484 0.164     0     0     0   0         0   
#> 6 06               1.97  1.84  1.72  0.882     0     0     0   0         0   
#> # ℹ 7 more variables: UPN <dbl>, BNG <dbl>, CCa <dbl>, SALF <dbl>,
#> #   Podemos <dbl>, OTBL <dbl>, ABNL <dbl>
```

### Escaños por provincia (`n_seats`)

El número de escaños al Congreso asignados a cada una de las 52
circunscripciones electorales de España.

``` r

data(n_seats)
head(n_seats)
#> # A tibble: 6 × 2
#>   codigo_provincia n_diputados
#>   <chr>                  <dbl>
#> 1 01                         4
#> 2 02                         4
#> 3 03                        12
#> 4 04                         6
#> 5 05                         3
#> 6 06                         5
```

### Ajustes manuales (`retoques`)

Ajustes discrecionales opcionales – sumar o restar votos a partidos
específicos basándose en conocimiento externo.

``` r

data(retoques)
retoques
#> # A tibble: 2 × 2
#>   idv   votos_adicionales
#>   <chr>             <dbl>
#> 1 Vox             -230000
#> 2 CCa               24000
```

### Partidos pequeños (`small_parties`)

Estimaciones de voto para partidos demasiado pequeños para modelar en la
matriz de transferencia pero relevantes para el resultado global.

``` r

data(small_parties)
small_parties
#> # A tibble: 3 × 2
#>   idv    votos
#>   <chr>  <dbl>
#> 1 BNG   152327
#> 2 CCa   114718
#> 3 UPN    51764
```

## Crear un Proyecto

La forma más fácil de iniciar una simulación es crear una estructura de
proyecto:

``` r

setup_electoral_project("mi_simulacion_2024")
```

Esto crea:

- `input/input.xlsx` – Una plantilla Excel pre-rellenada con datos de
  ejemplo
- `output/` – Directorio para los resultados de la simulación
- `scripts/main.R` – Un script de inicio

Alternativamente, puedes generar solo la plantilla Excel:

``` r

create_input_template("input/input.xlsx")
```

## Ejecutar una Simulación

Una vez que tengas tus datos de entrada en un archivo Excel, ejecuta el
pipeline completo con
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md):

``` r

resultados <- run_vota(
  input_path = "input/input.xlsx",
  output_file = "output/resultados.rds",
  uncertainty_method = "mcmc",
  nsims = 100,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  tiempo_entre_elecciones = 0.1,
  tau = 300,
  umbral = 0.03,
  seed = 42,
  verbose = TRUE
)
```

La función devuelve un objeto `electo_fit` que contiene:

- **`estimacion`** – Estimaciones nacionales con intervalos de confianza
  (% de voto y escaños)
- **`estimacion_sims`** – Todos los resultados de simulación
- **`estimacion_provincias_sims`** – Resultados de simulación a nivel
  provincial
- **`dhondt_output`** – Asignación detallada de D’Hondt
- **`mt_sims_pct`** / **`mt_sims_electores`** – Simulaciones de la
  matriz de transferencia
- **`participacion_media`** – Participación media estimada
- **`metadata`** – Parámetros de ejecución

## Inspeccionar Resultados

``` r

# Vista rápida
print(resultados)

# Resumen detallado con probabilidades de victoria
summary(resultados)

# Acceder a la tabla de estimaciones nacionales
resultados$estimacion
```

## Visualizar Resultados

El objeto `electo_fit` tiene un método
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) dedicado con
cuatro tipos de visualización:

``` r

# Porcentajes de voto nacionales con intervalos de confianza
plot(resultados, "nacional")

# Distribución de escaños en las simulaciones (por partido)
plot(resultados, "seats_dist")

# Escaños por provincia para un partido específico
plot(resultados, "provincia", partido = "PP")

# Fragilidad de escaños: margen del último cociente D'Hondt
plot(resultados, "dhondt_margin")
```

## Siguientes Pasos

- **[Metodología
  VOTA](https://vota.spainelectoralproject.com/articles/metodologia.md)**
  – Entiende las cinco correcciones y el modelo estadístico
- **[Tutorial paso a
  paso](https://vota.spainelectoralproject.com/articles/tutorial-es.md)**
  – Recorre cada función del pipeline usando los datasets internos
