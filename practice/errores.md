--12-08-26
set -euo pipefail no cubre < <(...): el comando de la derecha corre en otro proceso y su fallo no llega al script. Un find que falla deja el while sin entrada, el contador en 0, y exit 0.

set -e y trap ERR solo ven comandos del proceso principal. Lo que corre en un subproceso es invisible para los dos.

PIPESTATUS guarda el estado de cada elemento del pipe. pipefail no descubre el fallo, cambia cuál se reporta.

false | true; echo "${PIPESTATUS[@]}"   # → 1 0
false | true; echo "$?"                 # → 0
set -o pipefail
false | true; echo "$?"                 # → 1


[ -e ] y readlink -e dan verdadero también para directorios. Para validar el origen de un dotfile hace falta [ -f ]: existencia no es tipo.

set -u mata el subshell de $(...), no el script. La asignación recibe cadena vacía y set -e es lo que aborta después — el mensaje señala la línea del comando, no de la asignación.

(( expr )) sale con 1 cuando la expresión vale 0. Con set -e, ((contador++)) mata el script en la primera vuelta porque el post-incremento devuelve el valor viejo. ((++contador)) no.

local var=$(cmd) se traga el estado de salida: el que reporta es local, no el comando. Shellcheck lo marca como SC2155.

--13-08-26
Una subshell es fork sin exec: copia de bash con todo tu estado. Un comando o script es fork + exec: programa nuevo que solo hereda el entorno exportado. De ahí que set -e no cruce a un script hijo, y que las variables modificadas dentro de un pipe se pierdan.

set -e no cruza a un script hijo. Cada script necesita su propio set -euo pipefail — no se hereda del shell que lo lanzó.

Las variables modificadas dentro de un pipe se pierden: el bucle corre en una subshell y muere con ella. find | while deja el contador en 0; while < <(find) lo conserva.