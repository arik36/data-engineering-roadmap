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

## Pendientes

- **Pasarle `shellcheck` a `install.sh`.** A `contar-lineas.sh` ya se lo corrí; a `install.sh` no, desde que le metí funciones.

  Y vale anotar por qué eso no cancela nada de lo de arriba: **shellcheck detecta patrones peligrosos, no fallos silenciosos de lógica.** Ninguna de estas líneas nació de shellcheck — todas nacieron de un script que falló en silencio. Las dos cosas son necesarias y ninguna reemplaza a la otra.

- **Documentar los códigos de salida** del instalador: uno por modo de falla, y `--help` que los liste.
- **Añadir `trap ... EXIT`** para registrar toda salida, y comprobar en vivo que atrapa lo que `ERR` deja pasar.
