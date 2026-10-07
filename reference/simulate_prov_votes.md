# Proyeccion de matrices de provincia x partido

Proyecta los resultados de cada partido a cada provincia mediante
patrones historicos, de forma determinista o mediante simulacion.

## Usage

``` r
simulate_prov_votes(
  patrones,
  estimacion,
  method = c("dirichlet", "logitnorm", "deterministic"),
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

  Metodo de proyeccion: "dirichlet", "logitnorm" o "deterministic". El
  metodo determinista usa los patrones historicos sin perturbar y no
  consume numeros aleatorios.

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

Matriz con votos por provincia (filas = provincias, columnas =
partidos). Para los metodos estocasticos contiene un sorteo multinomial;
para `method = "deterministic"`, los valores esperados sin sorteo.

## Details

Con `method = "deterministic"`, los patrones de cada partido se
normalizan entre provincias y se multiplican por sus votos nacionales.
No se aplica smoothing, por lo que los ceros historicos se conservan.
