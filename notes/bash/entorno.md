# Entorno de shell: alias, dotfiles y carga de configuración

Fuente: `missing.csail.mit.edu/2026/command-line-environment/` → *Customizing the Shell* · 2026-08-03
Práctica: `practice/missing-semester/lecture02/dotfiles-alias.md`

---

## Modelo mental

Un alias **no es un comando**. Es una sustitución de texto que bash hace **al leer la línea**,
antes de evaluar nada. Eso explica sus tres rarezas: que se pueda anular con comillas, que no
funcione en scripts, y que el argumento siempre caiga al final.

Un alias **no vive en ningún lado por sí solo**. Existe en la memoria de *una* sesión de bash.
Para que sobreviva tiene que estar escrito en un archivo que bash lea al arrancar. Cuáles lee
depende de si la sesión es *login* o *interactive* — dos categorías distintas, con dos listas
distintas de archivos.

De ahí sale todo lo demás: los dotfiles existen porque la configuración tiene que estar en un
archivo con **ruta fija** que el programa ya sabe buscar. Y el symlink existe porque esa ruta
fija choca con querer tener los archivos en otro lado, bajo git.

---

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `alias nombre='comando'` | crea un alias en la sesión actual |
| `alias nombre` | imprime su definición · `alias` los lista todos |
| `unalias nombre` | lo elimina de la sesión |
| `\nombre` | lo ignora **una vez** |
| `type nombre` | qué es realmente: alias, función, builtin o programa |
| `source archivo` / `. archivo` | ejecuta el archivo **en la shell actual** |
| `shopt login_shell` | dice si esta sesión es login o no |
| `ln -s destino enlace` | crea un enlace simbólico |
| `readlink enlace` | imprime a dónde apunta |
| `ls -li` | listado **con número de inodo** |
| `stat -c '%i %h' archivo` | inodo y cuántos nombres lo apuntan |
| `Ctrl-R` | búsqueda inversa en el historial |

---

# 1. Para qué sirve realmente un alias

El material da **cuatro razones** y una capacidad. La proporción sorprende:

| Razón | Categoría |
|---|---|
| abreviar banderas comunes (`ll='ls -lh'`) | **escribir menos** |
| ahorrar tecleo en comandos frecuentes (`gs`, `gc`) | **escribir menos** |
| salvarte de escribir mal (`sl=ls`) | **no equivocarte** |
| **sobrescribir comandos con mejores defaults** (`mv -i`, `mkdir -p`, `df -h`) | **no equivocarte** |
| los alias se pueden componer (`lla='la -l'`) | *capacidad, no razón* |

**Es 2 a 2.** La mitad de las razones para usar alias no tienen nada que ver con escribir
menos. Es el punto que la sección hace sin decirlo en voz alta.

## La cuarta categoría es la que importa

`alias mv='mv -i'` — el `-i` es *interactive*: `mv` pregunta antes de sobrescribir un archivo
que ya existe. Sin él, `mv a.txt b.txt` **destruye `b.txt` en silencio**, sin confirmación y
sin forma de recuperarlo.

Eso no es escribir menos. Es cambiarle el comportamiento por defecto a una herramienta que por
diseño no protege. Es la categoría más valiosa y la más fácil de pasar por alto, porque no
ahorra ni un carácter — de hecho hace que el comando tarde más.

**Los tres que valen la pena:**

```bash
alias mv='mv -i'        # pregunta antes de sobrescribir
alias cp='cp -i'        # igual, para copiar
alias rm='rm -I'        # pregunta al borrar más de 3 archivos (I mayúscula)
```

### Cómo se rompe

> **Estos alias son una muleta local, no un hábito.** Si te acostumbras a que `rm` siempre
> pregunta, el día que estés en un servidor sin tu `.bashrc` vas a borrar algo sin red. El
> alias protege en tu máquina; no enseña cuidado.

---

# 2. El límite real de los alias, y dónde entran las funciones

La limitación **no** es "los alias no reciben argumentos". Sí los reciben — el argumento se
pega al final de la sustitución:

```bash
alias dc='cd'
dc projects        # → cd projects   ✅ funciona
```

**La limitación es cuando el argumento va en medio.** El alias no puede colocarlo en otro
lugar que no sea el final:

```bash
alias buscar='find -name "*.md" -type f'
buscar /tmp/f      # → find -name "*.md" -type f /tmp/f
find: paths must precede expression: `/tmp/f'
```

`find` quiere la ruta **primero**. El alias la puso al final. No hay arreglo dentro del alias.

**Ahí entran las funciones**, porque tienen parámetros posicionales:

```bash
buscar() { find "$1" -name "*.md" -type f; }
```

**Criterio:** banderas fijas y argumento al final → alias. Necesitas decidir *dónde* va el
argumento → función.

### Cómo se rompe

> **Definir una función con el nombre de un alias existente da un error de sintaxis.**
> ```
> alias buscar='find -name "*.md"'
> buscar() { ...; }
> bash: syntax error near unexpected token `('
> ```
> Bash expande el alias **antes** de parsear la definición, y se queda con
> `find -name "*.md" () { ... }`. Hay que hacer `unalias` primero. El error no menciona
> alias por ningún lado.

---

# 3. Cómo saltarse un alias una vez

`\comando`, `'comando'` y `"comando"` hacen **exactamente lo mismo**.

## La prueba

```bash
$ alias echo='echo ALIAS:'
$ echo hola
ALIAS: hola
$ \echo hola
hola
$ "echo" hola
hola
$ 'echo' hola
hola
$ ec"ho" hola
hola
```

El último es el que revela el mecanismo: **comillar dos letras en medio de la palabra** anula
el alias igual que la diagonal.

## El mecanismo

La regla de bash: **la primera palabra de un comando se revisa contra la tabla de alias solo
si está *sin comillar*.**

No es que `\` sea especial. `\`, `'` y `"` son las tres formas de comillar, y cualquiera de
ellas, aplicada a **cualquier parte** de la palabra, la marca como comillada. Con eso deja de
calificar para expansión de alias.

Conecta con la otra rareza: **los alias se expanden al leer la línea, no al ejecutarla.** Por
eso `bash -c 'alias dc=cd; dc /tmp'` falla — toda la cadena se parsea de golpe, y cuando se
lee `dc` el alias todavía no existía. Y por eso los alias **no funcionan en scripts** salvo
que actives `shopt -s expand_aliases`.

### Cómo se rompe

> **`\comando` no "escapa un carácter especial" — anula la expansión de alias.** Cualquier
> comilla en cualquier parte de la primera palabra hace lo mismo.

> **Un alias que tapa un comando real es invisible hasta que falla.** Con
> `alias grep='grep --color'`, el día que un script se comporte raro, `type grep` te lo dice
> y `which grep` no. `which` es un programa externo que solo mira `$PATH`; `type` es un
> builtin y conoce el orden real: **alias → función → builtin → `$PATH`**. Para depurar,
> `type`.

---

# 4. Qué carga bash al iniciar

| Tipo de sesión | Qué lee |
|---|---|
| **interactive, no login** | `~/.bashrc` |
| **login** | `/etc/profile`, luego **el primero que exista** de `~/.bash_profile`, `~/.bash_login`, `~/.profile` |

Fíjate: **`.bashrc` no aparece en la lista de login.** En teoría, una sesión de login no
leería los alias.

## Por qué funciona igual en Ubuntu

El `~/.profile` por defecto trae este bloque:

```bash
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
```

La cadena es: **login → `.profile` → `source .bashrc`**. Las dos rutas terminan en el mismo
archivo.

**Conclusión práctica: los alias van en `.bashrc`.** Sirve en ambos casos.

Para saber en cuál estás:

```bash
$ shopt login_shell
login_shell     on      # o off
```

## `.bash_aliases`

**Bash no conoce ese archivo** — no está en ninguna de las dos listas. Funciona porque el
`.bashrc` de Ubuntu trae:

```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```

No es un archivo del sistema: es una convención de Ubuntu para no ensuciar el `.bashrc`.

**En mi home ya hay uno de 318 bytes desde el 16 de julio.** Revisarlo antes de agregar alias:
si defino uno con el mismo nombre en `.bashrc`, el orden de lectura decide cuál gana.

### Cómo se rompe

> **En una distro sin ese bloque en `.profile`, los alias desaparecen en sesiones de login.**
> Se ve como "mis alias funcionan en la terminal pero no por ssh". Diagnóstico:
> `shopt login_shell` en las dos sesiones y comparar.

---

# 5. Recargar la configuración: `source`

```bash
$ source ~/.bashrc
$ . ~/.bashrc          # idéntico, . es sinónimo de source
```

## Por qué no sirve ejecutar el archivo como script

```bash
$ bash conf.sh
$ echo "$MI_VAR"
                        # vacío
$ type saluda
bash: type: saluda: not found

$ source conf.sh
$ echo "$MI_VAR"
valor-nuevo
$ type saluda
saluda is aliased to `echo hola-desde-conf'
```

**El mecanismo:** ejecutar un script lanza un **proceso hijo**. El hijo define los alias y las
variables, y luego **muere**. Tu shell nunca se entera. `source` no lanza nada: lee el archivo
y ejecuta sus líneas *dentro* de tu shell, como si las hubieras tecleado.

Es la contracara de `export`: los hijos heredan del padre, nunca al revés.

## Por qué `source` infla el `$PATH`

El patrón estándar para agregar una ruta es:

```bash
export PATH="$PATH:/opt/mis-scripts"
```

Esa línea **lee `$PATH` y le concatena algo al final**. No comprueba si ya estaba. Cada
`source` la vuelve a ejecutar sobre un `$PATH` que ya la contiene:

```
inicio:      /usr/bin:/bin
1er source:  /usr/bin:/bin:/opt/mis-scripts
2do source:  /usr/bin:/bin:/opt/mis-scripts:/opt/mis-scripts
```

No es que `source` haga algo raro: la línea es **acumulativa por diseño** y `source` la corre
otra vez. Lo mismo pasaría tecleándola dos veces a mano.

### Cómo se rompe

> **`source` agrega, no reinicia.** Si borras un alias del `.bashrc` y haces `source`, el
> alias **sigue vivo** en tu sesión. Hay que hacer `unalias` a mano o abrir terminal nueva.

> **Para validar un cambio, abre una terminal nueva.** `source` sirve para probar rápido, pero
> arrastra el estado anterior y ensucia el `$PATH`. La única prueba honesta de que el
> `.bashrc` quedó bien es arrancar de cero.

---

# 6. `Ctrl-R` y el historial

`Ctrl-R` + un fragmento del comando: bash busca hacia atrás y muestra la coincidencia más
reciente.

| Tecla | Qué hace |
|---|---|
| `Ctrl-R` de nuevo | salta a la coincidencia anterior |
| `Enter` | **ejecuta** el comando |
| `→` o `Ctrl-E` | lo pone en la línea **para editarlo** sin ejecutarlo |
| `Ctrl-G` | cancela y restaura la línea original |

Reemplaza el ciclo de flechas y el copiar-pegar.

**Para contar frecuencias**, `history` alimenta a `awk`, `sort` y `uniq -c`. `sort` antes de
`uniq` no es opcional: `uniq` solo agrupa líneas **consecutivas**.

### Cómo se rompe

> **`Ctrl-S` (búsqueda hacia adelante) congela la terminal en muchos setups.** La terminal lo
> interpreta como control de flujo XOFF. `Ctrl-Q` descongela. Para desactivarlo:
> `stty -ixon` en el `.bashrc`.

> **El historial miente sobre frecuencias.** `HISTCONTROL=ignoreboth` (default de Ubuntu)
> descarta duplicados **consecutivos** — justo lo que más repites es lo que menos se guarda.
> Y `HISTSIZE=1000` acota la ventana. Un conteo de "mis comandos más usados" es en realidad
> "los más usados entre los últimos 1000, sin repeticiones seguidas".

---

# 7. Inodos

Un **inodo** es la estructura donde el sistema de archivos guarda todo lo de un archivo
*menos su nombre*: permisos, dueño, tamaño, fechas, y dónde están los bloques de datos.

El nombre no vive en el inodo. Vive en el **directorio**, que es una tabla de
`nombre → número de inodo`. Un directorio no "contiene" archivos: contiene punteros.

```bash
$ ls -i archivo.txt
573494 archivo.txt

$ stat -c 'inodo=%i enlaces=%h tamaño=%s' archivo.txt
inodo=573494 enlaces=1 tamaño=10
```

Esa separación explica cosas que si no parecen arbitrarias:

```bash
$ mv a.txt b.txt      # inodo 573494 → 573494   solo cambió la entrada del directorio
$ cp b.txt c.txt      # inodo 573494 → 573495   archivo nuevo, datos duplicados
```

`mv` dentro del mismo sistema de archivos es instantáneo aunque el archivo pese 4 GB: no mueve
datos, reescribe una línea de la tabla. `cp` sí copia bloques.

El campo `enlaces` cuenta cuántos nombres apuntan al inodo. **Borrar un archivo no borra
datos:** quita un nombre y baja el contador. Los datos se liberan cuando llega a cero.

---

# 8. Symlinks y por qué los dotfiles se instalan así

**El problema:** los programas buscan su configuración en una ruta fija — bash lee `~/.bashrc`
y punto, porque la tiene escrita adentro. Si quisiera tener los archivos en otra carpeta,
tendría que mantener actualizados los dos. El symlink lo evita: en la ruta predeterminada
pone un archivo que en realidad apunta al de mi carpeta.

```bash
ln -s ~/repo/scripts/dotfiles/.bashrc ~/.bashrc
```

Bash abre `~/.bashrc`, el kernel sigue el enlace, y lee el archivo del repo. Un solo archivo
real, bajo git.

## No es "el mismo archivo"

Un symlink es un archivo aparte, con su propio inodo, cuyo contenido es una **ruta**:

```bash
$ ls -li real.txt enlace.txt
573484 real.txt
573483 enlace.txt -> real.txt      # inodo DISTINTO

$ readlink enlace.txt
real.txt
```

Contrasta con un **hard link**, que sí es el mismo archivo con dos nombres:

```bash
$ ln b.txt hard.txt
$ ls -li b.txt hard.txt
573483 b.txt
573483 hard.txt                     # mismo inodo
```

| | Inodo | Qué guarda |
|---|---|---|
| **hard link** (`ln`) | **el mismo** | otro nombre para el mismo inodo |
| **symlink** (`ln -s`) | **distinto** | archivo aparte cuyo contenido es una ruta |

Escribir a través del symlink sí modifica el original, porque el kernel resuelve la ruta. Pero
el enlace y el destino son dos objetos distintos del sistema de archivos.

## Cómo se rompe

> **Si borras o mueves el destino, el symlink queda colgado (*dangling*) y sigue viéndose
> normal en `ls`.**
> ```bash
> $ rm real.txt
> $ ls -l enlace.txt
> lrwxrwxrwx 1 mlizz mlizz 8 enlace.txt -> real.txt     # ahí sigue
> $ cat enlace.txt
> cat: enlace.txt: No such file or directory
> ```
> El error dice "no existe" señalando un archivo que `ls` acaba de listar. Guarda una **ruta**,
> no una referencia al archivo: si la ruta deja de resolver, el enlace apunta al vacío.

> **`test -e` y `test -L` dan respuestas opuestas sobre un symlink roto.**
> ```bash
> $ test -e enlace.txt && echo sí || echo no
> no          # -e sigue el enlace: el destino no existe
> $ test -L enlace.txt && echo sí
> sí          # -L mira el enlace mismo: ahí está
> ```
> **Esto importa al escribir un instalador.** Validar con `[ -e ~/.bashrc ]` reporta "no hay
> nada" cuando en realidad hay un symlink roto de una corrida anterior. En instaladores,
> comprobar `-L` además de `-e`.

## Ya tengo symlinks vivos

En mi home:

```
lrwxrwxrwx  1 mlizz mlizz  23 .aws   -> /mnt/c/Users/mlizz/.aws/
lrwxrwxrwx  1 mlizz mlizz  25 .azure -> /mnt/c/Users/mlizz/.azure/
```

La `l` inicial de los permisos y la flecha son la firma. El instalador de Azure CLI resolvió
exactamente el mismo problema: la config tenía que estar en `~/.aws`, pero los archivos reales
viven del lado de Windows.

---

## Pendientes

- [ ] Leer `~/.bash_aliases` (318 bytes, 16 jul) — ¿qué hay ahí ya? ¿choca con algo nuevo?
- [ ] Correr `shopt login_shell` en una terminal nueva de WSL y anotar el resultado
- [ ] `2>&1` — sigue abierta desde `redireccion.md`
- [ ] `find -exec` y el `\;` — con la gramática de operators/options/tests/actions
- [ ] Mañana: probar `[ -e ]` vs `[ -L ]` sobre un enlace roto antes de escribir `install.sh`
