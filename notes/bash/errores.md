# bash — cómo se pierde un error

**Fuente:** bitácora propia del 12, 13, 14 y 21 de agosto de 2026 · práctica de scripts de bash
**Fecha:** reorganizada por tema el 2026-08-21

---

## Modelo mental

**Bash reporta el estado del último comando, y hay tres lugares donde eso miente:** los pipes, los subprocesos, y los comandos que envuelven a otros.

Todo lo de abajo es una instancia de eso.

**`$(...)` = quiero su resultado. `<(...)` = quiero una fuente de datos.** Esa distinción explica por qué uno propaga el estado y el otro no: una asignación es un comando y falla si su lado derecho falla; una redirección solo abre un descriptor y no tiene dónde reportar nada.

---

## Cómo se rompe — el estado se pierde

- **Subshell vs. fork+exec.** Una subshell es *fork sin exec*: una copia de bash con todo tu estado. Un comando o script es *fork + exec*: programa nuevo que solo hereda el entorno exportado. De ahí salen las dos consecuencias siguientes.

- **`set -e` y `trap ERR` solo ven comandos del proceso principal.** No cruzan a un script hijo: cada script necesita su propio `set -euo pipefail`, no se hereda del shell que lo lanzó.

- **`source` sí lo hereda**, porque no crea proceso — corre dentro del tuyo. `bash script.sh` no, porque es fork+exec.

  ```bash
  # hijo.sh contiene dos líneas:
  #   false
  #   echo "sigo vivo"

  set -e; source hijo.sh   # el false aborta al padre; el echo NUNCA corre → exit 1
  set -e; bash hijo.sh     # el echo SÍ corre; padre e hijo sobreviven     → exit 0
  ```

- **`export` copia hacia abajo, nunca hacia arriba.** Nada que haga un hijo con su copia toca la del padre. Es propiedad de `fork`, no limitación de bash.

- **Las variables modificadas dentro de un pipe se pierden**: el bucle corre en una subshell y muere con ella.

  ```bash
  n=0; find . -type f | while read -r f; do ((++n)); done   # n=0
  n=0; while read -r f; do ((++n)); done < <(find . -type f) # n=3
  ```

- **`set -euo pipefail` no cubre `< <(...)`.** El comando de la derecha corre en otro proceso y su fallo no llega al script. Un `find` que falla deja el `while` sin entrada, el contador en 0, y `exit 0`.

- **El estado de un subproceso siempre existe; lo que cambia es si bash lo conecta con algo.** `< <(...)` no lo conecta. Un pipe sí, vía `PIPESTATUS`. Una asignación simple también — materializar la salida con `salida=$(find ...)` propaga el fallo.

- **`PIPESTATUS` guarda el estado de cada elemento del pipe.** `pipefail` no descubre el fallo: cambia cuál se reporta.

  ```bash
  false | true; echo "${PIPESTATUS[@]}"   # → 1 0
  false | true; echo "$?"                 # → 0
  set -o pipefail
  false | true; echo "$?"                 # → 1
  ```

---

## Cómo se rompe — la trampa está en el comando

- **`(( expr ))` sale con 1 cuando la expresión vale 0.** Con `set -e`, `((contador++))` mata el script en la primera vuelta, porque el post-incremento devuelve el valor **viejo** — que es 0. `((++contador))` no.

- **`local var=$(cmd)` se traga el estado de salida:** el que reporta es `local`, no el comando. Shellcheck lo marca como **SC2155**. Se separa en dos líneas: `local var` y luego `var=$(cmd)`.

- **`set -u` mata el subshell de `$(...)`, no el script.** La asignación recibe cadena vacía y el script sigue vivo; es `set -e` lo que aborta después. Y el mensaje señala la línea del comando, no la de la asignación.

- **`exit` no dispara `trap ERR`.** `ERR` reacciona a un comando que falla, y `exit` no falla — ordena terminar. Para registrar **todas** las salidas, `trap ... EXIT`.

- **`exit 0` es la única convención universal.** El significado de los demás códigos lo define cada programa. Justo por eso hay que documentarlos.

- **`PS4` repite su primer carácter una vez por nivel de anidamiento.** Por eso el `+ ` por defecto sale `++` dentro de `$(...)`, y un `PS4='TRACE: '` sale `TTRACE: `. La repetición es información —te dice a qué profundidad estás— pero destroza cualquier prefijo que no sea un solo carácter.

  ```bash
  PS4='X '; set -x; v=$(echo $(echo $(echo profundo)))
  XXXX echo profundo
  XXX echo profundo
  XX echo profundo
  X v=profundo
  ```

---

## Cómo se rompe — validar de más o de menos

- **`[ -e ]` y `readlink -e` dan verdadero también para directorios.** Para validar el origen de un dotfile hace falta `[ -f ]`: **existencia no es tipo**.

- **`<<<` sobre una cadena vacía produce una línea vacía, no cero.** `${#array[@]}` da 1 y el `for` entra una vez con `""`. Validar la cadena **antes** de convertirla esquiva el caso.

- **Validar el proceso no valida el dato: son dos capas.** Un pipeline nunca debe reportar éxito con resultado vacío sin haberlo comprobado.

- **Cada salida exitosa debe honrar el mismo contrato de stdout.** Bash trata la cadena vacía como cero en aritmética, así que un `echo` faltante no da error: da un resultado plausible. Ese es el modo de falla peor, porque no se ve.

- **Un código de salida por modo de falla, no uno genérico.** La distinción es qué debe hacer quien llama: `1` (uso) nunca se reintenta, `3` (permisos) quizá sí.

- **`--help` va a stdout con `exit 0`**: no es un error, es lo que se pidió. Y va **antes** de cualquier validación, o el script muere sin argumentos antes de poder explicarse.

---

## Lo que voy a usar

| Herramienta | Para qué |
|---|---|
| `set -euo pipefail` | La base. En **cada** script, no solo en el de arriba |
| `bash -x script.sh` | Traza cada comando expandido antes de ejecutarlo |
| `PS4='+ ${BASH_SOURCE}:${LINENO}: '` | Le pone archivo y línea a esa traza — ojo con el primer carácter (ver arriba) |
| `trap '...' ERR` | Reacciona a comandos que fallan |
| `trap '...' EXIT` | Reacciona a **toda** salida, incluidos los `exit` explícitos |
| `"${PIPESTATUS[@]}"` | El estado real de cada elemento de un pipe |
| `shellcheck` | Encuentra SC2155 y compañía sin correr el script |

---

# Adiciones a `notes/bash/errores.md`

Bloques listos para pegar. Fecha: 2026-08-26.

---

## En "Cómo se rompe — el estado se pierde", agregar:

- **`if ! cmd; then` pierde el código de salida; `cmd || { ... }` lo conserva.** Para cuando
  entras al `then`, `$?` ya es el de evaluar la condición, no el del comando. Verificado:

  ```bash
  if ! salida=$(bash -c "exit 6"); then echo "$?"; fi    # → 0   perdido
  salida=$(bash -c "exit 6") || { echo "$?"; }           # → 6   ahí está
  ```

  Si necesito distinguir *por qué* falló —`curl` 6 de DNS, 23 de escritura— el `||` es el
  único que me lo da.

---

## En "Cómo se rompe — la trampa está en el comando", agregar:

- **`trap ... EXIT` se ejecuta SIEMPRE que el script termina**, no solo con errores: salida
  exitosa, `exit` explícito, corte por `set -e`, o Ctrl-C. Verificado en los tres caminos.
  Por eso es el de limpieza, y el que garantiza que un `mktemp` no quede tirado.

  | Evento | Cuándo dispara |
  |---|---|
  | `EXIT` | **toda** salida del script |
  | `ERR` | solo un comando que devuelve ≠ 0 |
  | `INT` | solo Ctrl-C |

  Complementa lo que ya está anotado: `exit` no dispara `ERR` porque no falla — ordena
  terminar.

- **Una herramienta puede tener dos nociones de éxito.** `curl` sale con 0 aunque el servidor
  responda 404: para `curl`, entregar la respuesta *es* el éxito. El estado del servicio
  remoto es un **dato**, no un fallo, y hay que pedirlo aparte con `-w '%{http_code}'`.

  Es la misma familia que `awk` devolviendo columnas vacías: éxito del proceso, resultado
  inservible.

- **`-eq` exige enteros y revienta con una variable vacía.** Para "está vacía" lo idiomático
  es `-z`, no `!=` — que funciona pero compara cadenas.

  Y no existe `null` en bash: solo cadena vacía, `unset`, o la variable que nunca se definió.
  Por eso `set -u` es la red que avisa del tercer caso.

---

## En "Cómo se rompe — validar de más o de menos", agregar:

- **Descargar directo al archivo final deja basura si la descarga falla.** `curl -o destino.csv`
  escribe ahí la página HTML de error del servidor, y el `.csv` queda con contenido plausible
  y equivocado. Descargar a `mktemp` y `mv` solo si la validación pasó.

- **Un nombre con timestamp destruye la idempotencia.** `%Y%m%dT%H%M%S` cambia cada segundo,
  así que dos corridas del mismo día dejan dos archivos. `%Y-%m-%d` **provoca la colisión a
  propósito**: es lo que permite preguntar `[ -f "$destino" ]` y salir sin volver a bajar
  nada.

  ```
  con timestamp:  2026-08-27T100001_reporte.csv  y  2026-08-27T163000_reporte.csv
  con fecha:      2026-08-27_reporte.csv          las dos veces
  ```

  La colisión no es un defecto que haya que evitar: es el mecanismo.

- **`basename` es para rutas del sistema, no para URLs.** Verificado:

  ```bash
  basename 'https://x.com/datos.csv?token=abc&v=2'   → datos.csv?token=abc&v=2
  basename 'https://x.com/api/ventas/'               → ventas
  ```

  El primero crearía un archivo con `?` y `&` en el nombre; el segundo devuelve un directorio
  como si fuera archivo. Limpiar antes: `${url%%\?*}` corta desde el primer `?`.

  Con un solo `?`, `%%` y `%` dan lo mismo. La diferencia aparece con varios: `%%` corta
  desde el primero, `%` desde el último.

- **Una línea de `crontab` es estática.** Todo lo que cambia —la fecha, sobre todo— lo tiene
  que calcular el script en el momento. Una fecha escrita en el crontab sobrescribe el mismo
  archivo para siempre.

---

Fecha: 2026-08-28. Todo verificado en terminal.

---

## 1. CORRECCIÓN — la línea de `<<<` está mal

Dice:

> `<<<` sobre una cadena vacía produce una línea vacía, no cero. `${#array[@]}` da 1 y el
> `for` entra una vez con `""`.

**Eso es cierto para `mapfile`, no para `read -ra`.** Verificado:

```bash
IFS="," read -ra a <<< ""    → 0 elementos, el for NO entra
mapfile -t a <<< ""          → 1 elemento vacío
```

Reemplazar por:

> **`<<<` sobre una cadena vacía se comporta distinto según el comando.** `read -ra` parte
> por IFS y sin contenido no produce campos: array de 0, el `for` no entra. `mapfile` parte
> por líneas, y una cadena vacía sigue siendo una línea: array de 1 con `""`. Verificar cuál
> se está usando antes de asumir el conteo.

---

## 2. CORRECCIÓN — `wc -l` no devuelve 0

El comentario de `ingesta.sh` dice *"si el archivo no tiene saltos de línea, `wc -l` devuelve
0"*. Solo es cierto con **una** línea. En general devuelve **N−1**:

```
'Hola'      (1 línea sin \n)  → wc: 0   grep -c '^': 1
'a\nb\nc'   (3 líneas sin \n) → wc: 2   grep -c '^': 3
```

Cuenta caracteres `\n`, así que si falta el último salto pierde una línea, no todas.
Corregir el comentario del script.

*(El detalle completo ya está en `buscar-y-filtrar.md`. Aquí solo el puntero.)*

---

## 3. En "Cómo se rompe — el estado se pierde", agregar:

- **`if ! cmd; then` pierde el código de salida; `cmd || { ... }` lo conserva.** Para cuando
  entras al `then`, `$?` ya es el de evaluar la condición, no el del comando:

  ```bash
  if ! salida=$(bash -c "exit 6"); then echo "$?"; fi    # → 0   perdido
  salida=$(bash -c "exit 6") || { echo "$?"; }           # → 6   ahí está
  ```

  Si necesito distinguir *por qué* falló —`curl` 6 de DNS, 23 de escritura— el `||` es el
  único que me lo da.

---

## 4. En "Cómo se rompe — la trampa está en el comando", agregar:

- **`trap ... EXIT` se ejecuta SIEMPRE que el script termina**, no solo con errores: salida
  exitosa, `exit` explícito, corte por `set -e`, o Ctrl-C. Verificado en los tres caminos.

  | Evento | Cuándo dispara |
  |---|---|
  | `EXIT` | **toda** salida del script |
  | `ERR` | solo un comando que devuelve ≠ 0 |
  | `INT` | solo Ctrl-C |

  Por eso `EXIT` es el de limpieza, y el que garantiza que un `mktemp` no quede tirado.
  Complementa lo ya anotado: `exit` no dispara `ERR` porque no falla — ordena terminar.

- **Una herramienta puede tener dos nociones de éxito.** `curl` sale con 0 aunque el servidor
  responda 404: para `curl`, entregar la respuesta *es* el éxito. El estado del servicio
  remoto es un **dato**, no un fallo, y hay que pedirlo aparte con `-w '%{http_code}'`.

  Es la misma familia que `awk` devolviendo columnas vacías: éxito del proceso, resultado
  inservible.

- **`-eq` exige enteros y revienta con una variable vacía.** Para "está vacía" lo idiomático
  es `-z`, no `!=` — que funciona pero compara cadenas. Y no existe `null` en bash: solo
  cadena vacía, `unset`, o la variable que nunca se definió; `set -u` es la red del tercer
  caso.

---

## 5. En "Cómo se rompe — validar de más o de menos", agregar:

- **Descargar directo al archivo final deja basura si la descarga falla.** `curl -o destino.csv`
  escribe ahí la página HTML de error del servidor, y el `.csv` queda con contenido plausible
  y equivocado. Descargar a `mktemp` y `mv` solo si la validación pasó.

- **Un consumidor que vigila un directorio puede recoger un archivo a medio escribir.** El
  temporal tiene que estar en el **mismo sistema de archivos** que el destino —para que el
  `mv` sea un rename atómico y no una copia— y con un **nombre que no case el patrón del
  consumidor**. `ingesta.XXXXXX` no termina en `.csv`, así que un proceso que busque `*.csv`
  lo ignora hasta que el `mv` lo hace aparecer completo.

  Es el patrón estándar de ingesta, no un truco de bash.

- **Un nombre con timestamp destruye la idempotencia.** `%Y%m%dT%H%M%S` cambia cada segundo,
  así que dos corridas del mismo día dejan dos archivos. `%Y-%m-%d` **provoca la colisión a
  propósito**: es lo que permite preguntar `[ -f "$destino" ]` y salir sin volver a bajar
  nada. La colisión no es un defecto que haya que evitar: es el mecanismo.

- **`basename` es para rutas del sistema, no para URLs.** Verificado:

  ```bash
  basename 'https://x.com/datos.csv?token=abc&v=2'   → datos.csv?token=abc&v=2
  basename 'https://x.com/api/ventas/'               → ventas
  ```

  Limpiar antes con `${url%%\?*}`. Con un solo `?`, `%%` y `%` dan lo mismo; la diferencia
  aparece con varios.

- **Concatenar sin quitar la extensión duplica el sufijo.** `basename` sobre `datos.csv`
  devuelve `datos.csv`, y `"${fecha}_${nombre}.csv"` produce `2026-08-28_datos.csv.csv`.
  `${nombre%.csv}` lo corta.

- **Una línea de `crontab` es estática.** Todo lo que cambia —la fecha, sobre todo— lo tiene
  que calcular el script en el momento. Una fecha escrita en el crontab sobrescribe el mismo
  archivo para siempre.

---

## 6. Tachaduras en "Pendientes"

- ~~Pasarle `shellcheck` a `install.sh`~~ → hecho el 27-08
- ~~Documentar los códigos de salida~~ → hecho: `ingesta.sh` documenta del 0 al 8 en `--help`
- ~~Añadir `trap ... EXIT` y comprobar en vivo~~ → hecho el 26-08, con `mktemp`

---

## 7. Punteros a las notas nuevas

En "Lo que voy a usar", agregar al final:

> Coincidencia de texto, `grep` con subcadenas, `\r`, y las comillas dentro de `[[ ]]` →
> `notes/bash/texto.md`
> `umask`, `mktemp` en 600, `mv` y permisos → `notes/bash/permisos.md`

--31/08/2028
- ## CRON:

  Cron corre con PATH mínimo, sin tu .bashrc, y con un pwd que probablemente no es el que crees. Rutas absolutas en la línea y en los argumentos. env -i bash --noprofile --norc -c '...' reproduce ese entorno para probarlo antes.

  La salida de cron va a un correo local que nadie lee. Sin redirección explícita, un fallo a las 3 AM es invisible.

---
## Pendientes
- ~~Pasarle `shellcheck` a `install.sh`~~ → hecho el 27-08
- ~~Documentar los códigos de salida~~ → hecho: `ingesta.sh` documenta del 0 al 8 en `--help`
- ~~Añadir `trap ... EXIT` y comprobar en vivo~~ → hecho el 26-08, con `mktemp`

