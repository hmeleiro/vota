# vota <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/vota)](https://CRAN.R-project.org/package=vota)
[![pkgdown](https://github.com/hmeleiro/vota/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/hmeleiro/vota/actions/workflows/pkgdown.yaml)
[![License: GPL (>= 3)](https://img.shields.io/badge/License-GPL%20(%3E%3D%203)-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

[Read in English](README.md)

**vota** es un paquete de R para simular resultados electorales en España. Proyecta datos de encuestas nacionales a asignaciones de escaños provinciales usando matrices de transferencia, métodos Monte Carlo y bootstrapping. Implementa el algoritmo *VOTA* (**V**ote **O**utcome **T**ransfer-based **A**lgorithm), específicamente diseñado para el sistema electoral español con el método D'Hondt.

## Instalación

Puedes instalar la versión de desarrollo desde GitHub:

```r
# install.packages("devtools")
devtools::install_github("hmeleiro/vota")
```

## Visión general

El paquete implementa un pipeline completo de simulación electoral:

1. **Carga y validación de datos** -- Lectura de Excel multi-hoja y validación de consistencia entre hojas
2. **Simulación de matriz de transferencia** -- Generación de incertidumbre vía MCMC (remuestreo multinomial) o bootstrap
3. **Algoritmo VOTA** -- Aplicación de cinco correcciones secuenciales (abstención, nuevos votantes, redistribución de indecisos, partidos pequeños, ajustes manuales)
4. **Proyección provincial** -- Proyección de estimaciones nacionales a provincias usando patrones históricos de voto y simulación Dirichlet
5. **Asignación de escaños D'Hondt** -- Asignación vectorizada de escaños en todas las provincias y simulaciones
6. **Agregación y reporting** -- Intervalos de confianza, probabilidad de victoria y visualizaciones

## Inicio Rápido

### Crear un proyecto

```r
library(vota)

# Crear un nuevo proyecto electoral con plantillas
setup_electoral_project("mi_simulacion")
# Crea: input/input.xlsx, output/, scripts/main.R
```

### Ejecutar una simulación

```r
# Ejecutar el pipeline completo
resultados <- run_vota(
  input_path = "input/input.xlsx",
  output_file = "output/resultados.rds",
  uncertainty_method = "mcmc",
  nsims = 100,
  seed = 42
)

# Inspeccionar resultados
print(resultados)
summary(resultados)
```

### Visualizar resultados

```r
# Estimaciones de voto nacional con intervalos de confianza
plot(resultados, "nacional")

# Distribución de escaños en las simulaciones
plot(resultados, "seats_dist")

# Escaños por provincia para un partido específico
plot(resultados, "provincia", partido = "PP")

# Análisis de margen D'Hondt (fragilidad de escaños)
plot(resultados, "dhondt_margin")
```

## Datasets Incluidos

El paquete incluye datos de ejemplo de las elecciones generales españolas del 23 de julio de 2023 (23J):

| Dataset | Descripción |
|---|---|
| `mt` | Matriz de transferencia de ejemplo (recuerdo x intención de voto) |
| `votos_23J` | Resultados oficiales de votos de las elecciones 23J |
| `patrones_23J` | Patrones históricos de voto por provincia (23J) |
| `n_seats` | Número de escaños por provincia española (52 circunscripciones) |
| `retoques` | Ejemplo de ajustes manuales |
| `small_parties` | Ejemplo de estimaciones de partidos pequeños |

```r
# Explorar los datos incluidos
data(mt)
data(votos_23J)
data(patrones_23J)
data(n_seats)
```

## Funciones Principales

| Función | Propósito |
|---|---|
| `run_vota()` | Ejecutar el pipeline completo de simulación |
| `vota()` | Algoritmo VOTA central con 5 correcciones |
| `fast_dhondt()` | Asignación de escaños D'Hondt vectorizada |
| `simulate_mt()` | Simulaciones Monte Carlo de matrices de transferencia |
| `simulate_prov_votes()` | Simulaciones de voto provincial (Dirichlet/logit-normal) |
| `draw_mt()` | Orquestar la generación de matrices de transferencia |
| `project_to_districts()` | Proyectar estimaciones nacionales a provincias |
| `setup_electoral_project()` | Crear estructura de un nuevo proyecto |
| `create_input_template()` | Generar plantilla Excel de entrada |
| `plot.electo_fit()` | Visualizar resultados de simulación |
| `summary.electo_fit()` | Estadísticos resumen y probabilidades de victoria |

## Formato de Datos de Entrada

La simulación espera un archivo Excel (`.xlsx`) con estas hojas:

| Hoja | Columnas Requeridas | Descripción |
|---|---|---|
| `partidos` | `recuerdo`, `idv` | Mapeo de códigos de partidos (recuerdo → intención) |
| `mt_simplificada` | `idv` + columnas de partidos | Matriz de transferencia con fila `N` para tamaños de muestra |
| `patrones` | `codigo_provincia`, columnas de partidos | Patrones de voto provincial (proporciones) |
| `anteriores_elecciones` | `recuerdo`, `votos_ant` | Resultados de la elección anterior |
| `n_diputados` | `codigo_provincia`, `n_diputados` | Escaños por provincia |
| `retoques` (opcional) | `idv`, `votos_adicionales` | Ajustes manuales de votos |
| `small_parties` (opcional) | `idv`, `votos` | Estimaciones de voto de partidos pequeños |

Usa `create_input_template()` para generar una plantilla correctamente formateada con datos de ejemplo.

## Parámetros

Parámetros clave de `run_vota()`:

| Parámetro | Por defecto | Descripción |
|---|---|---|
| `uncertainty_method` | `"mcmc"` | `"mcmc"` o `"bootstrap"` |
| `strategy` | `"top_down"` | `"top_down"` o `"bottom_up"` |
| `nsims` | `100` | Número de simulaciones Monte Carlo |
| `factor_correccion_abstencion` | `3` | Factor de corrección por abstención |
| `factor_correccion_jovenes` | `2.5` | Factor de corrección por nuevos votantes |
| `factor_correccion_otbl` | `3` | Factor de corrección por voto otros/blanco |
| `tiempo_entre_elecciones` | `0.1` | Años entre elecciones (ajuste demográfico) |
| `tau` | `300` | Concentración Dirichlet para proyección provincial |
| `umbral` | `0.03` | Umbral mínimo de voto para asignación de escaños (3%) |
| `tipo_umbral` | `"provincial"` | Tipo de umbral: `"provincial"`, `"autonomico"` o `"mixto"` |
| `interval_level` | `0.9` | Nivel de confianza para intervalos de incertidumbre |
| `seed` | `NULL` | Semilla para reproducibilidad |

## Viñetas

- [Primeros pasos](vignettes/primeros-pasos.Rmd) / [Getting Started](vignettes/getting-started.Rmd)
- [Metodología VOTA](vignettes/metodologia.Rmd) / [The VOTA Methodology](vignettes/methodology.Rmd)
- [Tutorial paso a paso](vignettes/tutorial-es.Rmd) / [Step-by-step Tutorial](vignettes/tutorial.Rmd)

## Licencia

MIT
