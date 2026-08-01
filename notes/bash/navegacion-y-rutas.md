# Navegación y rutas

Fuente: `missing.csail.mit.edu/2026/course-shell/` · Práctica: `lecture01/navigation` · 2026-07-01

## Modelo mental

Todo comando se ejecuta **desde un directorio actual** (cwd, el que muestra `pwd`).
Una ruta que empieza con `/` se resuelve desde la raíz; cualquier otra se resuelve desde el cwd.

Y algo que no se ve: **la shell expande `~` y las variables antes de llamar al programa.**
Cuando escribes `cd ~/proyectos`, `cd` nunca ve el `~` — recibe `/home/mlizz/proyectos` ya resuelto.
Es la misma idea de las comillas: la shell transforma la línea, y el programa recibe el resultado.

Aparte de eso, la shell hace una búsqueda distinta: para encontrar el **programa** recorre las
carpetas listadas en `$PATH`, en orden, y ejecuta la primera coincidencia.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `pwd` | dónde estoy |
| `ls` | qué hay aquí |
| `cd <ruta>` | moverme |
| `cd` (sin nada) | volver a home |
| `mkdir -p a/b/c` | crear carpetas anidadas, sin fallar si ya existen |
| `which -a <cmd>` | dónde está el programa que se ejecuta, y sus duplicados |
| `man <cmd>` / `<cmd> --help` | manual completo / versión corta |

| Atajo | Significa |
|---|---|
| `.` | el directorio actual |
| `..` | el directorio padre |
| `~` | mi home |
| `/` | la raíz del sistema |

## Cómo se rompe

### Los atajos necesitan espacio

```bash
$ cd~
cd~: command not found
```

`cd~` y `cd/` no existen. `cd` es el comando y `~` es su argumento: **`cd ~`, `cd /`.**
Sin espacio, la shell busca un programa llamado `cd~`.

### Relativa vs absoluta: lo decide el primer carácter

| Ruta | Tipo | Se resuelve desde |
|---|---|---|
| `/bin` | **absoluta** — empieza con `/` | la raíz |
| `bin` | **relativa** — no empieza con `/` | donde estoy parada |

Regla: **si empieza con `/`, es absoluta.** Nada más.
La absoluta lleva al mismo lugar siempre; la relativa depende de dónde estés.

> Corregido el 2026-08-01: la versión anterior de esta nota tenía los ejemplos invertidos.

### Una ruta con varios `..` es una sola operación

```bash
~/proyectos/repo/practice/lecture01/navigation/level1$ cd ../..
~/proyectos/repo/practice/lecture01$
```

`cd` no ejecuta un `..` y luego otro por separado: recibe la cadena completa `../..` y la
resuelve de izquierda a derecha, componente por componente. `/` solo separa; no hace nada solo.

Mismo caso con `cd ../carpeta` → "sube al padre, y desde ahí entra a `carpeta`".

## Pendientes

- [ ] Ver qué pasa con `cd -` (volver al directorio anterior)
- [ ] Entender por qué `which` a veces no encuentra algo que sí corre (¿alias? ¿builtin?)
