# Problemas resueltos de Missing Semester — MIT

**Fuente:** `Manual_Shell_Linux_WSL_DI.pdf`, páginas 56–62
**Contenido:** Lecture 01 — *Course Overview + Introduction to the Shell* (ejercicios 1–9)
y el arranque de Lecture 02 — *Command-line Environment*

> Las capturas de terminal y los archivos que en el PDF eran imágenes están aquí transcritos
> como texto, con las comillas y las salidas ya corregidas.

---

## Lecture 01 — Course Overview + Introduction to the Shell

### 1. ¿Qué hace la bandera `-l` de `ls`?

> *What does the `-l` flag to `ls` do? Run `ls -l /` and examine the output. What do the first
> 10 characters of each line mean? (Hint: `man ls`)*

```console
mlizz@GAMINGARI:~/projects/data-engineering-roadmap/practice/shell/lecture01/files$ ls -l
total 8
-rwxr-xr-x 1 mlizz mlizz 142 Jul  2 16:53 hello.sh
-rw-r--r-- 1 mlizz mlizz  42 Jul  2 12:54 texto.txt
```

`ls` nos permite listar archivos, mientras que `-l` nos brinda un formato largo de estos:
permisos, usuario, tamaño, fecha. Y los primeros 10 caracteres de cada línea representan los
permisos (*tipos de permisos*).

---

### 2. ¿Qué es un glob?

> *In the command `find ~/Downloads -type f -name "*.zip" -mtime +30`, the `*.zip` is a "glob".
> What is a glob? Create a test directory with some files and experiment with patterns like
> `ls *.txt`, `ls file?.txt`, and `ls {a,b,c}.txt`. See Pattern Matching in the Bash manual.*

Los globs son patrones que **la shell expande antes de ejecutar el comando**. El `*.zip`
quiere decir *dame cualquier archivo que al final tenga `.zip`*.

---

### 3. Comillas simples, dobles y ANSI

> *What's the difference between `'single quotes'`, `"double quotes"`, and `$'ANSI quotes'`?
> Write a command that echoes a string containing a literal `$`, a `!`, and a newline
> character. See Quoting.*

#### 1 — Comillas simples

Todo se toma **literalmente**.

```bash
echo 'Hola $USER! \n'
```

Salida:

```
Hola $USER! \n
```

Aquí **no** se expande `$USER`, y `\n` no se convierte en salto de línea.

#### 2 — Comillas dobles

Permiten expansión de variables (`$HOME`), sustitución de comandos (`$(date)`) y secuencias
de escape (`\"`, `\$`).

```bash
echo "Hola $USER"
```

Salida posible:

```
Hola juan
```

Dentro de comillas dobles, Bash todavía interpreta cosas como:

```
$USER
$(comando)
`comando`
```

Pero conserva espacios y texto junto.

> ⚠️ En modo interactivo, `!` puede intentar hacer **history expansion**, por eso a veces
> causa errores si lo usas dentro de comillas dobles.

#### 3 — ANSI quotes: `$'...'`

Son parecidas a las comillas simples, pero **sí se expanden** secuencias de escape con barra
invertida, como:

| Secuencia | Qué es |
|---|---|
| `\n` | salto de línea |
| `\t` | tabulación |
| `\\` | barra invertida |
| `\'` | comilla simple |

Se escriben con un símbolo de dólar antes de las comillas: `$'...'`.

```bash
echo $'Hola\nMundo'
```

Salida:

```
Hola
Mundo
```

Aquí `\n` sí se convierte en un salto de línea real.

**La respuesta al ejercicio** — una cadena con un `$` literal, un `!` y un salto de línea:

```console
mlizz@GAMINGARI:~/projects/data-engineering-roadmap/practice/shell/lecture01/files$ echo $'Hola$ \n¿Cómo estan hoy?'
Hola$
¿Cómo estan hoy?
```

---

### 4. Los tres flujos estándar y sus redirecciones

> *The shell has three standard streams: stdin (0), stdout (1), and stderr (2). Run
> `ls /nonexistent /tmp` and redirect stdout to one file and stderr to another. How would you
> redirect both to the same file? See Redirections.*

Comando del ejercicio:

```bash
ls /nonexistent /tmp
```

Aquí pasan dos cosas:

- `/tmp` sí existe → salida normal → **stdout**
- `/nonexistent` no existe → mensaje de error → **stderr**

> ⚠️ `ls` sí puede procesar varias carpetas/rutas a la vez.
>
> Bash lo separa por espacios y se lo entrega a `ls` como **dos argumentos distintos**:
>
> - Argumento 1: `/nonexistent`
> - Argumento 2: `/tmp`
>
> **La clave está en el espacio.** Esto:
>
> `ls /nonexistent/tmp`
>
> es **una sola ruta**, que significa: *"busca la carpeta `tmp` dentro de `/nonexistent`"*.

#### Redirigir stdout a un archivo y stderr a otro

```bash
ls /nonexistent /tmp 1> salida.txt 2> errores.txt
```

Significa:

- `ls /nonexistent /tmp` — ejecuta el comando
- `1> salida.txt` — manda la **salida normal** a `salida.txt`
- `2> errores.txt` — manda los **errores** a `errores.txt`

`1` y `2` no representan "primer resultado" y "segundo resultado". Representan **canales de
salida**: `1` = salida normal, `2` = salida de error.

#### ¿Cómo es posible poner `1>` y luego `2>` en el mismo comando?

Porque Bash permite configurar varios canales **antes** de ejecutar el comando. Piensa en el
comando como si tuviera dos tubos de salida:

```
              stdout 1  ───────►  salida.txt
ls /tmp
              stderr 2  ───────►  errores.txt
```

Bash hace esto antes de correr `ls`:

1. Abre o crea `salida.txt`.
2. Conecta el canal 1 de `ls` a ese archivo.
3. Abre o crea `errores.txt`.
4. Conecta el canal 2 de `ls` a ese archivo.
5. Ahora sí ejecuta `ls`.

#### Redirigir ambos a un archivo

La forma moderna y sencilla en Bash es:

```bash
ls /nonexistent /tmp &> todo.txt
```

Eso manda stdout y stderr al mismo archivo `todo.txt`. También puedes usar la forma clásica:

```bash
ls /nonexistent /tmp > todo.txt 2>&1
```

> ⚠️ **Ojo con el orden**
>
> Este comando está bien:
>
> `ls /nonexistent /tmp > todo.txt 2>&1`
>
> Pero este puede no hacer lo esperado:
>
> `ls /nonexistent /tmp 2>&1 > todo.txt`
>
> Porque Bash lee las redirecciones **de izquierda a derecha**.
>
> En el primero — `> todo.txt 2>&1` — primero manda stdout a `todo.txt`, y luego manda stderr
> al mismo lugar.
>
> En el segundo — `2>&1 > todo.txt` — primero manda stderr a donde estaba stdout, que todavía
> era la terminal, y luego manda stdout al archivo.

En `2>&1`, el `&1` significa *"al mismo destino/canal donde está apuntando el descriptor 1"*.
Más técnicamente:

- `2` = stderr, salida de errores
- `>` = redirigir
- `&1` = **no es un archivo llamado `1`**, sino "usa el descriptor de archivo número 1"

Entonces `2>&1` significa: *"manda el canal 2 al mismo lugar donde está mandándose el canal 1"*.

---

### 5. `$?`, `&&` y `||`

> *`$?` holds the exit status of the last command (0 = success). `&&` runs the next command
> only if the previous succeeded; `||` runs it only if the previous failed. Write a one-liner
> that creates `/tmp/mydir` only if it doesn't already exist. See Exit Status.*

```console
mlizz@GAMINGARI:~/.../lecture01/files$ [ -d /tmp/mydir ] || mkdir /tmp/mydir
mlizz@GAMINGARI:~/.../lecture01/files$ echo $?
0
```

```bash
[ -d /tmp/mydir ]
```

Pregunta: *"¿`/tmp/mydir` existe y además es un directorio?"*

- Si la respuesta es **sí**, el comando termina con estado de salida `0`.
- Si la respuesta es **no**, termina con estado distinto de `0`.

---

### 6. ¿Por qué `cd` tiene que ser un builtin?

> *Why does `cd` have to be built into the shell itself rather than a standalone program?
> (Hint: think about what a child process can and cannot affect in its parent.)*

`cd` tiene que ser un **comando interno del shell** porque cambia el **directorio actual del
proceso del shell**.

Cuando tú escribes:

```bash
cd /tmp
```

lo que quieres es que **tu shell actual** cambie de carpeta. Es decir, después de eso quieres
que tu terminal quede trabajando dentro de `/tmp`.

El problema es que, si `cd` fuera un programa externo normal, pasaría esto: el shell crearía
un **proceso hijo** para ejecutar ese programa. Ese proceso hijo sí podría cambiar su propio
directorio a `/tmp`, pero cuando termina, desaparece. El shell padre seguiría en el directorio
anterior.

**Un proceso hijo no puede cambiar el directorio de trabajo de su proceso padre.**

Por eso `cd` debe ejecutarse dentro del mismo shell, no en un programa aparte.

---

### 7. Script que comprueba si un archivo existe

> *Write a script that takes a filename as an argument (`$1`) and checks whether the file
> exists using `test -f` or `[ -f ... ]`. It should print different messages depending on
> whether the file exists. See Bash Conditional Expressions.*

Creación del archivo con el script: `verificar.sh`

```bash
#!/bin/bash

if [ -f "$1" ]; then
    echo "El archivo existe."
else
    echo "El archivo no existe."
fi
```

---

### 8. `chmod +x` y por qué hace falta

> *Save the script from the previous exercise to a file (e.g., `check.sh`). Try running it with
> `./check.sh somefile`. What happens? Now run `chmod +x check.sh` and try again. Why is this
> step necessary? (Hint: look at `ls -l check.sh` before and after the chmod.)*

Primer intento, sin permiso de ejecución:

```console
mlizz@GAMINGARI:~/.../lecture01/files$ ./verificar.sh tarea.txt
-bash: ./verificar.sh: Permission denied
```

Después del `chmod`:

```console
mlizz@GAMINGARI:~/.../lecture01/files$ chmod +x verificar.sh
mlizz@GAMINGARI:~/.../lecture01/files$ ./verificar.sh tarea.txt
El archivo no existe.
mlizz@GAMINGARI:~/.../lecture01/files$
```

El comando:

```bash
chmod +x verificar.sh
```

significa: *"agrega permiso de ejecución al archivo `verificar.sh`."*

---

### 9. `set -x`, el modo de rastreo

> *What happens if you add `-x` to the set flags in a script? Try it with a simple script and
> observe the output. See The Set Builtin.*

#### ¿Qué significa `set -x`?

En Bash:

```bash
set -x
```

activa el modo **xtrace** o **modo de rastreo**. Eso hace que Bash muestre en pantalla **cada
comando antes de ejecutarlo**, después de haber expandido variables.

Sirve mucho para **depurar scripts**, o sea, para ver paso a paso qué está haciendo tu código.

Creamos el script `debug.sh`:

```bash
#!/bin/bash

set -x

name="Juan"
echo "Hello, $name"

number=5
echo "The number is $number"

set +x

echo "Debug mode is now off"
```

Otorgamos permisos de ejecución:

```console
mlizz@GAMINGARI:~/.../lecture01/files$ chmod +x debug.sh
```

Y ejecutamos:

```console
mlizz@GAMINGARI:~/.../lecture01/files$ ./debug.sh
+ name=Juan
+ echo 'Hello, Juan'
Hello, Juan
+ number=5
+ echo 'The number is 5'
The number is 5
+ set +x
Debug mode is now off
```

#### ¿Para qué sirve `set +x`?

Así como `set -x` activa el rastreo, `set +x` lo desactiva. Por eso en el ejemplo, después de
`set +x`, ya no aparecen líneas con `+`.

Entonces con `set -x` ves dos cosas:

| Tipo de línea | Significado |
|---|---|
| `+ echo 'Hello, Juan'` | Comando que Bash está ejecutando |
| `Hello, Juan` | Resultado producido por el comando |

---

## Lecture 02 — Command-line Environment

### Arguments and Globs

#### 1. El argumento `--`

> *You might see commands like `cmd --flag -- --notaflag`. The `--` is a special argument that
> tells the program to stop parsing flags. Everything after `--` is treated as a positional
> argument. Why might this be useful? Try running `touch -- -myfile` and then removing it
> without `--`.*

**Traducción:** puedes ver comandos como `cmd --flag -- --notaflag`. El `--` es un argumento
especial que le dice al programa que **deje de interpretar flags/opciones**. Todo lo que
aparece después de `--` se trata como un argumento posicional. ¿Por qué podría ser útil esto?
Prueba ejecutar `touch -- -myfile` y luego intenta eliminarlo sin usar `--`.

Ejercicio práctico:

```console
mlizz@GAMINGARI:~/projects/data-engineering-roadmap$ touch -- -myfile
mlizz@GAMINGARI:~/projects/data-engineering-roadmap$
```

*(La página 62 termina aquí; el resto de Lecture 02 continúa en las páginas siguientes del
manual.)*
