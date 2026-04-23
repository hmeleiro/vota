# Tutorial paso a paso

## Introducción

Este tutorial recorre el pipeline de vota paso a paso, usando únicamente
los datasets incluidos en el paquete. En lugar de ejecutar
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
como una caja negra, llamaremos a cada función individualmente para
entender qué ocurre en cada etapa.

``` r
library(vota)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(tidyr)
```

## Paso 1: Explorar los Datos Internos

### La Matriz de Transferencia

El dataset `mt` es un ejemplo de matriz de transferencia en formato
ancho. Cada fila es un partido de intención de voto (`idv`), y cada
columna es un partido de recuerdo de voto anterior. La última fila
(`idv == "n"`) proporciona el tamaño de muestra para cada columna
(recuerdo de voto).

``` r
data(mt)
mt
#> # A tibble: 15 × 8
#>    idv            PSOE      PP     Vox   Sumar    OTBL     ABNL  `<18`
#>    <chr>         <dbl>   <dbl>   <dbl>   <dbl>   <dbl>    <dbl>  <dbl>
#>  1 PSOE        67.7      0.898   0      11.4     4.95   10.4     17.2 
#>  2 PP           2.57    68.8     3.68    1.31    5.48    8.62     6.87
#>  3 Vox          1.28    12.7    78.4     0.106   2.11   11.5     19.2 
#>  4 Sumar        2.81     0       0.586  37.4     2.34    1.29     4.30
#>  5 Podemos      1.22     0       0.110  22.5     2.30    0.872    1.34
#>  6 ERC          0.187    0       0       1.04   10.9     0.365    1.33
#>  7 SALF         0.156    0.817   7.76    0       0.620   1.24     0   
#>  8 Junts        0.0382   0       0       0       5.76    0.0915   0   
#>  9 PNV          0.0487   0       0       0       3.05    0        0   
#> 10 EH Bildu     0.183    0       0       0.433   5.51    0.692    0   
#> 11 CCa          0.0480   0       0       0       0.564   0        0   
#> 12 OTBL         5.11     5.79    1.62    7.92   32.0     6.85    12.1 
#> 13 ABNL         3.45     2.05    2.71    1.23    4.12   44.4     17.1 
#> 14 Indecisos   15.2      9.02    5.12   16.6    20.3    13.7     20.6 
#> 15 N         1188.     771.    390.    423.    354.    547.     119.
```

Las columnas representan partidos de la elección *anterior* (recuerdo):
PSOE, PP, Vox, Sumar, OTBL (otros/blanco) y ABNL (abstención/nulo). La
columna `idv` muestra a quién piensan votar ahora estos votantes. Por
ejemplo, la fila donde `idv = "PP"` muestra cuántos votantes de cada
partido anterior ahora tienen intención de votar PP.

### Resultados de la Elección Anterior

`votos_23J` contiene los votos totales oficiales por partido de las
elecciones del 23J 2023:

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

Estos totales se usan para convertir los porcentajes de transferencia en
recuentos absolutos de votos.

### Patrones Provinciales

`patrones_23J` contiene la cuota histórica de voto de cada partido por
provincia (como proporción entre 0 y 1):

``` r
data(patrones_23J)
head(patrones_23J, 12)
#> # A tibble: 12 × 17
#>    codigo_provincia   PSOE    PP   Vox  Sumar   ERC Junts   CUP   PNV `EH Bildu`
#>    <chr>             <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>      <dbl>
#>  1 01                0.599 0.373 0.210  0.710   0     0     0    10.1       9.85
#>  2 02                0.979 1.10  1.18   0.520   0     0     0     0         0   
#>  3 03                3.69  4.09  4.70   3.81    0     0     0     0         0   
#>  4 04                1.19  1.63  2.19   0.701   0     0     0     0         0   
#>  5 05                0.341 0.524 0.484  0.164   0     0     0     0         0   
#>  6 06                1.97  1.84  1.72   0.882   0     0     0     0         0   
#>  7 07                1.95  2.22  2.46   2.76    0     0     0     0         0   
#>  8 08               12.2   4.53  6.46  13.4    70.5  65.3  67.5   0         0   
#>  9 09                0.890 1.02  0.825  0.572   0     0     0     0         0   
#> 10 10                1.17  1.11  1.03   0.536   0     0     0     0         0   
#> 11 11                2.71  2.75  3.11   2.71    0     0     0     0         0   
#> 12 12                1.29  1.34  1.57   1.45    0     0     0     0         0   
#> # ℹ 7 more variables: UPN <dbl>, BNG <dbl>, CCa <dbl>, SALF <dbl>,
#> #   Podemos <dbl>, OTBL <dbl>, ABNL <dbl>

# ¿Cuántas provincias y partidos?
cat("Provincias:", length(unique(patrones_23J$codigo_provincia)), "\n")
#> Provincias: 52
cat("Partidos:", length(unique(patrones_23J$partido)), "\n")
#> Warning: Unknown or uninitialised column: `partido`.
#> Partidos: 0
```

### Escaños por Provincia

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
cat("Total escaños:", sum(n_seats$n_diputados), "\n")
#> Total escaños: 350
```

### Opcional: Ajustes y Partidos Pequeños

``` r
data(retoques)
retoques
#> # A tibble: 2 × 2
#>   idv   votos_adicionales
#>   <chr>             <dbl>
#> 1 Vox             -230000
#> 2 CCa               24000

data(small_parties)
small_parties
#> # A tibble: 3 × 2
#>   idv    votos
#>   <chr>  <dbl>
#> 1 BNG   152327
#> 2 CCa   114718
#> 3 UPN    51764
```

## Paso 2: Preparar la Matriz de Transferencia

La función
[`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md)
necesita la matriz de transferencia en formato largo con columnas
`recuerdo`, `idv`, `n` y `pct_original`. Vamos a prepararla desde el
dataset `mt` en formato ancho.

``` r
# Convertir mt ancha a formato largo
party_cols <- setdiff(names(mt), c("idv", "n"))

mt_long_raw <- 
  mt %>%
  pivot_longer(
    cols = party_cols,
    names_to = "recuerdo",
    values_to = "pct_original"
  ) 
#> Warning: Using an external vector in selections was deprecated in tidyselect 1.1.0.
#> ℹ Please use `all_of()` or `any_of()` instead.
#>   # Was:
#>   data %>% select(party_cols)
#> 
#>   # Now:
#>   data %>% select(all_of(party_cols))
#> 
#> See <https://tidyselect.r-lib.org/reference/faq-external-vector.html>.
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

mt_long <- 
  mt_long_raw %>% 
  filter(idv != "N") %>% 
  left_join(
    mt_long_raw %>% 
      filter(idv == "N") %>% 
      select(recuerdo, n = pct_original), 
    by = join_by(recuerdo)
  ) %>%
  select(recuerdo, idv, n, pct_original)

head(mt_long)
#> # A tibble: 6 × 4
#>   recuerdo idv       n pct_original
#>   <chr>    <chr> <dbl>        <dbl>
#> 1 PSOE     PSOE  1188.       67.7  
#> 2 PP       PSOE   771.        0.898
#> 3 Vox      PSOE   390.        0    
#> 4 Sumar    PSOE   423.       11.4  
#> 5 OTBL     PSOE   354.        4.95 
#> 6 ABNL     PSOE   547.       10.4
```

La columna `pct_original` contiene el porcentaje de transferencia para
cada par recuerdo-idv, y `n` contiene el número de encuestados en esa
celda.

## Paso 3: Simular Matrices de Transferencia

Usando
[`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md),
generamos múltiples matrices de transferencia simuladas mediante
remuestreo multinomial. Cada simulación extrae de la distribución
muestral, creando variabilidad natural.

``` r
mt_sims <- simulate_mt(mt_long, nsims = 5, seed = 42)

# sim = 0 es la matriz original (sin perturbar)
head(mt_sims)
#> # A tibble: 6 × 5
#>     sim recuerdo idv       n transfer
#>   <dbl> <chr>    <chr> <dbl>    <dbl>
#> 1     0 PSOE     PSOE  1188.  0.677  
#> 2     0 PP       PSOE   771.  0.00898
#> 3     0 Vox      PSOE   390.  0      
#> 4     0 Sumar    PSOE   423.  0.114  
#> 5     0 OTBL     PSOE   354.  0.0495 
#> 6     0 ABNL     PSOE   547.  0.104
cat("Número de simulaciones (incluyendo original):", length(unique(mt_sims$sim)), "\n")
#> Número de simulaciones (incluyendo original): 6
```

Cada simulación (`sim = 1, 2, ...`) es una matriz de transferencia
plausible. `sim = 0` es la matriz original observada.

## Paso 4: Ejecutar el Algoritmo VOTA

La función
[`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
toma una única matriz de transferencia (en formato largo con columnas
`recuerdo`, `idv`, `transfer`) y devuelve estimaciones nacionales de
voto. Ejecutémosla sobre la matriz original (`sim = 0`):

``` r
# Obtener la matriz de transferencia original (sim=0)
mt_original <- mt_sims %>% filter(sim == 0)

resultado <- vota(
  mt_simplificada = mt_original,
  tiempo_entre_elecciones = 0.1,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  retoques = retoques,
  small_parties = small_parties,
  votos_ant = votos_23J
)

# Estimaciones de voto nacionales
resultado$estimacion %>% 
  arrange(desc(votos))
#> # A tibble: 15 × 2
#>    idv          votos
#>    <chr>        <dbl>
#>  1 ABNL     10927917.
#>  2 PP        6486123.
#>  3 PSOE      6355227.
#>  4 Vox       3780625.
#>  5 Sumar     1493472.
#>  6 OTBL       906063.
#>  7 Podemos    881679.
#>  8 SALF       377051.
#>  9 ERC        345678.
#> 10 EH Bildu   196936.
#> 11 Junts      157092.
#> 12 BNG        152327 
#> 13 CCa        114718 
#> 14 PNV         83840.
#> 15 UPN         51764
```

La salida es un data frame con los votos estimados por partido (`idv`).
Son recuentos absolutos de votos.

Podemos calcular porcentajes de voto:

``` r
estimacion <- resultado$estimacion %>%
  mutate(pct = votos / sum(votos) * 100) %>%
  arrange(desc(pct))

estimacion
#> # A tibble: 15 × 3
#>    idv          votos    pct
#>    <chr>        <dbl>  <dbl>
#>  1 ABNL     10927917. 33.8  
#>  2 PP        6486123. 20.1  
#>  3 PSOE      6355227. 19.7  
#>  4 Vox       3780625. 11.7  
#>  5 Sumar     1493472.  4.62 
#>  6 OTBL       906063.  2.80 
#>  7 Podemos    881679.  2.73 
#>  8 SALF       377051.  1.17 
#>  9 ERC        345678.  1.07 
#> 10 EH Bildu   196936.  0.610
#> 11 Junts      157092.  0.486
#> 12 BNG        152327   0.471
#> 13 CCa        114718   0.355
#> 14 PNV         83840.  0.259
#> 15 UPN         51764   0.160
```

## Paso 5: Ejecutar VOTA en Todas las Simulaciones

Para cuantificar la incertidumbre, ejecutamos
[`vota()`](https://vota.spainelectoralproject.com/reference/vota.md) en
cada matriz de transferencia simulada:

``` r
todas_estimaciones <- lapply(unique(mt_sims$sim), function(s) {
  mt_s <- mt_sims %>% filter(sim == s)
  res <- vota(
    mt_simplificada = mt_s,
    tiempo_entre_elecciones = 0.1,
    factor_correccion_abstencion = 3,
    factor_correccion_jovenes = 2.5,
    factor_correccion_otbl = 2.5,
    retoques = retoques,
    small_parties = small_parties,
    votos_ant = votos_23J
  )
  res$estimacion %>% mutate(sim = s)
})

todas_estimaciones <- bind_rows(todas_estimaciones)

# Calcular porcentajes por simulación
todas_estimaciones <- todas_estimaciones %>%
  group_by(sim) %>%
  mutate(pct = votos / sum(votos) * 100) %>%
  ungroup()

head(todas_estimaciones, n = 20)
#> # A tibble: 20 × 4
#>    idv          votos   sim    pct
#>    <chr>        <dbl> <dbl>  <dbl>
#>  1 ABNL     10927917.     0 33.8  
#>  2 EH Bildu   196936.     0  0.610
#>  3 ERC        345678.     0  1.07 
#>  4 Junts      157092.     0  0.486
#>  5 OTBL       906063.     0  2.80 
#>  6 PNV         83840.     0  0.259
#>  7 PP        6486123.     0 20.1  
#>  8 PSOE      6355227.     0 19.7  
#>  9 Podemos    881679.     0  2.73 
#> 10 SALF       377051.     0  1.17 
#> 11 Sumar     1493472.     0  4.62 
#> 12 Vox       3780625.     0 11.7  
#> 13 BNG        152327      0  0.471
#> 14 CCa        114718      0  0.355
#> 15 UPN         51764      0  0.160
#> 16 ABNL     10464779.     1 33.1  
#> 17 EH Bildu  1987601.     1  6.29 
#> 18 ERC       2051504.     1  6.50 
#> 19 Junts     1993972.     1  6.31 
#> 20 OTBL       814974.     1  2.58
```

Ahora podemos ver cómo varían las estimaciones entre simulaciones:

``` r
estadisticos <- todas_estimaciones %>%
  group_by(idv) %>%
  summarise(
    pct_mediana = median(pct),
    pct_inf = quantile(pct, 0.05),
    pct_sup = quantile(pct, 0.95),
    .groups = "drop"
  ) %>%
  arrange(desc(pct_mediana))

estadisticos
#> # A tibble: 15 × 4
#>    idv      pct_mediana pct_inf pct_sup
#>    <chr>          <dbl>   <dbl>   <dbl>
#>  1 ABNL          33.0    32.9    33.7  
#>  2 SALF           6.48    2.48    6.56 
#>  3 ERC            6.43    2.39    6.63 
#>  4 PSOE           6.43    6.39   16.4  
#>  5 PNV            6.41    1.79    6.55 
#>  6 PP             6.39    6.36   16.7  
#>  7 Sumar          6.39    5.05    6.50 
#>  8 Podemos        6.34    3.61    6.48 
#>  9 Junts          6.34    1.94    6.55 
#> 10 EH Bildu       6.30    2.01    6.39 
#> 11 Vox            5.57    5.47   10.2  
#> 12 OTBL           2.59    2.55    2.75 
#> 13 BNG            0.482   0.474   0.482
#> 14 CCa            0.363   0.357   0.363
#> 15 UPN            0.164   0.161   0.164
```

## Paso 6: Proyección Provincial

Las estimaciones nacionales necesitan distribuirse entre las 52
provincias de España usando patrones históricos de voto. La función
[`simulate_prov_votes()`](https://vota.spainelectoralproject.com/reference/simulate_prov_votes.md)
hace esto usando una distribución Dirichlet:

``` r
# Usar la estimación puntual (sim=0)
estimacion_nacional <- resultado$estimacion

# Filtrar patrones para incluir solo partidos en nuestra estimación
partidos_en_estimacion <- estimacion_nacional$idv
patrones_filtrados <- patrones_23J %>%
  pivot_longer(
    all_of(partidos_en_estimacion), 
    names_to = "idv", 
    values_to = "patron"
  ) %>%
  mutate(patron = patron / 100) %>%
  filter(patron > 0)

# Simular distribución provincial de votos
votos_prov <- simulate_prov_votes(
  patrones = patrones_filtrados,
  estimacion = estimacion_nacional,
  method = "dirichlet",
  tau = 200,
  seed = 42
)

# El resultado es una matriz: provincias (filas) x partidos (columnas)
dim(votos_prov)
#> [1] 52 15
head(votos_prov[, 1:4])
#>      ABNL EH Bildu ERC Junts
#> 01 171742    22332   0     0
#> 02  29504        0   0     0
#> 03 374512        0   0     0
#> 04  56570        0   0     0
#> 05  21189        0   0     0
#> 06 297321        0   0     0
```

Cada celda contiene el número simulado de votos para ese partido en esa
provincia. El parámetro `tau` controla cuánto se ciñe la distribución
provincial al patrón histórico (mayor = menos variabilidad).

## Paso 7: Asignación de Escaños D’Hondt

Finalmente, asignamos escaños usando el método D’Hondt. Primero,
preparamos los datos en el formato que espera
[`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md):

``` r
# Convertir la matriz de votos provinciales a formato largo
prov_df <- as.data.frame(votos_prov) %>%
  mutate(codigo_provincia = rownames(votos_prov)) %>%
  pivot_longer(
    cols = -codigo_provincia,
    names_to = "partido",
    values_to = "votos_prov"
  ) %>%
  # Añadir recuento de escaños
  left_join(n_seats, by = "codigo_provincia") %>%
  # Añadir identificador de simulación
  mutate(sim = 0L) %>%
  # Calcular porcentaje de voto por provincia
  group_by(sim, codigo_provincia) %>%
  mutate(
    votos_validos = sum(votos_prov),
    pct_sobre_validos = votos_prov / votos_validos
  ) %>%
  ungroup()

head(prov_df)
#> # A tibble: 6 × 7
#>   codigo_provincia partido  votos_prov n_diputados   sim votos_validos
#>   <chr>            <chr>         <int>       <dbl> <int>         <int>
#> 1 01               ABNL         171742           4     0        386196
#> 2 01               EH Bildu      22332           4     0        386196
#> 3 01               ERC               0           4     0        386196
#> 4 01               Junts             0           4     0        386196
#> 5 01               OTBL           1138           4     0        386196
#> 6 01               PNV            7821           4     0        386196
#> # ℹ 1 more variable: pct_sobre_validos <dbl>
```

Aplicar el umbral electoral (3%) y ejecutar D’Hondt:

``` r
# Filtrar partidos que superan el umbral
prov_sobre_umbral <- prov_df %>%
  filter(!partido %in% c("OTBL", "ABNL"), pct_sobre_validos >= 0.03)

# Ejecutar asignación D'Hondt
resultado_dhondt <- fast_dhondt(
  data = prov_sobre_umbral,
  cod_prov = codigo_provincia,
  sim = sim,
  partido = partido,
  votos_prov = votos_prov,
  nseats = n_diputados
)

head(resultado_dhondt)
#> # A tibble: 6 × 13
#>   codigo_provincia partido votos_prov n_diputados   sim votos_validos
#>   <chr>            <chr>        <int>       <dbl> <int>         <int>
#> 1 01               PP           71200           4     0        386196
#> 2 01               PSOE         69712           4     0        386196
#> 3 01               PP           71200           4     0        386196
#> 4 01               PSOE         69712           4     0        386196
#> 5 02               PP           77596           4     0        206836
#> 6 02               Vox          63294           4     0        206836
#> # ℹ 7 more variables: pct_sobre_validos <dbl>, divisor <int>, cociente <dbl>,
#> #   order <int>, tipo <chr>, col <dbl>, dif <dbl>
```

Agregar para obtener el total de escaños por partido:

``` r
escanos_por_partido <- resultado_dhondt %>%
  filter(tipo == "Asignado") %>%
  count(partido, name = "escanos") %>%
  arrange(desc(escanos))

escanos_por_partido
#> # A tibble: 12 × 2
#>    partido  escanos
#>    <chr>      <int>
#>  1 PSOE         121
#>  2 PP           120
#>  3 Vox           72
#>  4 Sumar         16
#>  5 ERC            7
#>  6 Podemos        4
#>  7 CCa            3
#>  8 EH Bildu       3
#>  9 BNG            1
#> 10 Junts          1
#> 11 PNV            1
#> 12 UPN            1
cat("Total escaños asignados:", sum(escanos_por_partido$escanos), "\n")
#> Total escaños asignados: 350
```

## Paso 8: El Pipeline Completo con `run_vota()`

En la práctica, usarías
[`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
que orquesta todos los pasos anteriores automáticamente. Lee desde un
archivo Excel, así que vamos a crear uno usando la función de plantilla:

``` r
# Crear un proyecto temporal
tmp_dir <- tempdir()
project_dir <- file.path(tmp_dir, "tutorial_proyecto")
setup_electoral_project(project_dir)

# Ejecutar el pipeline completo
resultados <- run_vota(
  input_path = file.path(project_dir, "input", "input.xlsx"),
  output_file = file.path(project_dir, "output", "resultados.rds"),
  uncertainty_method = "mcmc",
  nsims = 50,
  factor_correccion_abstencion = 3,
  factor_correccion_jovenes = 2.5,
  factor_correccion_otbl = 2.5,
  tiempo_entre_elecciones = 0.1,
  tau = 300,
  umbral = 0.03,
  seed = 42,
  verbose = TRUE
)

# Ver resultados
print(resultados)
summary(resultados)

# Visualizar
plot(resultados, "nacional")
plot(resultados, "seats_dist")
```

## Resumen

En este tutorial hemos recorrido cada paso de la simulación electoral:

1.  **Exploración de datos** – Entendiendo la matriz de transferencia,
    resultados anteriores y patrones provinciales
2.  **Simulación de la matriz de transferencia** –
    [`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md)
    para incertidumbre multinomial
3.  **Algoritmo VOTA** –
    [`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
    con cinco correcciones secuenciales
4.  **Proyección provincial** –
    [`simulate_prov_votes()`](https://vota.spainelectoralproject.com/reference/simulate_prov_votes.md)
    con variabilidad Dirichlet
5.  **Asignación de escaños** –
    [`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)
    para D’Hondt vectorizado
6.  **Pipeline completo** –
    [`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
    integrando todo

## Más Información

- **[Primeros
  pasos](https://vota.spainelectoralproject.com/articles/primeros-pasos.md)**
  – Guía de configuración rápida
- **[Metodología
  VOTA](https://vota.spainelectoralproject.com/articles/metodologia.md)**
  – Detalles estadísticos del algoritmo
