# Procesos, señales y control de trabajos

Fuente: MS 2026 L2 *Signals and Job Control* + experimentos propios · 2026-08-12
Unifica cosas que aparecieron sueltas en `entorno.md`, `ssh.md`, `scripting.md` y las notas
de `set -e`.

---

## Consulta rápida

| Comando | Qué hace |
|---|---|
| `cmd &` | lanzar en segundo plano |
| `Ctrl-Z` | suspender lo que está en primer plano |
| `Ctrl-C` | interrumpir lo que está en primer plano |
| `jobs` / `jobs -l` | trabajos de esta shell / con PID |
| `jobs -p %1` | solo el PID del trabajo 1 |
| `fg %1` | traer al primer plano |
| `bg %1` | reanudar en segundo plano |
| `kill %1` / `kill PID` | señal al trabajo / al proceso |
| `$!` | PID del último lanzado con `&` |
| `$$` / `$BASHPID` | PID del script que arrancó / PID real de *este* proceso (solo bash) |
| `wait $PID` | esperar y recibir su código de salida |
| `kill -0 PID` | ¿existe y puedo señalarlo? Sin mandar nada |
| `nohup cmd &` | que sobreviva al cierre de la terminal |
| `disown %1` | sacarlo de la tabla de trabajos, ya lanzado |
| `pgrep -f patrón` | buscar PID por línea de comando |
| `pkill -f patrón` | mandarle señal a lo que encuentre |
| `trap 'limpieza' EXIT` | ejecutar algo al salir |
| `ps -o pid,ppid,stat,comm` | estado de los procesos |

---

## Modelo mental

### Proceso, PID, job

| Concepto | Qué es | Quién lo administra |
|---|---|---|
| **Proceso** | programa ejecutándose | el kernel |
| **PID** | su identificador real | el kernel |
| **Job** | proceso que *esta shell* administra | bash |
| **Job ID** (`%1`) | número que bash le da | bash |

**Los jobs son de bash, no del sistema.** `%1` solo existe en la terminal donde lo lanzaste;
otra shell no lo ve. El PID es universal. Por eso en scripts se usa `$!`, no `%1`.

### Cómo nace un proceso: `fork` y `exec`

**`fork`** duplica el proceso actual **en memoria**. El hijo nace idéntico: mismas variables,
funciones, alias, opciones, directorio.

**`exec`** reemplaza el programa dentro de un proceso que ya existe, cargándolo **del disco**.
No crea nada; descarta la imagen de memoria que había.

> **La construcción decide si hay `fork`. El contenido decide si hay `exec`.**

| | ¿fork? | ¿exec? |
|---|---|---|
| `( echo hola )`, `$( pwd )` | sí | no — builtins |
| `( ls )`, `<( find ... )` | sí | sí — externos |
| `ls`, `bash script.sh` | sí | sí |
| `cd`, `export` | no | no — builtin en mi shell |
| `source archivo` | no | no — corre en mi shell |

**Subshell = fork sin exec**: sigue siendo bash con todo mi estado.
**Comando = fork + exec**: programa nuevo, que solo hereda el entorno exportado.

| Sobrevive a `exec` | Se borra |
|---|---|
| PID y PPID | variables sin exportar |
| descriptores de archivo | funciones |
| directorio actual, umask | alias |
| entorno **exportado** | opciones (`set -e`) |

Las dos rutas dan PID nuevo — lo pone el `fork`. `exec` solo conserva el que ya había.

### Traza de `ls -l > salida.txt`

```
bash (474), en el prompt
  ├─ 1. parsea la línea, expande globs y variables
  ├─ 2. fork()  ──────► nace 476, copia de bash EN MEMORIA
  │      476 ─ 3. abre salida.txt y lo conecta a su descriptor 1
  │             (todavía es bash quien hace esto)
  │      476 ─ 4. exec("/usr/bin/ls") — lee el binario DEL DISCO,
  │             descarta la memoria de bash, conserva PID y descriptores
  │      476 ─ 5. ahora es ls. Escribe al descriptor 1 sin saber
  │             que del otro lado hay un archivo
  │      476 ─ 6. termina con estado 0
  ├─ 7. bash 474 estaba bloqueado en wait(476), recibe el estado
  └─ 8. lo guarda en $?
```

**El paso 3 es el contrato de stdout:** la redirección se monta *entre* el fork y el exec,
mientras el hijo todavía es bash. Por eso `ls > f` funciona sin que `ls` sepa nada de
redirecciones — nace con el canal ya conectado.

---

## Señales

Una señal es un mensaje del kernel o de la terminal a un proceso: interrumpir, pausar,
terminar, notificar. Muchas teclas se traducen en señales.

| Tecla | Señal | Nº | Efecto | ¿Se puede capturar? |
|---|---|---|---|---|
| `Ctrl-C` | SIGINT | 2 | pide interrumpir | **sí** |
| `Ctrl-\` | SIGQUIT | 3 | pide salir, puede dejar core dump | sí |
| `Ctrl-Z` | SIGTSTP | 20 | suspende | **sí** |
| — | SIGTERM | 15 | pide terminar limpiamente — **el default de `kill`** | sí |
| — | SIGKILL | 9 | mata de inmediato | **no** |
| — | SIGSTOP | 19 | congela | **no** |
| — | SIGCONT | 18 | reanuda | — |
| cerrar terminal | SIGHUP | 1 | "hang up": la terminal desapareció | sí |

`kill -l` lista todas.

**La distinción clave es la última columna.** SIGTERM, SIGINT y SIGTSTP son *peticiones*: el
proceso puede atenderlas, limpiar y salir con orden. SIGKILL y SIGSTOP los aplica el kernel
directamente y el proceso ni se entera.

Verificado:

```bash
$ trap 'echo "capturé SIGTSTP"' TSTP; kill -TSTP $$
capturé SIGTSTP
seguí vivo
```

Con `STOP` en vez de `TSTP` no pasa nada: el `trap` se ignora en silencio.

Por eso **`kill -9` es el último recurso, no el primero**: no corre ningún `trap`, no se
borran temporales, no se cierran conexiones. Empezar siempre con `kill` a secas (SIGTERM).

Muchos servicios usan SIGHUP con otro sentido: **recargar configuración** sin reiniciar.

### `trap`: limpieza garantizada

```bash
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
```

`EXIT` es una pseudo-señal de bash: se dispara al terminar el script, por la razón que sea.
Es la forma correcta de no dejar temporales.

Para atender interrupciones: `trap 'echo "cancelado"; exit 130' INT TERM`.

---

## Jobs

Un **job** es un proceso, o un grupo de procesos, que bash administra en esta sesión.

| Estado | Qué significa |
|---|---|
| `Running` | ejecutándose |
| `Stopped` | suspendido, congelado |
| `Done` | terminado |

**Primer plano** = ocupa la terminal; no puedo escribir hasta que termine.
**Segundo plano** (`&`) = corre sin bloquearme la terminal.

### Cómo referirse a un job

```
$ jobs
[1]   Running    sleep 40 &
[2]-  Running    sleep 41 &
[3]+  Running    sleep 42 &
```

| Notación | Cuál |
|---|---|
| `%1` | el trabajo 1 |
| `%+` o `%%` | el **actual** — el `+` de la salida |
| `%-` | el **anterior** — el `-` |
| `%sleep` | el que empieza con "sleep" |

`fg` y `bg` sin argumento operan sobre `%+`.

### `nohup` vs `disown`

Las dos evitan que el proceso muera al cerrar la terminal, pero en momentos distintos:

| | Cuándo | Qué hace |
|---|---|---|
| `nohup cmd &` | **antes** de lanzar | ignora SIGHUP; redirige la salida a `nohup.out` |
| `disown %1` | **después**, ya corriendo | lo saca de la tabla de trabajos de bash |

`disown` es el rescate cuando lanzaste algo largo y te das cuenta tarde. Verificado: después
de `disown %1`, `jobs` sale vacío aunque el proceso siga corriendo.

Con `disown` la salida **sigue apuntando a la terminal**, así que conviene haber redirigido
antes.

### `pgrep` y `pkill`

Buscan por nombre en vez de por PID. Misma búsqueda; `pgrep` muestra, `pkill` señala.

| Opción | Qué hace |
|---|---|
| `-l` | muestra el nombre |
| `-a` | PID y comando completo |
| `-u juan` | de ese usuario |
| `-x python` | nombre **exacto** |
| `-f` | busca en **toda la línea de comando** |

`-f` es el que más se usa en la práctica:

```bash
pgrep python          # no distingue cuál de los cinco procesos python
pkill -f etl.py       # sí: busca en "python /home/juan/jobs/etl.py"
```

El proceso se llama `python`, no `etl.py`. Sin `-f`, no lo encuentra.

⚠️ `pkill -f` con un patrón corto puede matar mucho más de lo que crees. **Correr siempre
`pgrep -af` primero** para ver qué caería.

---

## Cómo se rompe

### `$$` miente en cualquier subproceso, no solo en una subshell

`$$` es el PID del **script que arrancó**. `$BASHPID` es el del proceso que ejecuta la línea
*en este instante*. Verificado en las seis construcciones que crean un proceso:

```
principal                    $$=1587   BASHPID=1587
subshell ( ... )             $$=1587   BASHPID=1588
sustitución $( ... )         $$=1587   BASHPID=1589
lado derecho de un pipe      $$=1587   BASHPID=1591
lado izquierdo de un pipe    $$=1587   BASHPID=1592
en segundo plano &           $$=1587   BASHPID=1594
de vuelta en el principal    $$=1587   BASHPID=1587
```

`$$` es ciego a **las tres construcciones que más uso**: `( )`, `|` y `$( )`. Y `$BASHPID`
vuelve a su valor original al salir del subproceso — no es un contador, es "quién soy ahora".

**Consecuencia para diagnóstico:** si un hijo falla y buscas `$$` en `ps` o en el log, estás
rastreando al padre, no al proceso que falló. Un `trap ... EXIT` corre en el padre, así que
también reporta el PID del padre:

```bash
$ trap 'echo "trap en BASHPID=$BASHPID"' EXIT
$ ( echo "hijo BASHPID=$BASHPID"; exit 1 )
hijo BASHPID=1604
trap en BASHPID=1603      ← el padre, no el que falló
```

### `$BASHPID` no existe fuera de bash, y su ausencia no avisa

`$$` es **POSIX**; `$BASHPID` es una **extensión de bash**. En una `sh` pura no existe — y no
da error: sale **vacío**.

```bash
$ dash -c 'tmp="/tmp/limpieza.$BASHPID"; echo "$tmp"'
/tmp/limpieza.            ← un nombre plausible, sin PID
```

Es el mismo modo de falla de `errores.md`: **vacío no es cero, y no avisa.** Dos scripts
distintos escribirían al mismo `/tmp/limpieza.` y se pisarían.

`set -u` sí lo atrapa, y es una razón más para llevarlo puesto:

```bash
$ dash -c 'set -u; echo "$BASHPID"'
dash: 1: BASHPID: parameter not set     # exit 2
```

Si el script tiene que ser portable, lo que hay es `$$` más `mktemp` — que da unicidad sin
depender del PID.

### `set -e` no cruza a un script hijo

Las opciones viven en la imagen de memoria, y `exec` la borra. **Por eso cada script necesita
su propio `set -euo pipefail`**: no es hábito, es necesidad.

### Variables modificadas dentro de un pipe se pierden

```bash
$ c=0; printf 'a\nb\nc\n' | while read -r l; do c=$((c+1)); done; echo $c
0
$ c=0; while read -r l; do c=$((c+1)); done < <(printf 'a\nb\nc\n'); echo $c
3
```

Cada lado de un pipe corre en subshell: el contador se incrementa en la copia, la copia
muere, y el original sigue en cero.

**Pero las dos formas pierden algo distinto:**

| | contador sobrevive | estado de `find` |
|---|---|---|
| `find \| while` | no | sí, vía `PIPESTATUS` |
| `while < <(find)` | sí | no |

Bash no da las dos cosas con ninguna construcción. No es que el script esté mal escrito.

### `$?` de un pipe es solo la última etapa

```bash
$ false | true; echo "$? / ${PIPESTATUS[*]}"
0 / 1 0
```

`PIPESTATUS` se sobrescribe con el comando siguiente: hay que copiarlo de inmediato.

### `<(...)` produce un nombre de archivo, no datos

```bash
$ echo <(echo hola)
/dev/fd/63
$ cat <(echo hola)
hola
```

`echo` imprime la ruta; `cat` imprime el contenido porque la abre.

### `export` copia hacia abajo, nunca hacia arriba

Ninguna ruta devuelve estado al padre salvo el código de salida. Por eso `ssh-agent` tiene
que **imprimir** las variables para que yo las ejecute con `eval`, y por eso `cd` tiene que
ser builtin.

### `SIGSTOP` congela el proceso, no el reloj

```bash
$ sleep 5 & kill -STOP $!    # detenido en el segundo 1
$ kill -CONT $!              # reanudado en el segundo 5
terminó tras 0s de reanudarlo
```

`sleep` no cuenta trabajo: pidió despertar en un instante del reloj, y ese instante ya pasó.

### Un job en segundo plano sigue escribiendo a la terminal

`&` desocupa el prompt, no silencia la salida. Un comando ruidoso te ensucia la pantalla
mientras escribes otra cosa. Redirigir: `cmd > salida.log 2>&1 &`.

Y si un proceso en segundo plano intenta **leer** de la terminal, el kernel lo detiene con
SIGTTIN. Aparece como `Stopped` sin razón aparente; se resuelve con `fg`.

### Un zombi no se puede matar

Ya terminó: no consume CPU, solo una entrada en la tabla donde guarda su código de salida
esperando a que el padre lo recoja. Matarlo no tiene sentido — ya está muerto.

Hay que matar **al padre**; entonces `init` lo adopta y lo recoge. Bash recoge a sus hijos
solo, así que los zombis vienen de programas mal escritos.

### Los jobs no cruzan terminales

`%1` es de bash y local a esa shell. Si cierras la terminal y abres otra, `jobs` sale vacío
aunque los procesos sigan vivos — hay que buscarlos con `pgrep` o `ps`.

### `kill -0` no mata: pregunta

```bash
$ kill -0 478 && echo "existe"
existe
$ kill -0 999999
kill: No such process
```

Verifica que el proceso exista **y** que tenga permiso de señalarlo, sin mandar nada. Es la
forma correcta de comprobar si algo sigue vivo en un script.

### `STAT` en `ps` es letra + banderas

`S` durmiendo · `R` corriendo · `T` detenido · `Z` zombi.
`+` primer plano · `s` líder de sesión.

---

## Dónde reaparece esto

Las mismas piezas explican cosas que ya vi por separado:

- `source` corre en mi shell, `bash archivo` en un hijo → `entorno.md`
- Cada conexión ssh levanta un shell nuevo sin estado compartido → `ssh.md`
- `$( )` corre en subshell, por eso el `cd` no me mueve → `scripting.md`
- Un contenedor de Docker es un proceso; una tarea de Airflow, otro. Un orquestador que
  "cancela" una tarea manda SIGTERM y luego SIGKILL — el `trap` es lo que decide si el
  trabajo alcanza a limpiar sus temporales

## Pendientes

- [ ] `trap` con SIGTERM en un script largo: probar que la limpieza corre
- [ ] `wait` con varios hijos y cómo recoger el estado de cada uno
- [ ] `timeout` — matar algo que se pasa de tiempo
