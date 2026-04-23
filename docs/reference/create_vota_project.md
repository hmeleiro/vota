# Crear proyecto desde plantilla

funcion de conveniencia para crear un proyecto completo con datos de
ejemplo.

## Uso

``` r
create_vota_project(name = "", path = ".")
```

## Argumentos

- name:

  Nombre del proyecto (usado para el directorio)

- path:

  Directorio donde crear el proyecto (por defecto ".")

## Valor

Devuelve (invisiblemente) la ruta del proyecto creado

## Detalles

Esta funcion es un wrapper de
[`setup_electoral_project()`](https://vota.spainelectoralproject.com/reference/setup_electoral_project.md)
que ademas proporciona mensajes informativos sobre como usar el proyecto
creado.

## Ejemplos

``` r
if (FALSE) { # \dontrun{
# Crear proyecto en directorio actual
create_vota_project("elecciones_2023")

# Crear proyecto en ubicacion especifica
create_vota_project("valencia_2023", path = "/proyectos/")
} # }
```
