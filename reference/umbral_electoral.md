# Aplica el umbral electoral a los datos de votos simulados por provincias.

Aplica el umbral electoral a los datos de votos simulados por
provincias.

## Usage

``` r
umbral_electoral(
  votos_provincias_sims,
  umbral = 0.03,
  tipo_umbral = "provincial"
)
```

## Arguments

- votos_provincias_sims:

  Data frame con votos simulados por provincia

- umbral:

  Umbral minimo de voto para asignacion de escaños (por defecto 0.03)

- tipo_umbral:

  Tipo de umbral: "provincial", "autonomico" o "mixto" (por defecto
  "provincial")

## Value

Lista con dos data frames:

- noentran:

  Partidos que no alcanzan el umbral, con votos y seats = NA

- entran:

  Partidos que superan el umbral, con votos para asignacion D'Hondt
