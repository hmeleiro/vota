# Simulaciones Monte Carlo de matrices de provincia x partido

Genera simulaciones multinomiales de resultados de cada partido en cada
provincia

## Usage

``` r
simulate_prov_votes(
  patrones,
  estimacion,
  method = c("dirichlet", "logitnorm"),
  tau = 300,
  sigma = 0.15,
  Sigma = NULL,
  eps = 1e-12,
  seed = NULL
)
```

## Arguments

- patrones:

  data frame con patrones provinciales (columnas: codigo_provincia, idv,
  patron)

- estimacion:

  vector con votos nacionales por partido (nombres = colnames(patrones))

- method:

  Metodo de simulacion: "dirichlet" o "logitnorm"

- tau:

  Concentracion para Dirichlet (escalar o vector por partido)

- sigma:

  Desviacion estandar del ruido en log-escala para Logistic-normal

- Sigma:

  Matriz de covarianza opcional (PxP) para correlacion espacial

- eps:

  Smoothing para evitar ceros exactos en patrones

- seed:

  Semilla para reproducibilidad (por defecto NULL)

## Value

Matriz con simulacion de votos por provincia (filas = provincias,
columnas = partidos)
