# Data Engineering Roadmap

Ruta de aprendizaje hacia Data Engineer / Analytics Engineer.
Iniciada en julio de 2026. Bitácora de sesiones en [`LOG.md`](LOG.md).

## Stack objetivo

**Base:** Linux · Bash · Git · Python · SQL
**Datos:** PostgreSQL · dbt · Airflow · Spark
**Infra:** Docker · una nube (por definir en el mes 10)

## Estructura

| Carpeta | Qué contiene | Organizado por |
|---|---|---|
| `notes/` | Apuntes propios, máximo 1 página cada uno | **tema** |
| `practice/` | Ejercicios de cursos y retos | **curso / fuente** |
| `projects/` | Proyectos completos, end-to-end | proyecto |
| `scripts/` | Utilidades reutilizables propias | — |
| `data/` | Datos de práctica (`raw/` está en .gitignore) | — |

Reglas: las carpetas nacen cuando tienen su primer archivo real, nunca antes.
La tecnología es el **segundo** nivel (`notes/bash/`, `practice/missing-semester/`), no el primero.

## Convenciones

- Nombres en minúsculas, `kebab-case`, sin espacios, sin acentos, sin paréntesis.
- Salidas de terminal en bloques de código, nunca capturas de pantalla.
- Cada nota sigue [`notes/_plantilla.md`](notes/_plantilla.md). Si no cabe en una página, se parte.
- Toda sesión de estudio termina en un commit.

## Progreso

Ver [`LOG.md`](LOG.md) — una línea por sesión, append-only.
Dudas en cola: [`pendientes.md`](pendientes.md).
