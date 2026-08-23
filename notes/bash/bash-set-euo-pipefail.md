# Notas — `set -euo pipefail`, globs, subshells y redirección

**Ejercicio de la sesión:** un script que recibe un directorio, cuenta las líneas de sus `.md`, y sale con `exit 1` si el directorio no existe. Con `set -euo pipefail` y ShellCheck a cero.

**Cómo leer estas notas:** el cuerpo es lo que trabajé y comprobé en la terminal, tal como lo entendí. Los bloques marcados son añadidos posteriores:

| Marca | Significado |
|---|---|
| 🔴 **Pendiente** | El ejercicio pedía esto y mis notas no llegaron a resolverlo |
| ➕ **Ampliación** | Detalle extra que completa lo que ya había entendido |
| ✅ **Comprobado** | Verificado ejecutándolo (bash 5.2.21, GNU/Linux) |

---

## Índice

1. [`set -u` y los parámetros posicionales](#1-set--u-y-los-parámetros-posicionales)
2. [`set -e` y el contador](#2-set--e-y-el-contador)
3. [El pipe crea un subshell](#3-el-pipe-crea-un-subshell)
4. [`wc -l archivo` vs `wc -l < archivo`](#4-wc--l-archivo-vs-wc--l--archivo)
5. [`set -e` no dispara dentro de un `if`](#5-set--e-no-dispara-dentro-de-un-if)
6. [Revisión del script final](#6-revisión-del-script-final-lo-que-todavía-falla)
7. [Chuleta](#7-chuleta)

---
---

# 1. `set -u` y los parámetros posicionales

## 1.1 ¿Qué es `set -u`?

`set -u` le dice a bash:

> **"Si intentas usar una variable que no está definida, considera eso un error."**

Su nombre largo es `nounset`. Sirve para cazar erratas: si escribes `$contadr` en lugar de `$contador`, sin `-u` bash lo expande silenciosamente a la cadena vacía y tu script sigue adelante dando resultados incorrectos. Con `-u`, se detiene y te avisa.

**Prueba en terminal:**

```bash
#!/usr/bin/env bash
set -u
echo "recibi: $1"
```

```
$ bash contar-lineas.sh /tmp
recibi: /tmp

$ bash contar-lineas.sh
contar-lineas.sh: line 3: $1: unbound variable
```

> **Nota sobre "sin argumentos":** significa invocar el script tal cual (`bash contar-lineas.sh`), sin pasarle nada detrás. El script sí tiene su código dentro; lo que falta es el dato que esperaba recibir desde fuera. Es la prueba de qué pasa cuando el usuario se olvida de escribir el directorio.

## 1.2 `${1:-}` — valores por defecto

De `man bash`, sobre `${parameter:-word}` (*Use Default Values*), en mis palabras:

> Si el parámetro está **sin definir** o **vacío**, se sustituye por la expansión de *word*. En caso contrario, se sustituye por el valor del parámetro.

```bash
#!/usr/bin/env bash
set -u
echo "${1:-}"
```

```
$ bash contar-lineas.sh
                              ← línea vacía, pero NO muere

$ bash contar-lineas.sh /tmp
/tmp
```

Es decir, `${1:-}` significa: *"si `$1` está sin definir o vacía, usa el valor que va después de `:-`"* — y aquí ese valor por defecto es **la cadena vacía**. Como ya hay algo con lo que sustituir, `set -u` ya no tiene de qué quejarse.

Con un valor por defecto de verdad:

```bash
#!/usr/bin/env bash
set -u
echo "${1:-nada}"
```

```
$ bash contar-lineas.sh
nada
```

> ➕ **Ampliación — por qué conviene entrecomillar igual.**
> En mis pruebas escribí `echo ${1:-}` sin comillas y funcionó. Pero el resultado de una expansión sin comillas sufre *word splitting* y *globbing*: si alguien invoca el script con un argumento como `*` o `hola mundo`, el `echo` imprime otra cosa. Costumbre sana: `"${1:-}"`, siempre con comillas.
>
> En el script final quedó bien: `directorio="${1:-}"`. ✅

## 1.3 `${1-}` vs `${1:-}` — los dos puntos importan

Los dos puntos añaden **"o está vacía"** a la condición.

| Estado de `$1` | `${1-DEFAULT}` | `${1:-DEFAULT}` |
|---|---|---|
| Sin definir (no se pasó argumento) | `DEFAULT` | `DEFAULT` |
| Definida pero **vacía** (`""`) | `""` ← vacía | `DEFAULT` |
| Definida con valor | el valor | el valor |

Dicho corto: **`-` solo mira si existe; `:-` mira si existe *y además* tiene contenido.**

> ✅ **Comprobado:**
> ```bash
> $ bash -c 'set -u; set -- ""; printf "[%s]\n" "${1-DEFAULT}" "${1:-DEFAULT}"'
> []
> [DEFAULT]
> ```
> Con `$1` definida pero vacía, `${1-}` la deja vacía y `${1:-}` sí mete el valor por defecto.

> ➕ **Ampliación — la familia completa.** Esta lógica de los dos puntos se repite en cuatro operadores:
>
> | Operador | Qué hace |
> |---|---|
> | `${var:-valor}` | **Usa** el valor por defecto (no toca la variable) |
> | `${var:=valor}` | **Asigna** el valor por defecto a la variable y lo usa |
> | `${var:?mensaje}` | **Aborta** con ese mensaje de error si está vacía/sin definir |
> | `${var:+valor}` | Al revés: usa el valor **solo si** la variable SÍ tiene contenido |
>
> El tercero es interesante para este ejercicio: `${1:?falta el directorio}` valida y aborta en una sola línea.

## 1.4 La excepción de `"$@"` y `"$*"`

Segunda prueba del ejercicio: `echo "$@"` sin argumentos **no mata el script**, a diferencia de `echo "$1"`.

**Con `$1`:**

```
set -u
echo "$1"

bash script.sh          ← sin argumentos

$1
 ↓
NO EXISTE
 ↓
❌ set -u: "estás usando un parámetro que no existe"
```

**Con `$@`:**

```
set -u
echo "$@"

$@
 ↓
"todos los argumentos"
 ↓
no hay argumentos
 ↓
CERO argumentos ← que es una cantidad perfectamente válida
 ↓
✅ echo recibe cero argumentos e imprime una línea vacía
```

La diferencia de fondo: `$1` pregunta *"¿cuál es el primer argumento?"* y la respuesta puede no existir. `$@` pregunta *"¿cuál es la lista de argumentos?"* y la respuesta siempre existe, aunque esa lista tenga longitud cero. **Una lista vacía no es lo mismo que una variable indefinida.**

> ✅ **Comprobado:** `set -u; echo "$@"; echo sobrevivio` con cero argumentos → sale exit 0 e imprime `sobrevivio`.
>
> ➕ **Ampliación:** esto está garantizado a partir de **bash 4.4**. En versiones anteriores, `"$@"` con cero parámetros bajo `set -u` podía dar `unbound variable` en algunos contextos. Si algún día un script tuyo tiene que correr en un sistema antiguo, la forma defensiva es `${@:-}`.

## 1.5 Por qué `"$@"` va entre comillas

`"$@"` entre comillas tiene un comportamiento **especial y único** en todo bash.

```bash
bash script.sh uno "dos tres" cuatro
```

```
$1 = uno
$2 = dos tres
$3 = cuatro
```

`echo "$@"` se expande conceptualmente a:

```bash
echo "uno" "dos tres" "cuatro"
```

Es decir: **cada argumento sigue siendo un argumento independiente**, con sus espacios internos intactos. Es la única expansión en bash que produce *varias* palabras estando entre comillas.

Por eso lo ves constantemente en scripts que reenvían todos sus argumentos a otro comando.

> ➕ **Ampliación — la tabla de las cuatro variantes.** Con los mismos argumentos de arriba:
>
> | Escrito | Resultado | Palabras |
> |---|---|---|
> | `"$@"` | `uno` / `dos tres` / `cuatro` | 3 ✅ correcto |
> | `$@` | `uno` / `dos` / `tres` / `cuatro` | 4 ❌ rompe el que tenía espacio |
> | `"$*"` | `uno dos tres cuatro` | 1 ❌ todo pegado en un string |
> | `$*` | `uno` / `dos` / `tres` / `cuatro` | 4 ❌ igual de roto |
>
> `"$*"` une los argumentos usando el **primer carácter de `$IFS`**. Solo sirve cuando quieres deliberadamente un texto único, por ejemplo para un mensaje.

## ✔ Lo que me llevo de la práctica 1

- `set -u` = aborta si usas una variable indefinida. Caza erratas.
- `${1:-}` le da un valor por defecto y desactiva la queja de `set -u`.
- `:-` considera vacía **y** sin definir; `-` solo sin definir.
- `"$@"` es la lista de argumentos: con cero elementos sigue siendo válida, por eso `set -u` no protesta.
- `"$@"` **siempre con comillas**: es la única expansión que devuelve varias palabras estando entrecomillada.

---
---

# 2. `set -e` y el contador

## 2.1 ¿Qué es `set -e`?

`set -e` (nombre largo: `errexit`) le dice a bash, aproximadamente:

> **"Si un comando devuelve un código de salida distinto de 0, termina el script."**

La idea es no seguir trabajando sobre un estado roto. En la práctica tiene muchas excepciones — la práctica 5 trata una de ellas.

## 2.2 🔴 Pendiente: la trampa de `((total++))`

El enunciado decía:

> *"Acumula el total en una variable con `((total++))` empezando en cero, con `set -e`. El script se va a morir en la primera vuelta y el mensaje no va a decir por qué. Esa es la sesión de hoy en una línea."*

En la sesión escribí directamente `contador=$((contador + 1))` y el script funcionó, así que **nunca llegué a ver por qué moría la versión con `((total++))`**. Y era el punto central del ejercicio. Aquí está:

```bash
total=0
((total++))
echo $?        # → 1
```

Hay dos piezas encajando:

**Pieza 1: `(( ))` invierte la lógica respecto a un comando normal.**

`(( expresión ))` devuelve:
- **exit status 0** (éxito) si el resultado aritmético es **distinto de cero**
- **exit status 1** (fallo) si el resultado aritmético es **cero**

Imita la noción de verdad de C, donde 0 es falso. Pero como en bash 0 significa éxito, el resultado queda del revés respecto a lo que uno espera.

**Pieza 2: `total++` es post-incremento, y el valor de la expresión es el valor ANTIGUO.**

```
total = 0
        ↓
((total++))
        ↓
la variable pasa a valer 1  ✅ (el incremento sí ocurre)
pero el VALOR DE LA EXPRESIÓN es 0  ← el valor de antes
        ↓
resultado aritmético = 0
        ↓
(( )) devuelve exit status 1
        ↓
set -e mata el script
```

Y bash **no imprime absolutamente nada**. No hay mensaje de error porque, técnicamente, nada falló: un comando devolvió 1 y `errexit` hizo su trabajo. De ahí lo de *"el mensaje no va a decir por qué"*.

> ✅ **Comprobado:**
> ```
> $ bash -c 'set -e; total=0; echo "antes"; ((total++)); echo "despues"'
> antes
> $ echo $?
> 1
> ```
> `despues` nunca se imprime. Cero mensajes de error. Y ocurre **solo en la primera vuelta**: a partir de `total=1` el valor antiguo ya es distinto de cero y el problema desaparece — lo cual lo hace todavía más traicionero, porque en otro contexto el bug podría tardar meses en aparecer.

**Las cuatro formas de escribirlo y qué pasa con cada una:**

| Escrito | Con `total=0` | ¿Seguro? |
|---|---|---|
| `((total++))` | exit **1** → muere con `set -e` | ❌ |
| `((++total))` | exit 0, porque el pre-incremento devuelve el valor **nuevo** (1) | ⚠️ funciona **de casualidad**; falla si `total` empieza en `-1` |
| `((total++)) \|\| true` | exit 0 forzado | ✅ funciona, pero es un parche |
| `total=$((total + 1))` | exit 0 **siempre** | ✅ **el que usé, y el correcto** |

**Por qué la última es la buena:** `$(( ))` (con `$`) es una **expansión**, no un comando: produce un texto. Y una **asignación** devuelve exit status 0 pase lo que pase con el número. No hay ninguna forma de que `set -e` se enfade con ella.

Así que mi instinto en la sesión fue el correcto — ahora ya sé el motivo, que era lo que el ejercicio quería enseñarme.

> ➕ **Ampliación — esto es el pitfall #22 del wiki de Greg**, el de `cmd1 && cmd2 || cmd3`. El ejemplo canónico de allí es exactamente este:
> ```bash
> i=0
> true && ((i++)) || ((i--))   # ¡MAL!
> echo "$i"                    # imprime 0: se ejecutaron AMBOS
> ```
> Se ejecutan los dos porque `((i++))` devolvió 1 (falso) y eso disparó la rama del `||`.
>
> **La regla general:** desconfía de `(( ))` como comando suelto cuando el resultado pueda valer cero. Como *expansión* (`$(( ))`) no tiene ningún problema.

## 2.3 El glob que no coincide con nada

Idea inicial:

```bash
set -e
contador=0

for archivo in "$1"/*.md
do
    contador=$((contador + 1))
done
echo "El directorio $1 contiene $contador archivos .md"
```

**El problema:** si no existe ningún `.md`, bash deja el patrón **literalmente** como `"$1"/*.md`. El `for` lo interpreta como un elemento más y el contador termina en **1** en lugar de 0.

> ➕ **Ampliación — el detalle de comillas que hice bien.** En `"$1"/*.md` las comillas cubren **solo** `$1`, y `/*.md` queda fuera. Eso es exactamente lo que se necesita:
> - la parte entrecomillada protege el nombre del directorio (si tiene espacios, no se parte);
> - la parte sin comillas conserva su capacidad de expandirse como glob.
>
> Si hubiera escrito `"$1/*.md"` con todo dentro, el `*` sería texto literal y el glob nunca se expandiría.

## 2.4 La solución: `[ -e "$archivo" ] || continue`

```bash
#!/usr/bin/env bash
set -e
contador=0

for archivo in "$1"/*.md
do
    [ -e "$archivo" ] || continue
    contador=$((contador + 1))
done
echo "El directorio $1 contiene $contador archivos .md"
```

El `continue` hace que se salte a la siguiente iteración. Si el glob se quedó literal, `$archivo` contiene un nombre que no existe, `[ -e ... ]` falla, y esa vuelta no cuenta.

**¿Por qué no `nullglob`?**

`shopt -s nullglob` cambia el comportamiento de **todos los globs posteriores del script**: hace que cualquier patrón sin coincidencias se expanda a **cero palabras**, en lugar de quedarse literalmente como `*.md`.

Resuelve el problema, sí, pero es un interruptor **global**: afecta a cualquier otro glob del script, incluidos los que escriba más adelante sin acordarme de que está activo. `[ -e "$archivo" ] || continue` es **local**: solo afecta a este bucle, y se lee en el sitio donde importa.

> ➕ **Ampliación — `set -e` y el `continue`.** Ojo con una sutileza: `[ -e "$archivo" ]` está fallando a propósito, y `set -e` no lo mata. ¿Por qué? Porque es el lado izquierdo de un `||`, y ese es uno de los contextos exceptuados. Es el mismo mecanismo de la práctica 5, apareciendo aquí sin que me diera cuenta.

## 2.5 Evidencia de la terminal

```
$ bash contar-lineas.sh ~/.../lecture02/files
El directorio /home/mlizz/.../lecture02/files contiene 0 archivos .md

$ bash contar-lineas.sh ~/.../lecture02/
El directorio /home/mlizz/.../lecture02/ contiene 2 archivos .md
```

El `0` del primer caso es la prueba de que el arreglo funciona: sin `[ -e ]` habría dicho `1`.

## ✔ Lo que me llevo de la práctica 2

- `set -e` = aborta si un comando devuelve algo distinto de 0.
- **`((total++))` devuelve exit 1 cuando `total` vale 0**, porque el post-incremento entrega el valor antiguo y `(( ))` considera "fallo" el resultado cero. Con `set -e`, muerte silenciosa.
- `total=$((total + 1))` es inmune: una asignación siempre devuelve 0.
- Un glob sin coincidencias se queda literal → `[ -e "$x" ] || continue` (local) o `shopt -s nullglob` (global).
- En `"$1"/*.md`, las comillas van solo alrededor de `$1`.

---
---

# 3. El pipe crea un subshell

## 3.1 La versión incorrecta

```bash
contador=0
find "$1" -type f -name "*.md" |
    while read -r archivo; do
        contador=$((contador + 1))
    done
echo "El directorio $1 contiene $contador archivos .md"
```

Imprime siempre **0**.

## 3.2 Por qué

**El pipe ejecuta el `while` en un subshell.** Un subshell es un proceso hijo con su **propia copia** de las variables. El hijo puede leer las del padre, pero cuando termina, todos sus cambios se van con él.

```
        shell principal
        contador = 0
              │
      ┌───────┴────────┐
      │                │
    find          SUBSHELL
                  contador = 0 → 1 → 2 → 3
                       │
                  (el proceso muere)
                       ✗
        shell principal
        contador = 0    ← nunca se enteró
```

Los datos fluyen hacia adelante por el pipe. Las variables **no fluyen hacia atrás**.

## 3.3 La solución: *process substitution*

```bash
contador=0
while read -r archivo; do
    contador=$((contador + 1))
done < <(find "$1" -type f -name "*.md")
echo "$contador"
```

Desarmando la línea, que es la parte que más cuesta leer:

**`read -r archivo`** significa: *lee una línea de stdin y guárdala en la variable `archivo`*.

Pero, ¿de dónde viene ese stdin? Lo estamos proporcionando con lo que va después del `done`.

**`< algo`** significa: *haz que la entrada estándar del `while` venga de aquí*.

**`<(find ...)`** — bash ejecuta el `find` y conecta su salida a **una especie de archivo temporal especial** que bash puede ofrecer como entrada.

```
      done  <  <( find ... )
            │      │
            │      └── ejecuta find y expone su salida como si fuera un archivo
            └───────── redirige la entrada estándar del while a ese "archivo"
```

**La clave: ya no hay pipe.** Y sin pipe, no hay subshell, así que el `while` corre en el shell principal y `contador` sobrevive al bucle.

> ➕ **Ampliación — los dos flags de `read` que faltan.**
>
> La versión completamente robusta es:
> ```bash
> while IFS= read -r archivo; do ...
> ```
> - **`-r`** (que sí puse): evita que `read` interprete `\` como carácter de escape. Un nombre de archivo puede contener backslashes.
> - **`IFS=`** (que no puse): con `IFS` vacío, `read` **no recorta** los espacios y tabulaciones del principio y del final de la línea. Con el `IFS` por defecto sí los recorta, así que un archivo llamado `  notas.md` perdería sus espacios iniciales y luego `wc` no lo encontraría.
>
> El `IFS=` delante del comando solo aplica a ese comando; no cambia el `IFS` del resto del script.
>
> Y para el caso patológico —un nombre de archivo que contenga un salto de línea— la forma blindada usa el byte NUL como separador, que es el único byte que no puede aparecer en un nombre:
> ```bash
> while IFS= read -r -d '' archivo; do
>     ...
> done < <(find "$1" -type f -name '*.md' -print0)
> ```
> `-print0` separa con NUL y `-d ''` le dice a `read` que use NUL como delimitador.

> ➕ **Ampliación — otras salidas al mismo problema.**
> - `shopt -s lastpipe` hace que el último comando del pipe corra en el shell principal. Pero solo funciona en modo no interactivo y con el control de trabajos desactivado; es frágil.
> - A veces la solución más simple es no necesitar la variable: `find ... | wc -l` te da la cuenta directamente.

## ✔ Lo que me llevo de la práctica 3

- Cada lado de un pipe corre en un **subshell**: las variables que modifiques ahí se pierden.
- `done < <(comando)` (*process substitution*) elimina el pipe y mantiene el bucle en el shell actual.
- `read -r` siempre; `IFS= read -r` si los datos pueden llevar espacios en las orillas.

---
---

# 4. `wc -l archivo` vs `wc -l < archivo`

## 4.1 La prueba

```bash
printf '%s\n' uno dos tres cuatro > archivo
```

`archivo` tiene 4 líneas.

```
$ wc -l archivo
4 archivo

$ wc -l < archivo
4
```

## 4.2 Por qué en un caso aparece el nombre y en el otro no

**Caso A — como argumento:**

```
wc
 │
 └── argumento: "archivo"
         ↓
    abre archivo
         ↓
    cuenta líneas
         ↓
    imprime: 4 archivo
```

Aquí le estás diciendo a `wc`: *"abre este archivo, que se llama `archivo`, y cuenta sus líneas."* `wc` sabe dos cosas: cuántas líneas hay **y cómo se llama el archivo**. Por eso puede imprimir el nombre — lo tiene porque tú se lo diste.

**Caso B — por redirección:**

El `<` no le pasa `archivo` como argumento a `wc`. **El `<` es una instrucción para el shell, no para `wc`:**

```
                 SHELL
                   │
          abre "archivo"
                   │
                   │ contenido
                   ▼
                 stdin
                   │
                   ▼
                 wc -l
```

`wc` recibe:

```
uno
dos
tres
cuatro
```

pero **no recibe la palabra `archivo` como argumento**. Desde el punto de vista de `wc`, alguien le entregó un chorro de datos por su entrada estándar y ya. No hay ningún nombre asociado a esos datos, porque los nombres de archivo viven en el sistema de archivos y `wc` nunca tocó el sistema de archivos: el shell ya lo había hecho por él y le pasó solo el contenido.

Por eso `wc` solo puede decir `4`. **No tiene un nombre que mostrar porque nunca recibió uno.**

> ➕ **Ampliación — la analogía que lo cierra.** Es como pedir un libro en una biblioteca de dos formas distintas:
> - *"Cuenta las páginas de `El Quijote`"* → tú abres el libro, ves la portada, y puedes responder "863 páginas, El Quijote".
> - Alguien te pasa un fajo de hojas sueltas por debajo de la puerta → cuentas 863, pero no puedes decir de qué libro son. Nadie te lo dijo, y las hojas no lo llevan escrito.
>
> El `<` es "el fajo de hojas por debajo de la puerta": el shell ya abrió el libro y te pasó solo el contenido.

## 4.3 🔴 Pendiente: "¿solo `wc` y `while` toman argumentos?"

Esta pregunta se me quedó sin responder en la sesión. Son dos preguntas mezcladas:

### (a) ¿Qué comandos aceptan un nombre de archivo como argumento?

No es cosa de `wc`: es una **convención general de Unix** para los programas llamados *filtros*:

> Si les das nombres de archivo como argumentos, leen esos archivos. Si no les das ninguno, leen de **stdin**.

Se comportan así: `cat`, `grep`, `wc`, `sort`, `head`, `tail`, `cut`, `uniq`, `nl`, `sed`, `awk`, `md5sum`…

Y hay tres grupos distintos:

| Grupo | Comportamiento | Ejemplos |
|---|---|---|
| **Filtros** | Aceptan archivos como argumento; si no hay, leen stdin | `cat`, `grep`, `wc`, `sort`, `head`, `sed`, `awk` |
| **Solo stdin** | Nunca aceptan un nombre de archivo; **siempre** hay que redirigir o hacer pipe | `tr`, `xargs` |
| **Solo argumentos** | Nunca leen stdin; los argumentos son los datos, no rutas que abrir | `echo`, `printf`, `ls`, `cp`, `mv`, `rm` |

Por eso `tr a-z A-Z archivo.txt` **no funciona**: hay que escribir `tr a-z A-Z < archivo.txt`.

Y de los que aceptan ambas cosas, los que **imprimen el nombre** cuando lo tienen (y lo omiten cuando no) son sobre todo `wc`, `grep` con varios archivos, y los `*sum` (`md5sum`, `sha256sum`).

### (b) ¿Y `while`?

`while` es una categoría **completamente distinta**. No es un comando: es una **palabra clave del shell**.

> ✅ **Comprobado:**
> ```
> $ type wc
> wc is /usr/bin/wc            ← un programa
> $ type while
> while is a shell keyword     ← sintaxis del lenguaje
> $ type [
> [ is a shell builtin         ← un comando interno
> ```

`while` no "toma" un archivo ni podría hacerlo. Lo que ocurre es que la **redirección `< archivo` se aplica al comando compuesto completo**, y eso fija el stdin de **todo lo que hay dentro del bucle**. `read` es quien realmente lee — y lee de stdin, que el shell ya dejó apuntando al sitio correcto.

```
while read -r linea; do
    ...
done < archivo
     └──────────── esta redirección se la aplica el SHELL al bucle entero,
                   igual que se la aplicaría a wc. El bucle no "recibe" nada.
```

Es exactamente el mismo mecanismo que en `wc -l < archivo`. El shell abre el archivo y conecta su contenido a la entrada estándar de lo que venga. Lo único que cambia es qué hay al otro lado: un programa (`wc`) o un bloque de código (`while ... done`).

Con esto se conecta con lo que ya había escrito:

```bash
contador=0
while read -r archivo
do
    contador=$((contador + 1))
done < archivo

echo "$contador"
```

> El archivo no se convierte en un argumento del `while`. Su contenido se convierte en la **entrada estándar** del `while`.

## 4.4 Por qué esto decide si la suma funciona

Este era el objetivo real del ejercicio 4. En el script hay que hacer:

```bash
lineas=$(wc -l < "$archivo")
contador=$((contador + lineas))
```

Si hubiera escrito `wc -l "$archivo"` (con argumento), la variable `lineas` valdría `3 completo.md` en lugar de `3`, y la suma aritmética explotaría.

> ✅ **Comprobado:**
> ```
> $ lineas=$(wc -l completo.md); echo "[$lineas]"
> [3 completo.md]
> $ echo $((contador + lineas))
> bash: 3 completo.md: syntax error: invalid arithmetic operator (error token is ".md")
> ```

**Por eso `wc -l < "$archivo"` no es una manía de estilo: es lo que hace que la suma sea posible.** Necesitas un número limpio, y la única forma de que `wc` no te añada el nombre es no dárselo.

> ➕ **Ampliación — el defecto de `wc -l` que hay que conocer.** `wc -l` no cuenta líneas: cuenta **saltos de línea**. Si un archivo no termina en `\n`, la última línea no se cuenta.
>
> ✅ **Comprobado:**
> ```
> completo.md (3 líneas, termina en \n)          → wc dice: 3  ✅
> sin_salto_final.md (3 líneas, sin \n al final) → wc dice: 2  ❌
> ```
> La alternativa exacta es `grep -c '' archivo`, que cuenta líneas de verdad (dio 3 en el caso de arriba).
>
> **Pero cuidado, y aquí se juntan tres cosas de esta sesión:** `grep` devuelve exit status 1 cuando no encuentra coincidencias, y un archivo `.md` **vacío** no tiene ninguna línea. Con `set -e`:
> ```
> $ bash -c 'set -e; lineas=$(grep -c "" vacio.md); echo "despues"'
> $ echo $?
> 1                    ← el script murió, y "despues" nunca se imprimió
> ```
> Una asignación devuelve 0… **salvo** si su lado derecho es una sustitución de comandos, en cuyo caso hereda el exit status de ese comando. Es la excepción a la regla de la práctica 2.
>
> Conclusión práctica: `wc -l < archivo` es la opción **segura bajo `set -e`**, a costa de perder la última línea si falta el `\n` final. Es un compromiso razonable y es el que dejo en el script.

## ✔ Lo que me llevo de la práctica 4

- `<` es una instrucción **para el shell**, no para el comando. El shell abre el archivo y conecta el contenido a stdin.
- `wc -l archivo` imprime `4 archivo`; `wc -l < archivo` imprime `4`. La diferencia es si `wc` recibió un nombre.
- Para sumar hace falta un número limpio → **`wc -l < "$archivo"`**.
- La convención de "argumentos o stdin" es general en Unix; `tr` solo lee stdin, `echo` solo lee argumentos.
- `while` no es un comando sino una palabra clave; la redirección se la aplica el shell al bloque completo.
- `wc -l` cuenta saltos de línea, no líneas.

---
---
# 4.5 Un exit status diferente de 0 no termina un script, set -e si lo hace...
La convención completa es: 0 = éxito, 1 = ausencia o negativa, 2+ = error real. Muchas herramientas la siguen, pero no es obligatoria — por eso man tiene sección "EXIT STATUS" y por eso tu --help lleva la tabla.

Una trampa que sale de ahí y que sí te va a morder: bajo set -e, un grep que no encuentra nada mata tu script. Es el caso más común de "mi script murió y no sé por qué". El arreglo es grep ... || true cuando no encontrar es un resultado aceptable.

Exit 0 es la única convención universal. El resto lo define cada programa: grep sale con 1 cuando no encuentra, diff cuando hay diferencias — no son fallos. Bajo set -e, un grep sin coincidencias mata el script; || true si no encontrar es aceptable.

# 5. `set -e` no dispara dentro de un `if`

## 5.1 La prueba

```bash
#!/usr/bin/env bash
set -e

if [ -d "$1" ]; then
    echo "El directorio existe"
fi

echo "El script continúa"
```

```
$ bash script.sh /no/existe
El script continúa
```

## 5.2 ¿Pero no debería `set -e` matar el script?

Recordemos que `[ -d "$1" ]` es un **comando** que devuelve un exit status:

```
directorio existe:        directorio NO existe:
[ -d "$1" ]               [ -d "$1" ]
     ↓                         ↓
  verdadero                  falso
     ↓                         ↓
exit status = 0            exit status ≠ 0
```

Entonces uno esperaría:

```
set -e
   ↓
[ -d "$1" ] falla
   ↓
¡termina el script!
```

**Pero bash tiene una excepción muy importante:**

> **Los comandos usados como condición de un `if` no provocan que `set -e` termine el script cuando devuelven un estado distinto de cero.**

Y tiene todo el sentido: si un `if` muriera cada vez que su condición es falsa, el `if` sería inútil. **Un `if` con condición falsa no es un error: es información.**

> ➕ **Ampliación — la lista completa de contextos exceptuados.** `set -e` NO dispara cuando el comando que falla está en:
>
> | Contexto | Ejemplo |
> |---|---|
> | La condición de un `if` o `elif` | `if [ -d "$1" ]; then` |
> | La condición de un `while` o `until` | `while [ -d "$1" ]; do` |
> | Cualquier comando de una cadena `&&` / `\|\|` **excepto el último** | `[ -e "$f" ] \|\| continue` |
> | Un comando negado con `!` | `! grep -q foo archivo` |
>
> ✅ **Comprobado, los cuatro sobreviven.** Y el que sí mata: `[ -d /no/existe ]` **suelto**, en una línea propia, sin `if` ni `||`.
>
> **La regla mental:** `set -e` dispara cuando un comando falla y **nadie estaba mirando su resultado**. Si tú ya estás comprobando el estado (con `if`, `while`, `&&`, `||` o `!`), bash entiende que sabes lo que haces y se aparta.
>
> Esto explica retroactivamente por qué el `[ -e "$archivo" ] || continue` de la práctica 2 no mataba el script: estaba a la izquierda de un `||`.

## 5.3 Primera versión del script completo

```bash
set -eu

if [ -d "$1" ]; then
    contador=0
    while read -r archivo; do
        while read -r linea; do
            contador=$((contador + 1))
        done < "$archivo"
    done < <(find "$1" -type f -name "*.md")
    echo "El directorio $1 contiene $contador líneas en archivos .md"
else
    echo "Error: el directorio no existe"
    exit 1
fi
```

El bucle interno cuenta líneas leyéndolas una a una. Funciona, pero es lento: para un archivo de 10.000 líneas, bash da 10.000 vueltas. `wc` hace lo mismo en una llamada.

## 5.4 ¿Qué es `set -o` y qué es `pipefail`?

**`set -o`** es la forma **larga** de escribir las mismas opciones. Cada letra corta tiene un nombre:

| Corta | Larga | Qué hace |
|---|---|---|
| `-e` | `set -o errexit` | Sale si un comando falla |
| `-u` | `set -o nounset` | Error si usas una variable indefinida |
| `-x` | `set -o xtrace` | Imprime cada comando antes de ejecutarlo (para depurar) |
| — | `set -o pipefail` | **No tiene letra corta** |

Por eso `pipefail` **no se activa con `-p`**. Hay que escribir `set -o pipefail`, y bash permite combinarlo así:

```bash
set -euo pipefail
```

que se lee como: `-e`, `-u`, y `-o pipefail`.

> ➕ **Truco:** `set -o` a secas, sin argumentos, imprime la lista de todas las opciones con su estado actual.

**¿Qué hace `pipefail`?**

Normalmente, el exit status de un pipe completo es el **del último comando**.

```
comando1 | comando2
   ❌          ✅
                ↑
          último comando
                ↓
          pipe = éxito
```

Es decir, el pipe puede terminar con `exit status = 0` **aunque `comando1` haya fallado**. Ejemplo mínimo:

```
false | true
  ❌      ✅
          ↓
      pipe = 0
          ↓
set -e no hace nada
          ↓
"llegué aquí"
```

Con `pipefail` activado, si **cualquier** parte del pipe devuelve distinto de cero, el pipe entero devuelve distinto de cero:

```
false | true
  ❌      ✅
   ↓
pipe = ❌
   ↓
set -e
   ↓
termina el script
```

> ➕ **Ampliación — dos matices importantes sobre `pipefail`.**
>
> **1. En este script no hace nada.** El script final no tiene ni un solo pipe. `pipefail` está ahí por costumbre, no porque cambie algo. No está mal dejarlo, pero conviene saber que no está protegiendo nada aquí.
>
> **2. Puede causar falsos fallos.** El caso clásico:
> ```bash
> if algún_comando | grep -q foo; then
>     echo "encontrado"
> else
>     echo "no encontrado"
> fi
> ```
> `grep -q` sale en cuanto encuentra la primera coincidencia, sin leer el resto. Cuando `algún_comando` intenta escribir el siguiente trozo, el otro extremo del pipe ya está cerrado y el sistema le manda **SIGPIPE**, que lo hace terminar con estado distinto de cero. Con `pipefail`, el pipe entero se marca como fallido **aunque `foo` sí se haya encontrado**, y el script dice "no encontrado".
>
> Por eso el wiki de Greg (pitfall #60) recomienda activar `pipefail` solo alrededor de los pipes concretos donde lo necesites, no de forma global. `set -euo pipefail` es una fórmula popular, pero no es magia: cada una de las tres tiene sus trampas.

## ✔ Lo que me llevo de la práctica 5

- `set -e` **no dispara** cuando el comando que falla es una condición de `if`/`while`, está a la izquierda de `&&`/`||`, o va negado con `!`. Un `if` falso no es un error.
- `set -o nombre` es la forma larga; `pipefail` solo existe en forma larga.
- Sin `pipefail`, el exit status de un pipe es el del **último** comando.
- `pipefail` no siempre es deseable: con `cmd | grep -q` produce falsos fallos por SIGPIPE.

---
---

# 6. Revisión del script final

Versión final, ya con las dos correcciones aplicadas:

```bash
#!/usr/bin/env bash
set -euo pipefail

directorio="${1:-}"

if [ -d "$directorio" ]; then
    contador=0

    while read -r archivo; do
        lineas=$(wc -l < "$archivo")
        contador=$((contador + lineas))
    done < <(find "$directorio" -type f -name "*.md")

    echo "El directorio $directorio contiene $contador líneas en archivos .md"
else
    echo "Error: el directorio no existe" >&2
    exit 1
fi
```

## 6.1 Requisitos del ejercicio

| Requisito | Estado |
|---|---|
| Recibe un directorio | ✅ |
| Cuenta las líneas de los `.md` | ✅ |
| `exit 1` si no existe | ✅ |
| `set -euo pipefail` | ✅ |
| **ShellCheck a cero** | ✅ verificado, sin un solo aviso |

> ✅ **Comprobado** (bash 5.2.21):
> ```
> $ shellcheck script.sh                → cero avisos
>
> $ bash script.sh                      → "Error: el directorio no existe" (stderr)
> $ echo $?                             → 1
>
> $ bash script.sh /no/existe           → "Error: el directorio no existe" (stderr)
> $ echo $?                             → 1
>
> $ bash script.sh .                    → "El directorio . contiene 6 líneas en archivos .md"
> $ echo $?                             → 0
> ```
> Probado también con un `.md` dentro de una carpeta llamada `sub carpeta/con espacios.md`: lo cuenta bien.

## 6.2 Las dos correcciones, y por qué funcionan

### `directorio="${1:-}"`

Sin esto, con `set -u` activo y sin argumentos, bash moría en la línea del `if` con `$1: unbound variable`, **antes de llegar al `else`**. El mensaje de error propio nunca se llegaba a imprimir.

La cadena completa ahora:

```
bash script.sh          ← sin argumentos
        ↓
directorio="${1:-}"     ← $1 no existe → se usa el valor por defecto: ""
        ↓
set -u ya no tiene de qué quejarse: la variable SÍ está definida
        ↓
[ -d "" ]               ← la cadena vacía no es un directorio → falso
        ↓
else
        ↓
mensaje de error + exit 1   ✅
```

> ➕ **El detalle elegante:** una sola rama cubre los dos casos de fallo — *"no me diste nada"* y *"me diste algo que no existe"*. Ambos acaban con `[ -d "$directorio" ]` en falso. Por eso no hacen falta dos `if` separados: la cadena vacía se comporta como un directorio inexistente, que es justo lo que se necesita.
>
> El único matiz es que el mensaje dice *"el directorio no existe"* también cuando no se pasó ningún argumento, que es cierto pero poco informativo. Si algún día quieres afinarlo, `${1:?Uso: se requiere un directorio}` aborta con mensaje propio en la misma línea de la asignación.

También está bien puesto lo de **entrecomillar** la expansión: `"${1:-}"` y no `${1:-}`. Si alguien invocara el script con un argumento como `*`, sin comillas el resultado sufriría globbing.

### `>&2`

`echo "Error: ..."` sin más va a **stdout**, mezclado con la salida normal. Con `>&2` va a **stderr**, que es donde pertenecen los errores.

La diferencia se nota al redirigir:

```bash
bash script.sh /no/existe > resultado.txt
```

Sin `>&2`, el mensaje de error acabaría **dentro de `resultado.txt`** y la terminal se quedaría muda. Con `>&2`, `resultado.txt` queda vacío (correcto: no hubo resultado) y el error aparece en pantalla. Así puede verlo un humano y a la vez no contamina la salida que otro programa vaya a procesar.

## 6.3 Lo único que queda: nombres de archivo patológicos

Es el punto de la práctica 3 que no llegó al script: `while read -r` sin `IFS=`, y `find` sin `-print0`. Son dos casos raros pero **reales y reproducibles**:

**Caso A — el directorio empieza con espacios.** Sin `IFS=`, `read` recorta los espacios del principio y del final de cada línea, así que la ruta llega mutilada a `wc`.

```
$ mkdir "  midir" && printf 'a\nb\n' > "  midir/x.md"
$ bash script.sh "  midir"
script.sh: line 10: midir/x.md: No such file or directory     ← perdió los dos espacios
>>> exit: 1
```

**Caso B — un nombre de archivo contiene un salto de línea.** `read` corta por saltos de línea, así que un nombre así se parte en dos "archivos" inexistentes.

```
$ printf 'a\nb\nc\n' > "normal/$(printf 'raro\nnombre').md"
$ bash script.sh normal
script.sh: line 10: normal/raro: No such file or directory
>>> exit: 1
```

> ➕ **La buena noticia:** en los dos casos el script **muere ruidosamente en lugar de dar una cuenta incorrecta**. Eso es `set -e` haciendo exactamente su trabajo: `wc` falló, la sustitución de comandos heredó ese exit status distinto de cero, la asignación lo heredó a su vez, y `errexit` cortó por lo sano. Un conteo silenciosamente equivocado habría sido mucho peor que un error visible.

**El arreglo**, si algún día lo necesitas, son tres cambios pequeños:

```bash
while IFS= read -r -d '' archivo; do
    lineas=$(wc -l < "$archivo")
    contador=$((contador + lineas))
done < <(find "$directorio" -type f -name "*.md" -print0)
```

| Cambio | Qué resuelve |
|---|---|
| `IFS=` | `read` deja de recortar espacios en las orillas → **Caso A** |
| `-print0` | `find` separa con el byte NUL, el único que no puede aparecer en un nombre |
| `-d ''` | `read` usa NUL como delimitador en vez del salto de línea → **Caso B** |

> ✅ **Comprobado:** con estos tres cambios, los dos casos de arriba cuentan correctamente (2 y 3 líneas respectivamente) y salen con exit 0.

**¿Merece la pena meterlo?** Depende del uso. Para un script personal sobre tus propias notas, la versión actual es perfectamente razonable y se lee mejor. Para un script que vaya a correr sobre directorios que no controlas, sí. Lo importante es **saber que la limitación está ahí** y que no es un accidente, sino una decisión.

## 6.4 Un defecto que no depende de ti: `wc -l`

Recordatorio de la práctica 4: `wc -l` cuenta **saltos de línea**, no líneas. Si un `.md` no termina en `\n`, su última línea no se cuenta.

```
completo.md      (3 líneas, termina en \n)   → wc dice 3  ✅
sin_salto.md     (3 líneas, sin \n al final) → wc dice 2  ❌
```

La alternativa exacta sería `grep -c '' "$archivo"`, pero **bajo `set -e` es peligrosa**: `grep` devuelve exit 1 cuando no encuentra coincidencias, y un `.md` vacío no tiene ninguna línea, así que el script moriría. `wc -l < "$archivo"` es el compromiso correcto aquí.

---
---

# 7. Chuleta

## Las opciones de `set`

| Opción | Nombre largo | Qué hace | Trampa principal |
|---|---|---|---|
| `-e` | `errexit` | Sale si un comando falla | No dispara en condiciones de `if`/`while`, ni a la izquierda de `&&`/`\|\|`, ni con `!`. Y `((x++))` con `x=0` sí lo dispara |
| `-u` | `nounset` | Error con variables indefinidas | `"$@"` está exceptuado. Se desactiva puntualmente con `${var:-}` |
| — | `pipefail` | El pipe falla si falla cualquier parte | Falsos fallos con `cmd \| grep -q` por SIGPIPE |
| `-x` | `xtrace` | Imprime cada comando antes de ejecutarlo | Para depurar: `bash -x script.sh` |

## Expansión de parámetros

| Escrito | Significado |
|---|---|
| `${var-def}` | `def` si está **sin definir** |
| `${var:-def}` | `def` si está sin definir **o vacía** |
| `${var:=def}` | Igual, pero además **asigna** `def` a la variable |
| `${var:?msg}` | **Aborta** con `msg` si está sin definir o vacía |
| `${var:+def}` | `def` solo si **sí** tiene contenido |

## Contadores bajo `set -e`

```bash
total=$((total + 1))     # ✅ seguro siempre
((total++))              # ❌ exit 1 cuando total vale 0
((++total))              # ⚠️ funciona de casualidad
((total++)) || true      # ✅ parche válido
```

## Redirección y bucles

```bash
cmd | while read ...; done          # ❌ subshell: las variables se pierden
while read ...; done < <(cmd)       # ✅ process substitution
while IFS= read -r -d '' f; done < <(find ... -print0)   # ✅ blindado
```

## `wc`

```bash
wc -l archivo       # imprime "4 archivo"  → inservible para sumar
wc -l < archivo     # imprime "4"          → ✅
grep -c '' archivo  # cuenta líneas de verdad, pero exit 1 si el archivo está vacío
```

## Comprobar qué es cada cosa

```bash
type wc         # wc is /usr/bin/wc        → un programa externo
type [          # [ is a shell builtin     → un comando interno
type while      # while is a shell keyword → sintaxis del lenguaje
shellcheck script.sh
bash -x script.sh    # traza de ejecución
set -o               # lista todas las opciones y su estado
```

---

## Para la próxima sesión

- [x] ~~Aplicar `${1:-}` al script final~~ → hecho: `directorio="${1:-}"`
- [x] ~~Mandar los errores a stderr~~ → hecho: `>&2`
- [ ] Reescribir el script para que acepte **varios** directorios usando `"$@"` (cierra el círculo con la práctica 1)
- [ ] Probar qué pasa con un `.md` de 100.000 líneas: comparar el bucle `while read` interno contra `wc`
- [ ] Leer el pitfall #60 completo del wiki de Greg, sobre las trampas de `set -euo pipefail`
- [ ] Practicar `${var:?mensaje}` como alternativa a la guarda del principio
- [ ] Decidir si el script necesita la versión blindada con `-print0` (ver 6.3)
