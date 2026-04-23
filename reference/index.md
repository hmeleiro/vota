# Package index

## Pipeline principal

Funciones para ejecutar la simulación completa.

- [`run_vota()`](https://vota.spainelectoralproject.com/reference/run_vota.md)
  : Run Complete Electoral Simulation
- [`vota()`](https://vota.spainelectoralproject.com/reference/vota.md) :
  VOTA: Vote Outcome Transfer-based Algorithm
- [`load_and_validate()`](https://vota.spainelectoralproject.com/reference/load_and_validate.md)
  : Load and validate electoral data from Excel
- [`validate_input_data()`](https://vota.spainelectoralproject.com/reference/validate_input_data.md)
  : Validate Input Data

## Simulación Monte Carlo

Funciones de simulación y muestreo.

- [`simulate_mt()`](https://vota.spainelectoralproject.com/reference/simulate_mt.md)
  : Simulaciones Monte Carlo de Matrices de Transferencia
- [`simulate_prov_votes()`](https://vota.spainelectoralproject.com/reference/simulate_prov_votes.md)
  : Simulaciones Monte Carlo de matrices de provincia x partido
- [`draw_mt()`](https://vota.spainelectoralproject.com/reference/draw_mt.md)
  : Generate transfer matrix simulations

## D’Hondt y escaños

Asignación de escaños y agregación.

- [`fast_dhondt()`](https://vota.spainelectoralproject.com/reference/fast_dhondt.md)
  : Vectorized D'Hondt Allocation
- [`allocate_seats()`](https://vota.spainelectoralproject.com/reference/allocate_seats.md)
  : Allocate Seats to Parties in Each Province Allocates seats to
  parties in each province using the D'Hondt method, applying electoral
  thresholds to determine which parties are eligible for seat
  allocation.
- [`aggregate_results()`](https://vota.spainelectoralproject.com/reference/aggregate_results.md)
  : Agregar Resultados Nacionales desede Simulaciones Provinciales
- [`calculate_n()`](https://vota.spainelectoralproject.com/reference/calculate_n.md)
  : Calcular Tamaños de Muestra de MT

## Datos de entrada

Lectura y preparación de datos.

- [`read_mt()`](https://vota.spainelectoralproject.com/reference/read_mt.md)
  : Leer Matriz de Transferencia
- [`read_partidos()`](https://vota.spainelectoralproject.com/reference/read_partidos.md)
  : Cargar codigos de Partidos
- [`read_patrones()`](https://vota.spainelectoralproject.com/reference/read_patrones.md)
  : Read Provincial Patterns
- [`get_censo()`](https://vota.spainelectoralproject.com/reference/get_censo.md)
  : Download Electoral Census Data

## Utilidades

Herramientas auxiliares y plantillas.

- [`setup_electoral_project()`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md)
  : Set up electoral project
- [`create_vota_project()`](https://vota.spainelectoralproject.com/reference/create_vota_project.md)
  : Crear proyecto desde plantilla
- [`create_input_template()`](https://vota.spainelectoralproject.com/reference/create_input_template.md)
  : Crear plantilla de archivos de entrada

## Clases S3

Objeto de resultados y métodos asociados.

- [`new_electo_fit()`](https://vota.spainelectoralproject.com/reference/new_electo_fit.md)
  : Crea un objeto electo_fit
- [`print(`*`<electo_fit>`*`)`](https://vota.spainelectoralproject.com/reference/print.electo_fit.md)
  : Print method for electo_fit objects
- [`print(`*`<summary_electo_fit>`*`)`](https://vota.spainelectoralproject.com/reference/print.summary_electo_fit.md)
  : Print method for summary_electo_fit objects
- [`summary(`*`<electo_fit>`*`)`](https://vota.spainelectoralproject.com/reference/summary.electo_fit.md)
  : Summary method for electo_fit objects
- [`plot(`*`<electo_fit>`*`)`](https://vota.spainelectoralproject.com/reference/plot.electo_fit.md)
  : Generate plots from electo_fit objects

## Conjuntos de datos

Datos incluidos en el paquete.

- [`mt`](https://vota.spainelectoralproject.com/reference/mt.md) :
  Matriz de Transferencia de Ejemplo
- [`n_seats`](https://vota.spainelectoralproject.com/reference/n_seats.md)
  : Número de escaños por provincia
- [`patrones_23J`](https://vota.spainelectoralproject.com/reference/patrones_23J.md)
  : Patrones electorales del 23J
- [`retoques`](https://vota.spainelectoralproject.com/reference/retoques.md)
  : Ajustes manuales de ejemplo
- [`small_parties`](https://vota.spainelectoralproject.com/reference/small_parties.md)
  : Partidos pequeños de ejemplo
- [`votos_23J`](https://vota.spainelectoralproject.com/reference/votos_23J.md)
  : Resultados electorales del 23J
