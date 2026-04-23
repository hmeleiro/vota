# Metodología VOTA

``` r
library(vota)
```

## Visión General

El algoritmo *VOTA* es el método de proyección central de vota.
Transforma una matriz de transferencia (a quién votaron previamente los
encuestados y a quién piensan votar ahora) en estimaciones nacionales de
voto, aplicando cinco correcciones secuenciales para mejorar el
realismo. Estas estimaciones se proyectan después al nivel provincial y
se convierten en escaños usando el método D’Hondt.

Esta viñeta explica cada etapa de la metodología.

## La Matriz de Transferencia

La matriz de transferencia es la entrada fundamental. Es una tabulación
cruzada de:

- **Filas:** Recuerdo de voto (`recuerdo`) – a qué partido dicen los
  votantes que votaron la última vez
- **Columnas:** Intención de voto actual (`idv`) – a qué partido piensan
  votar ahora

Cada celda contiene la proporción de votantes que transfieren de un
partido a otro. Las categorías especiales incluyen:

- **ABNL** (Abstención / Nulo): Abstención o votos nulos
- **OTBL** (Otros / Blanco): Otros partidos o votos en blanco
- **\<18**: Votantes que eran menores de 18 en la elección anterior
  (nuevos votantes)
- **Indecisos**: Votantes que aún no han decidido

``` r
data(mt)
str(mt)
#> tibble [15 × 8] (S3: tbl_df/tbl/data.frame)
#>  $ idv  : chr [1:15] "PSOE" "PP" "Vox" "Sumar" ...
#>  $ PSOE : num [1:15] 67.74 2.57 1.28 2.81 1.22 ...
#>  $ PP   : num [1:15] 0.898 68.754 12.677 0 0 ...
#>  $ Vox  : num [1:15] 0 3.677 78.412 0.586 0.11 ...
#>  $ Sumar: num [1:15] 11.425 1.313 0.106 37.397 22.545 ...
#>  $ OTBL : num [1:15] 4.95 5.48 2.11 2.34 2.3 ...
#>  $ ABNL : num [1:15] 10.365 8.622 11.495 1.286 0.872 ...
#>  $ <18  : num [1:15] 17.18 6.87 19.21 4.3 1.34 ...
```

## Las Cinco Correcciones

La función
[`vota()`](https://vota.spainelectoralproject.com/reference/vota.md)
aplica cinco correcciones en secuencia. Cada una se construye sobre la
salida de la anterior.

### 1. Corrección de Abstención

Los votantes que se abstuvieron en la elección anterior (recuerdo
`ABNL`) tienden a tener patrones de transferencia poco fiables. La
corrección reduce las probabilidades de transferencia desde ABNL
dividiéndolas por `factor_correccion_abstencion` (por defecto: 3), y
luego renormaliza.

**Justificación:** Los anteriores abstencionistas que ahora dicen que
votarán por un partido específico históricamente tienen menos
probabilidad de hacerlo realmente. Dividir por 3 significa que solo ~1/3
de su intención declarada se refleja en la estimación.

### 2. Corrección de Nuevos Votantes

Los votantes menores de 18 años durante la elección anterior (recuerdo
`<18`) son una nueva cohorte demográfica. Sus probabilidades de
transferencia se reducen de forma similar por
`factor_correccion_jovenes` (por defecto: 2.5).

El número de nuevos votantes se estima como:

$$\text{Nuevos votantes} = \text{Total votos anteriores} \times 0.01 \times \text{años entre elecciones}$$

Se aplica un ajuste de mortalidad correspondiente a los grupos de
votantes existentes de forma proporcional.

**Justificación:** Los jóvenes que no han votado antes tienden a
sobreestimar su intención de votar y tienen preferencias menos estables.

### 3. Redistribución de Indecisos

Los votantes clasificados como “Indecisos” se redistribuyen entre todos
los partidos proporcionalmente al patrón de transferencia existente.
Esto equivale a asumir que los indecisos se distribuirán en las mismas
proporciones que los decididos.

### 4. Incorporación de Partidos Pequeños

Los partidos pequeños no incluidos en la matriz de transferencia
principal se inyectan mediante el parámetro `small_parties`. Sus votos
totales estimados se añaden directamente, y cualquier código de partido
solapado se reemplaza.

**Justificación:** Los partidos muy pequeños (p.ej., partidos regionales
con \<1% a nivel nacional) son difíciles de modelar mediante matrices de
transferencia debido a los tamaños muestrales pequeños. Las estimaciones
externas (de encuestas regionales o juicio experto) son más fiables.

### 5. Ajustes Manuales

Los ajustes discrecionales (`retoques`) suman o restan votos a partidos
específicos. Se aplican en último lugar, como corrección final
discrecional.

**Justificación:** Los analistas pueden disponer de información no
capturada por los datos de encuesta (p.ej., efectos de campaña de último
momento, señales de movilización).

## Cuantificación de la Incertidumbre

### Método MCMC

Cuando `uncertainty_method = "mcmc"`, el paquete genera `nsims` matrices
de transferencia simuladas usando remuestreo multinomial. El proceso:

1.  Toma la matriz de transferencia observada con los tamaños de muestra
    (`n`)
2.  Genera `nsims` muestras multinomiales del mismo tamaño total
3.  Convierte cada extracción de vuelta a proporciones
4.  Ejecuta el algoritmo VOTA completo sobre cada matriz simulada

Esto produce una distribución de estimaciones nacionales, capturando la
incertidumbre muestral.

### Método Bootstrap

Cuando `uncertainty_method = "bootstrap"`, los datos individuales de
encuesta se remuestrean con reemplazo. Opcionalmente, se pueden usar
pesos de encuesta y variables de calibración para producir réplicas
bootstrap calibradas
([`survey::calibrate()`](https://rdrr.io/pkg/survey/man/calibrate.html)).

## Proyección Provincial

Las estimaciones nacionales se proyectan a provincias usando la función
[`project_to_districts()`](https://vota.spainelectoralproject.com/reference/project_to_districts.md):

1.  Los **patrones históricos** de `patrones_23J` definen la
    distribución provincial esperada de cada partido
2.  La **simulación Dirichlet** añade variabilidad: para cada partido,
    las cuotas provinciales se extraen de una distribución Dirichlet
    centrada en el patrón histórico, con parámetro de concentración
    `tau`
    - Mayor `tau` (p.ej., 500) = menos variabilidad provincial
    - Menor `tau` (p.ej., 100) = más variabilidad provincial
3.  La **asignación multinomial** distribuye los votos nacionales
    totales entre las celdas provincia-partido

``` r
data(patrones_23J)
# Patrones provinciales: cuota histórica de voto de cada partido por provincia
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

## Asignación de Escaños D’Hondt

La función
[`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)
implementa el método D’Hondt, vectorizado para el procesamiento
simultáneo de todas las provincias y simulaciones:

1.  Los votos provinciales de cada partido se dividen por 1, 2, 3, …,
    hasta el número total de escaños
2.  Los escaños se asignan a los cocientes más altos
3.  Se aplica un umbral electoral (`umbral`, por defecto 3%) – los
    partidos por debajo de este umbral en una circunscripción no reciben
    escaños

El umbral puede aplicarse a tres niveles:

- **`provincial`** – cada provincia de forma independiente (estándar
  para elecciones nacionales)
- **`autonomico`** – porcentaje calculado sobre toda la comunidad
  autónoma
- **`mixto`** – el partido se clasifica si supera el umbral provincial o
  el autonómico

``` r
data(n_seats)
# 52 circunscripciones con diferente número de escaños
summary(n_seats$n_diputados)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   1.000   4.000   5.000   6.731   7.000  37.000
```

## El Objeto `electo_fit`

Todos los resultados se empaquetan en un objeto S3 de clase
`electo_fit`, con métodos para:

- [`print()`](https://rdrr.io/r/base/print.html) – Vista rápida de los
  partidos principales por votos y escaños
- [`summary()`](https://rdrr.io/r/base/summary.html) – Estimaciones
  agregadas con intervalos de confianza y probabilidades de victoria
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) – Cuatro
  tipos de visualización (nacional, seats_dist, provincia,
  dhondt_margin)

## Sensibilidad de Parámetros

Parámetros clave y sus efectos:

| Parámetro                      | Efecto al aumentar                                                        |
|--------------------------------|---------------------------------------------------------------------------|
| `nsims`                        | Estimaciones de incertidumbre más estables, cómputo más lento             |
| `tau`                          | Menos variabilidad provincial, más ajustado a patrones históricos         |
| `factor_correccion_abstencion` | Mayor descuento de las intenciones declaradas de abstencionistas          |
| `factor_correccion_jovenes`    | Mayor descuento de las intenciones declaradas de nuevos votantes          |
| `factor_correccion_otbl`       | Mayor descuento de las intenciones declaradas de votantes de otros/blanco |
| `tiempo_entre_elecciones`      | Mayor cohorte de nuevos votantes, mayor ajuste de mortalidad              |
| `umbral`                       | Umbral más alto para obtener escaños (filtra partidos más pequeños)       |

## Resumen del Pipeline

    Datos de Encuesta (Excel)
           |
           v
    load_and_validate()           -- Lectura y validación
           |
           v
    draw_mt() / simulate_mt()    -- Generar nsims matrices de transferencia
           |
           v
    vota()  [x nsims]           -- Aplicar 5 correcciones por simulación
           |
           v
    project_to_districts()        -- Nacional -> Provincial (Dirichlet)
           |
           v
    umbral_electoral()            -- Aplicar umbral electoral
           |
           v
    fast_dhondt()                 -- Asignar escaños (D'Hondt)
           |
           v
    aggregate_results()           -- Medianas, ICs, probabilidades de victoria
           |
           v
    new_electo_fit()              -- Empaquetar en objeto electo_fit

## Más Información

- **[Primeros
  pasos](https://vota.spainelectoralproject.com/articles/primeros-pasos.md)**
  – Instalación e inicio rápido
- **[Tutorial paso a
  paso](https://vota.spainelectoralproject.com/articles/tutorial-es.md)**
  – Recorrido práctico con datos internos
