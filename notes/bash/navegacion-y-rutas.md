# Navegación y rutas

Fuente: `missing.csail.mit.edu/2026/course-shell/` · Práctica: `lecture01/navigation` y Bandit 1–4
2026-07-01, ampliada 2026-08-11

## Modelo mental

Todo comando se ejecuta **desde un directorio actual** (cwd, el que muestra `pwd`).
Una ruta que empieza con `/` se resuelve desde la raíz; cualquier otra, desde el cwd.

Y algo que no se ve: **la shell expande `~`, las variables y los globs antes de llamar al
programa.** Cuando escribo `cd ~/proyectos`, `cd` nunca ve el `~` — recibe
`/home/mlizz/proyectos` ya resuelto. El programa recibe un arreglo de cadenas, sin comillas
y sin comodines.

De ahí sale la pregunta que resuelve casi todo: **¿esto lo interpreta la shell, o el
programa?**

Aparte, la shell hace una búsqueda distinta: para encontrar el **programa** recorre las
carpetas de `$PATH`, en orden, y ejecuta la primera coincidencia.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `pwd` | dónde estoy, **siempre en absoluto** |
| `ls` / `ls -a` | qué hay aquí / incluyendo los ocultos |
| `cd <ruta>` / `cd` | moverme / volver a home |
| `mkdir -p a/b/c` | crear carpetas anidadas, sin fallar si ya existen |
| `type <cmd>` | qué es realmente: alias, función, builtin o programa |
| `which -a <cmd>` | dónde está el programa, y sus duplicados |
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

`cd` es el comando y `~` es su argumento: **`cd ~`, `cd /`.** Sin espacio, la shell busca un
programa llamado `cd~`.

### Relativa vs absoluta: lo decide el primer carácter

| Ruta | Tipo | Se resuelve desde |
|---|---|---|
| `/bin` | **absoluta** | la raíz |
| `bin` | **relativa** | donde estoy parada |

Regla: **si empieza con `/`, es absoluta.** Nada más. Que tenga carpetas adentro o sea un
solo nombre no cambia nada, y el `./` inicial es decorativo: `./bashrc` y `bashrc` son la
misma ruta.

> Corregido el 2026-08-01: la versión anterior tenía los ejemplos invertidos.

### Una ruta con varios `..` es una sola operación

```bash
~/proyectos/repo/practice/lecture01/navigation/level1$ cd ../..
~/proyectos/repo/practice/lecture01$
```

`cd` recibe la cadena completa `../..` y la resuelve de izquierda a derecha, componente por
componente. `/` solo separa; no hace nada solo.

### Un nombre que empieza con `-` lo lee el programa como opción

```bash
$ cat -file07
cat: unrecognized option
```

**Escapar con `\` no sirve**: `\-` y `-` le llegan idénticos al programa, porque el guion no
tiene significado especial para la shell. El problema no es de la shell, es de `cat`.

Las tres salidas:

```bash
cat ./-file07        # anteponer una ruta
cat -- -file07       # -- = "aquí terminan las opciones"
cat < -file07        # redirigir: cat ni recibe el argumento
```

**`./` solo importa cuando el nombre empieza con `-`.** En el resto de los casos es ruido.

Ojo con `-` **solo**, que es otro mecanismo: por convención significa "lee de stdin". `cat -`
se queda esperando el teclado; `cat -file07` da error de opción.

### Los archivos ocultos son solo nombres que empiezan con punto

No existe un atributo "oculto". `ls` los omite por convención, `ls -a` los muestra. Una vez
que sé el nombre, se leen como cualquier otro.

Consecuencia práctica: **un glob `*` tampoco los encuentra.** Por eso un bucle
`for f in "$DIR"/*` sobre una carpeta de dotfiles corre sin error y sin hacer nada.

Y los `...` no significan nada en ningún lado. Solo existen `.` y `..` como componentes
completos de una ruta; `...Hiding-From-You` es un nombre normal.

### Qué obliga a poner comillas

Espacios, `*`, `?`, `$`, `;`, `|`, `&`, `(`, `)`, `"`, `'`. El punto y el guion **no** están
en la lista.

Son dos problemas distintos que a veces coinciden:

```bash
cat -- "--spaces in this filename--"
#   │      └── comillas: los espacios los resuelve la SHELL
#   └── --: el guion lo resuelve el PROGRAMA
```

Sin comillas, la shell parte el nombre en cuatro argumentos. Con comillas pero sin `--`,
`cat` lee los primeros guiones como opción.

### Un nombre por stdin no es un nombre de archivo

```bash
$ ls | cat -
--spaces in this filename--
```

Imprimió el nombre, no el contenido. `cat` con stdin **no abre nada**: copia lo que le entra.
Un nombre como **argumento** hace que el programa lo abra; el mismo nombre como **datos** es
solo texto.

Los pipes llevan contenido, no referencias. `xargs` es lo que convierte texto en argumentos.

## Pendientes

- [ ] `cd -` (volver al directorio anterior)
- [ ] `xargs` en la práctica
