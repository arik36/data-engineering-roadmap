# Logging y profiling — notas para `ingesta.sh`


Base: *Debugging and Profiling* (Missing Semester, MIT, 2026), recortado a lo que usas.
Cada comando de este documento lo corrí en una terminal real; las salidas que aparecen son
las que de verdad imprimieron.

Saltado a propósito: gdb, rr, sanitizers, Valgrind, perf, flame graphs, callgrind, massif,
tcpdump, bpftrace, hyperfine.

### Qué cambió respecto a la v1

--

# 0. Antes de empezar: leer Bash sin adivinar

Casi toda la confusión con el logger no es sobre logging, es sobre sintaxis de Bash. Cinco
minutos aquí y el resto se lee solo.

## 0.1 `$variable` contra `${variable}`

En Bash puedes escribir una variable de dos formas:

```bash
nombre="Ari"

echo "$nombre"     # → Ari
echo "${nombre}"   # → Ari
```

Los dos imprimen lo mismo. Entonces la pregunta obvia:

> ¿Para qué escribir `${nombre}` si `$nombre` ya funciona?

Por dos razones.

**Razón 1 — separar la variable del texto pegado.** Sin llaves, Bash no sabe dónde termina
el nombre de la variable:

```bash
archivo="ventas"

echo "$archivo_agosto.csv"     # → .csv        ¡busca la variable "archivo_agosto"!
echo "${archivo}_agosto.csv"   # → ventas_agosto.csv
```

**Razón 2 — y esta es la importante — `${...}` es una puerta a operaciones extra sobre la
variable.** No solo "dame el valor", sino "dame el valor, pero…". Eso se llama *parameter
expansion*, y es lo que aparece en el logger.

## 0.2 `${VAR:-valor_por_defecto}`

La forma general:

```bash
${VARIABLE:-valor_por_defecto}
```

se lee así:

> Si `VARIABLE` existe y no está vacía → usa su valor.
> Si no existe o está vacía → usa `valor_por_defecto`.

Nada de esto modifica la variable: es una expresión que *produce* un valor. Por eso en el
logger se reasigna:

```bash
LOG_LEVEL="${LOG_LEVEL:-INFO}"
```

que significa "pon en `LOG_LEVEL` lo que ya tenía; si no tenía nada, pon `INFO`".

**Caso A — no existe:**

```bash
unset LOG_LEVEL
echo "${LOG_LEVEL:-INFO}"    # → INFO
```

**Caso B — ya existe:**

```bash
LOG_LEVEL="DEBUG"
echo "${LOG_LEVEL:-INFO}"    # → DEBUG    (ignora el INFO)
```

En diagrama:

```text
                LOG_LEVEL
                    │
        ┌───────────┴───────────┐
        │                       │
  ya tiene valor          no existe / vacía
        │                       │
        ▼                       ▼
      úsalo                  usa INFO
```

### ¿Y por qué no escribir simplemente `LOG_LEVEL="INFO"`?

Porque entonces quedaría clavado en el código y nadie podría cambiarlo desde fuera. Con la
forma `:-` obtienes las dos cosas:

```bash
./ingesta.sh                    # LOG_LEVEL = INFO   (el default)
LOG_LEVEL=DEBUG ./ingesta.sh    # LOG_LEVEL = DEBUG  (sin tocar el archivo)
```

Esa segunda línea es el patrón completo: **poner una variable justo antes del comando la
define solo para esa ejecución.** No queda contaminada tu sesión.

Esta es la razón principal de que la línea esté escrita así, y vas a ver el mismo truco en
prácticamente cualquier script serio de Linux.

## 0.3 Las tres salidas de un programa

Todo proceso en Unix nace con tres canales abiertos:

```text
                    tu programa
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
     stdin            stdout           stderr
   (entrada)      (salida normal)   (diagnóstico)
      fd 0            fd 1              fd 2
```

`fd` = *file descriptor*, el número con el que el sistema los identifica. Los vas a
necesitar para entender `>&2` y `+L1` más adelante.

La trampa de nombre: **`stderr` no significa "solo errores"**. Significa "el otro canal".
Los programas lo usan para logs, avisos, barras de progreso y cualquier cosa que **no sea
el resultado**. La regla real es:

```text
stdout → el producto del programa (los datos)
stderr → el relato de cómo le fue (los logs)
```

Por eso `>&2` en un logger no es raro ni indica que algo falló: es dónde va el relato.
Redirigir es así:

```bash
./ingesta.sh > datos.csv          # solo stdout al archivo; los logs siguen en pantalla
./ingesta.sh 2> ingesta.log       # solo stderr al archivo; los datos siguen en pantalla
./ingesta.sh > datos.csv 2> ingesta.log   # cada uno a su lugar
./ingesta.sh > todo.txt 2>&1      # los dos al mismo archivo
```

Ese último `2>&1` se lee "manda el fd 2 a donde ya apunta el fd 1". El `&` está ahí para
decir "1 es un descriptor, no un archivo llamado `1`".

---

# 1. Logging

## 1.1 El punto de partida: `print` no está mal

La lección arranca defendiendo el `print` de depuración, con la cita de Kernighan de que la
herramienta más efectiva sigue siendo pensar con cuidado más unos `print` bien colocados.
No es una concesión irónica: el `print` no necesita configuración, existe en todos los
lenguajes y es lo primero que debes hacer.

El problema del `print` no es que sea tosco. Es que es **efímero y sin estructura**. Lo
pones, resuelves, lo borras, y cuando el mismo bug reaparece tres semanas después vuelves a
estar ciego en el mismo lugar exacto.

## 1.2 Logging = "print con más cuidado"

La lección lo define así — *printing with more care* — normalmente a través de un framework
que te da tres cosas que el `print` no tiene:

1. **Niveles de severidad** — filtrar cuánto ruido quieres sin editar el código.
2. **Múltiples destinos** — pantalla, archivo, servidor remoto, todos a la vez.
3. **Salida estructurada** — campos, no frases.

## 1.3 Cuándo un `print` se convierte en log permanente

La regla operativa de la lección, y la frase que conviene memorizar:

> Una vez que encontraste y arreglaste un problema usando `print`, casi siempre vale la pena
> convertir esos `print` en sentencias de log **antes** de borrarlos.

La lógica no es obvia hasta que te muerde: **el lugar donde necesitaste visibilidad durante
el bug es exactamente el lugar donde vas a necesitar visibilidad cuando el bug vuelva.**
Borrar el `print` es tirar el trabajo de diagnóstico que ya hiciste. Convertirlo en
`log DEBUG ...` lo deja ahí, apagado por defecto, listo para encender.

| El `print` te decía… | Qué hacer |
| --- | --- |
| Un valor intermedio que solo importaba para *este* bug | Bórralo |
| Que un paso empezó / terminó | → `INFO` permanente |
| El valor de una variable que explica *por qué* falló | → `DEBUG` permanente |
| Que algo raro pasó pero el programa siguió | → `WARN` permanente |
| Que el paso no se completó | → `ERROR` permanente |

## 1.4 Los niveles, aplicados a `ingesta.sh`

Los niveles no son decoración: son un dial de verbosidad que operas **desde fuera**. Corres
en `INFO` todos los días y subes a `DEBUG` solo cuando algo se rompe, con el mismo código.

| Nivel | Número | Significa | En tu ingesta |
| --- | --- | --- | --- |
| `DEBUG` | 10 | Detalle de diagnóstico | URL exacta pedida, filas por chunk, valor del cursor |
| `INFO` | 20 | Progreso normal esperado | "inicia extracción", "escritas 12 480 filas" |
| `WARN` | 30 | Anomalía recuperable | reintento tras timeout, fila malformada descartada |
| `ERROR` | 40 | El paso falló | la descarga no completó, el `COPY` reventó |

Los números son la clave del mecanismo: convierten "¿es esto más importante que aquello?"
en una comparación aritmética simple.

## 1.5 El logger, línea por línea

Este es el script completo. Abajo lo desarmo en siete pedazos.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_LEVEL="${LOG_LEVEL:-INFO}"
declare -A LEVELS=([DEBUG]=10 [INFO]=20 [WARN]=30 [ERROR]=40)

log() {
  local nivel="$1"; shift
  (( LEVELS[$nivel] < LEVELS[$LOG_LEVEL] )) && return 0
  printf '%s [%-5s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nivel" "$*" >&2
}

log INFO  "inicia ingesta"
log DEBUG "endpoint=${API_URL:-none} cursor=0"
log WARN  "timeout en el intento 1, reintentando"
log ERROR "no se pudo escribir en raw/"
```

### Pieza 1 — `#!/usr/bin/env bash`

El *shebang*. Le dice al sistema con qué intérprete ejecutar el archivo cuando haces
`./script.sh`. La forma con `env` busca `bash` en tu `PATH` en vez de asumir que está en
`/bin/bash`, que es más portable (en macOS y BSD no siempre está en el mismo lugar).

### Pieza 2 — `set -euo pipefail`

Cuatro interruptores que hacen a Bash menos permisivo. Bash por defecto es
**alarmantemente** tolerante: si un comando falla, sigue adelante como si nada.

| | Qué hace | Sin él |
| --- | --- | --- |
| `-e` | Aborta si un comando falla | El script sigue con datos a medias |
| `-u` | Aborta si usas una variable no definida | Un typo se expande a cadena vacía y borras `/` |
| `-o pipefail` | Un pipe falla si **cualquier** etapa falla | Solo cuenta la última etapa |
| `-o` | (es solo el prefijo para nombrar opciones largas como `pipefail`) | |

El caso de `-u` merece verse, porque es el que más daño evita:

```bash
DESTINO="/datos/raw"
rm -rf "$DESTIN0/"*     # ← typo: 0 en vez de O
```

Sin `-u`, `$DESTIN0` no existe → se expande a nada → el comando se vuelve `rm -rf /*`.
Con `-u`, el script muere ahí mismo con `DESTIN0: unbound variable`.

Y `pipefail`, en un caso de ingesta real:

```bash
curl -s https://api.ejemplo.com/datos | gzip -d | psql -c "COPY ..."
```

Si `curl` falla pero `psql` termina bien, sin `pipefail` el pipe reporta éxito y crees que
cargaste datos que nunca llegaron.

### Pieza 3 — `LOG_LEVEL="${LOG_LEVEL:-INFO}"`

Ya la desarmamos entera en §0.2: nivel configurable desde fuera, con `INFO` por defecto.

### Pieza 4 — `declare -A LEVELS=(...)`

```bash
declare -A LEVELS=([DEBUG]=10 [INFO]=20 [WARN]=30 [ERROR]=40)
```

`declare -A` crea un **array asociativo**: un array cuyos índices son palabras en vez de
números. En Python sería un diccionario; en Bash hay que declararlo explícitamente.

```text
LEVELS
│
├── DEBUG → 10
├── INFO  → 20
├── WARN  → 30
└── ERROR → 40
```

Se consulta con corchetes:

```bash
nivel="WARN"
echo "${LEVELS[$nivel]}"    # → 30    (equivale a LEVELS[WARN])
```

La diferencia con `declare -a` (minúscula) es el tipo de índice:

```bash
declare -a normal=(uno dos tres)   # índices 0,1,2  → normal[0] = "uno"
declare -A asoc=([a]=1 [b]=2)      # índices a,b    → asoc[a]  = 1
```

Sin el `-A`, Bash intentaría interpretar `DEBUG` como un número, lo evaluaría a 0, y las
cuatro asignaciones se pisarían en el índice 0.

### Pieza 5 — `local nivel="$1"; shift`

```bash
log() {
  local nivel="$1"; shift
```

Cuando llamas `log INFO "inicia ingesta"`, dentro de la función los argumentos son:

```text
$1 = INFO
$2 = inicia ingesta
$# = 2          ← cantidad de argumentos
```

**`local`** hace que la variable exista solo dentro de la función. Sin `local`, `nivel`
sería global y sobrescribiría cualquier `nivel` de fuera. En funciones, `local` siempre.

**`shift`** corre todos los argumentos una posición a la izquierda y descarta el primero:

```text
ANTES              DESPUÉS de shift
$1 = INFO          $1 = inicia ingesta
$2 = inicia...     $2 = (nada)
$# = 2             $# = 1
```

¿Para qué? Porque la función quiere tratar los argumentos así:

```text
primer argumento  → el nivel
todo lo demás     → el mensaje
```

Con `shift`, "todo lo demás" se vuelve simplemente "todos los argumentos que quedan", y eso
se escribe `$*`. Sin `shift` tendrías que escribir algo como `${@:2}`, más difícil de leer.

Además esto hace que la función acepte mensajes en varias palabras sin comillas:

```bash
log INFO "escritas 12480 filas"     # $* = escritas 12480 filas
log INFO escritas 12480 filas       # $* = escritas 12480 filas  ← también funciona
```

### Pieza 6 — el filtro de nivel

```bash
(( LEVELS[$nivel] < LEVELS[$LOG_LEVEL] )) && return 0
```

Tres cosas juntas. Primero, **`(( ... ))` es el contexto aritmético de Bash**: dentro se
hacen comparaciones y cuentas con números, sin `$` en los nombres de variable y sin las
rarezas de `[ ]`.

```bash
(( 10 < 20 ))     # verdadero
(( 5 + 3 ))       # evalúa a 8 → verdadero (cualquier valor ≠ 0)
(( 0 ))           # falso
```

Segundo, **`A && B` ejecuta `B` solo si `A` fue verdadero**. Es un `if` de una línea.

Tercero, **`return 0`** sale de la función inmediatamente, sin llegar al `printf`. El `0`
significa "todo bien" (en Unix, 0 = éxito).

Ahora la traza completa. Supón `LOG_LEVEL="INFO"` y llamas `log DEBUG "algo"`:

```text
nivel     = DEBUG   →  LEVELS[DEBUG] = 10
LOG_LEVEL = INFO    →  LEVELS[INFO]  = 20

la condición se vuelve:   (( 10 < 20 ))   →  VERDADERO
                                   ↓
                             return 0
                                   ↓
                    sale sin imprimir: el DEBUG se filtra
```

Y con `log ERROR "algo"`, mismo `LOG_LEVEL="INFO"`:

```text
nivel     = ERROR   →  LEVELS[ERROR] = 40
LOG_LEVEL = INFO    →  LEVELS[INFO]  = 20

la condición se vuelve:   (( 40 < 20 ))   →  FALSO
                                   ↓
                    el && no dispara: no hay return
                                   ↓
                        sigue al printf: se imprime
```

La condición entera se lee: **"si este mensaje es menos importante que el umbral que fijé,
cállalo."**

Como se ve en la escala, con `LOG_LEVEL=INFO` ves INFO, WARN y ERROR, pero no DEBUG:

```text
        DEBUG(10)   INFO(20)   WARN(30)   ERROR(40)
           │           │          │          │
           ✗           ✓          ✓          ✓
        filtrado    ────────── se imprimen ──────────
                       ↑
                  LOG_LEVEL=INFO  (el umbral)
```

### Pieza 7 — el `printf`

```bash
printf '%s [%-5s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nivel" "$*" >&2
```

`printf` toma una **plantilla** con huecos y luego los valores que van en cada hueco:

```text
plantilla:   '%s  [%-5s]  %s\n'
              │     │      │
              │     │      └── hueco 3 → "$*"      (el mensaje)
              │     └───────── hueco 2 → "$nivel"  (INFO, WARN…)
              └─────────────── hueco 1 → la fecha
```

- `%s` = "mete aquí una cadena de texto".
- `%-5s` = igual, pero **rellenado a 5 caracteres, alineado a la izquierda**. Por eso en la
  salida ves `[INFO ]` con un espacio y `[ERROR]` sin él: las columnas quedan cuadradas y
  el log se puede leer en vertical. El `-` es lo que da la alineación izquierda; sin él
  quedaría `[ INFO]`.
- `\n` = salto de línea. `printf`, a diferencia de `echo`, **no lo agrega solo**.

`$(...)` es **sustitución de comandos**: ejecuta lo de adentro y pone su salida ahí mismo.
`$(date -u +%Y-%m-%dT%H:%M:%SZ)` produce `2026-08-12T23:57:19Z`.

El formato de la fecha, campo por campo:

```text
date -u  +%Y - %m - %d T %H : %M : %S Z
     │     │    │    │  │  │    │    │  │
     │     │    │    │  │  │    │    │  └── literal "Z" = zona Zulu = UTC
     │     │    │    │  │  └────┴────┴───── hora, minuto, segundo
     │     │    │    │  └── literal "T", separa fecha de hora (norma ISO 8601)
     │     └────┴────┴───── año, mes, día
     └── -u = en UTC, no en tu zona horaria local
```

Dos razones para este formato y no otro:

1. **Se ordena solo.** `2026-08-12T09:00:00Z` < `2026-08-12T21:40:03Z` alfabéticamente *y*
   cronológicamente. Un `sort` normal sobre tus logs los ordena por tiempo. Con
   `12/08/2026` eso no pasa.
2. **UTC no tiene ambigüedades.** Cuando cambia el horario de verano, una hora local se
   repite o desaparece; en UTC nunca. Si tu pipeline corre en un servidor en otra zona, esto
   deja de ser teórico.

Y `>&2` manda todo a stderr — la razón está en §0.3.

### Verificación: el logger corriendo de verdad

Estas son salidas reales del script de arriba:

```text
$ ./logger.sh                          # LOG_LEVEL por defecto = INFO
2026-08-12T23:57:19Z [INFO ] inicia ingesta
2026-08-12T23:57:19Z [WARN ] timeout en el intento 1, reintentando
2026-08-12T23:57:19Z [ERROR] no se pudo escribir en raw/
                                       ↑ el DEBUG no aparece

$ LOG_LEVEL=DEBUG ./logger.sh          # mismo código, más detalle
2026-08-12T23:57:19Z [INFO ] inicia ingesta
2026-08-12T23:57:19Z [DEBUG] endpoint=none cursor=0
2026-08-12T23:57:19Z [WARN ] timeout en el intento 1, reintentando
2026-08-12T23:57:19Z [ERROR] no se pudo escribir en raw/

$ LOG_LEVEL=ERROR ./logger.sh          # solo lo grave
2026-08-12T23:57:19Z [ERROR] no se pudo escribir en raw/

$ API_URL="https://api.ejemplo.com" LOG_LEVEL=DEBUG ./logger.sh
2026-08-12T23:57:19Z [DEBUG] endpoint=https://api.ejemplo.com cursor=0
                                       ↑ el ${API_URL:-none} tomó el valor real
```

Fíjate en la última: `${API_URL:-none}` es **la misma construcción de §0.2**, usada dentro
del mensaje. Si `API_URL` no existe imprime `endpoint=none`; si existe, imprime la URL. Así
el log nunca queda con un hueco vacío que no sabes interpretar.

Y la prueba de que los logs no contaminan los datos:

```text
$ ./logger.sh > solo_stdout.txt 2> solo_stderr.txt
stdout capturado -> []            (vacío = correcto, ahí irían los datos)
stderr capturado -> 3 líneas de log
```

### El mapa mental completo

```text
set -euo pipefail
       ↓
   modo estricto: que falle temprano y ruidoso

LOG_LEVEL="${LOG_LEVEL:-INFO}"
       ↓
   umbral configurable desde fuera, INFO por defecto

declare -A LEVELS=(...)
       ↓
   traduce nombres de nivel → números comparables

log() ─── recibe: nivel + mensaje
       ↓
   ¿LEVELS[nivel] < LEVELS[LOG_LEVEL] ?
       ├── SÍ  → return 0        (silencio)
       └── NO  → printf          (imprime)
                    ↓
              timestamp + nivel + mensaje
                    ↓
                  stderr
```

## 1.6 La letra chica de `set -euo pipefail`

`set -euo pipefail` es la mejor primera línea que puedes poner, pero **no es una red de
seguridad completa** y conviene saber dónde tiene agujeros antes de confiarle un pipeline.

### Agujero 1: los subprocesos son invisibles

`set -e` y `trap ERR` solo ven comandos del **proceso principal**. Lo que corre en un
subproceso no los dispara. El caso clásico es la sustitución de procesos `< <(...)`:

```bash
#!/usr/bin/env bash
set -euo pipefail
n=0
while read -r linea; do n=$((n+1)); done < <(find /ruta/que/no/existe -type f)
echo "filas contadas: $n"
```

El `find` de la derecha corre en **otro proceso**. Si falla, su fallo no llega al script: el
`while` simplemente no recibe entrada, el contador se queda en 0, y el script termina
tranquilamente con éxito. Lo corrí:

```text
filas contadas: 0
el script llegó al final y va a salir con 0
código de salida real del script = 0
```

Cero archivos procesados y **exit 0**. Para un pipeline de ingesta eso es lo peor posible:
un fallo que se reporta como éxito. Si tu cron mira el código de salida, nunca te enteras.

### Agujero 2: `pipefail` no *descubre* el fallo, cambia *cuál* se reporta

En un pipe, cada etapa tiene su propio código de salida. Bash guarda todos en el array
`PIPESTATUS`. Verificado:

```text
$ false | true; echo "${PIPESTATUS[@]}"
1 0                    ← etapa 1 falló (1), etapa 2 tuvo éxito (0)

$ false | true; echo "$?"
0                      ← $? solo reporta la ÚLTIMA etapa

$ set -o pipefail
$ false | true; echo "$?"
1                      ← ahora reporta el primer fallo
```

Los tres números ya estaban ahí desde el principio. `pipefail` no detecta nada nuevo:
cambia la política de cuál de ellos se convierte en `$?`. La distinción importa cuando
necesitas saber **qué etapa** falló, no solo que algo falló — y para eso tienes que leer
`PIPESTATUS` a mano:

```bash
curl -s "$URL" | gzip -d | psql -c "COPY ..."
estados=("${PIPESTATUS[@]}")
(( estados[0] != 0 )) && log ERROR "falló la descarga"
(( estados[1] != 0 )) && log ERROR "falló la descompresión"
(( estados[2] != 0 )) && log ERROR "falló la carga a Postgres"
```

Ojo con un detalle: `PIPESTATUS` se sobrescribe con **cada** comando. Cópialo a otro array
en la línea inmediatamente siguiente, o ya lo perdiste.

### Agujero 3: un nivel mal escrito silencia el mensaje

Este es un bug del logger, no de Bash, y lo confirmé:

```text
$ log ERROR "esto sí sale"
2026-08-12T23:57:42Z [ERROR] esto sí sale

$ log ERORR "este mensaje CRÍTICO se pierde en silencio"
                          ← nada. El script ni siquiera falló.
```

¿Por qué? `LEVELS[ERORR]` no existe → se expande a vacío → `(( ))` trata el vacío como `0`
→ `0 < 20` es verdadero → `return 0`. Un typo en el nombre del nivel **desaparece tu
mensaje más importante sin avisar**.

El arreglo son dos líneas:

```bash
log() {
  local nivel="$1"; shift
  if [[ -z "${LEVELS[$nivel]:-}" ]]; then
    printf '%s [ERROR] nivel de log inválido: %s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nivel" >&2
    return 1
  fi
  (( LEVELS[$nivel] < LEVELS[$LOG_LEVEL] )) && return 0
  printf '%s [%-5s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nivel" "$*" >&2
}
```

(`[[ -z ... ]]` es "está vacío"; el `:-` de nuevo, aquí para que `set -u` no mate el script
al consultar una clave inexistente.)

## 1.7 `/var/log` y `systemd` / `journalctl`

Mientras corras `ingesta.sh` a mano, los logs salen en tu terminal y ya. La pregunta
aparece cuando el script deja de ser algo que ejecutas tú y pasa a correr solo: **¿a dónde
van los mensajes cuando no hay nadie mirando la pantalla?**

Hay dos respuestas en Linux, una vieja y una nueva.

### La respuesta clásica: `/var/log/`

Un directorio con archivos de texto plano, uno por programa. Se leen con `less`, `grep`,
`tail -f`. En la máquina donde probé esto había, entre otros:

```text
/var/log/
├── dpkg.log          ← el gestor de paquetes
├── auth.log          ← intentos de login
├── postgresql/       ← un directorio por servicio
├── redis/
└── journal/          ← ojo con este, ya llegamos
```

### La respuesta moderna: `systemd`

Aquí es donde estaban mezcladas tres cosas distintas. Vamos una por una.

**¿Qué es `systemd`?** Es un programa que arranca junto con Linux y se queda corriendo todo
el tiempo. Su trabajo es **administrar los programas que deben ejecutarse en segundo
plano**: iniciarlos al encender, reiniciarlos si se caen, detenerlos ordenadamente al
apagar. Es el "jefe de turno" de la máquina.

```text
la computadora enciende
          ↓
       systemd
          ↓
    ┌─────┼─────────────────┐
    ↓     ↓                 ↓
  nginx  PostgreSQL   mi-ingesta.service
```

A cada programa administrado así se le llama una **unidad** (*unit*). Un servicio es un
tipo de unidad, y su nombre termina en `.service`. Si conviertes tu script en servicio,
pasa a llamarse por ejemplo `ingesta.service`, y `systemd` lo supervisa.

**¿Qué tiene que ver `stderr`?** Que cuando `systemd` lanza tu script, **se queda
enganchado a sus dos salidas**. No las deja caer en una terminal que no existe: las captura
y las guarda.

**¿Dónde las guarda?** En el **journal**, la bitácora central de systemd. No es un archivo
de texto que puedas abrir con `less` — es un formato binario indexado (vive en
`/var/log/journal/`). Por eso necesitas un programa para leerlo.

**Ese programa es `journalctl`.** No es "el log": es el visor del log.

La cadena completa:

```text
                 ┌──────────────────────┐
                 │       systemd        │
                 │  ejecuta el servicio │
                 └──────────┬───────────┘
                            │
                            ↓
                  ┌───────────────────┐
                  │    ingesta.sh     │
                  └─────────┬─────────┘
                            │
                   escribe en stderr  ( >&2 )
                            │
                            ↓
                  ┌───────────────────┐
                  │      journal      │
                  │  [INFO ] ...      │
                  │  [WARN ] ...      │
                  │  [ERROR] ...      │
                  └─────────┬─────────┘
                            │
                            ↓
                  journalctl -u ingesta
                            │
                            ↓
                      tú ves los logs
```

Y en una tabla, porque son cuatro cosas fáciles de confundir:

| Elemento | Qué es |
| --- | --- |
| `stderr` | El canal por donde tu script manda sus mensajes |
| `systemd` | El administrador que ejecuta y supervisa el servicio |
| `journal` | El almacén donde systemd centraliza los mensajes |
| `journalctl` | El comando para consultar ese almacén |

### Qué significa esto en la práctica

Si tu script hace esto:

```bash
log INFO  "aplicación iniciada"
log INFO  "conectando a la base de datos"
log ERROR "no se pudo conectar"
```

y `systemd` lo está corriendo, entonces:

```bash
journalctl -u ingesta.service
```

te muestra algo así:

```text
Aug 12 16:20:01 servidor ingesta.sh[1234]: 2026-08-12T22:20:01Z [INFO ] aplicación iniciada
Aug 12 16:20:01 servidor ingesta.sh[1234]: 2026-08-12T22:20:01Z [INFO ] conectando a la base de datos
Aug 12 16:20:02 servidor ingesta.sh[1234]: 2026-08-12T22:20:02Z [ERROR] no se pudo conectar
```

Y aquí está el detalle que ahorra media hora: **nunca escribiste un archivo**. No hiciste
`>> /var/log/ingesta.log` ni creaste el directorio ni configuraste rotación de logs. El
`>&2` de tu logger fue suficiente, porque systemd recogió lo que salió por ahí.

(Systemd le pone su propio timestamp y el nombre del proceso al frente; el tuyo queda
después. Redundante pero inofensivo — y el tuyo en UTC sigue siendo el bueno para ordenar.)

### Los comandos que vas a usar

```bash
journalctl -u ingesta                      # todo el log de la unidad
journalctl -u ingesta -f                   # seguir en vivo, como tail -f
journalctl -u ingesta -n 100               # últimas 100 líneas
journalctl -u ingesta --since "1 hour ago" # ventana de tiempo
journalctl -u ingesta --since today
journalctl -u ingesta -p err               # solo severidad error o peor
journalctl -u ingesta -b                   # solo desde el arranque actual
journalctl --user -u ingesta               # servicios de usuario, no del sistema
```

El `-f` es exactamente el `tail -f archivo.log` de toda la vida, pero vigilando el journal
en lugar de un archivo que tú creaste.

---

# 2. "Log your data in a tidy way"

Esta es la parte que la lección menciona casi de pasada y que, como intuiste, es la que más
se te va a repetir en la carrera.

La recomendación textual: cuando agregues logs para depurar, formatea la salida para que se
pueda **graficar después**. Un timestamp y un valor en CSV (`1705012345,42.5`) es muchísimo
más fácil de plotear que una frase en prosa.

## 2.1 Por qué no es una nota de estilo

Compara estas dos líneas:

```text
2026-08-12T21:40:03Z [INFO ] terminé de cargar el archivo de agosto,
tardó como 12 segundos y fueron unas 12 mil filas
```

```text
2026-08-12T21:40:03Z,carga,ok,12.4,12480
```

En la primera, una computadora tendría que **interpretar lenguaje humano**. ¿"Como 12
segundos" es 11.8? ¿12.1? ¿12.4? ¿"Unas 12 mil filas" es 11 900, 12 000, 12 480? La
información *estaba* ahí y se perdió al escribirla en prosa.

La segunda tiene campos definidos:

```text
      timestamp          paso   estado   segundos   filas
          ↓               ↓       ↓         ↓         ↓
2026-08-12T21:40:03Z  , carga ,   ok   ,   12.4  ,  12480
```

Después de 200 corridas tienes esto:

```text
timestamp,paso,estado,segundos,filas
2026-08-12T21:40:03Z,carga,ok,12.4,12480
2026-08-12T22:05:12Z,carga,ok,11.8,11920
2026-08-12T22:31:47Z,carga,ok,14.2,15230
2026-08-12T22:59:01Z,carga,error,3.1,0
```

Y puedes preguntar: *¿cuál es el tiempo promedio de carga? ¿está creciendo el tiempo
conforme crecen las filas? ¿qué días falló?* Con la versión en prosa, cada una de esas
preguntas es un problema de procesamiento de texto. Con la versión CSV, es un `df.plot()`.

## 2.2 La regla, formalizada

*Tidy data* significa: **una observación por fila, una variable por columna, sin prosa en
las celdas.** Aplicado a logs, cada evento medible es una fila.

## 2.3 Corrección a la v1: `.log` + `.csv` no es la forma correcta de decirlo

Tu objeción era buena y la v1 estaba mal planteada. Decía "emite dos flujos: `ingesta.log` y
`metricas.csv`", y eso choca de frente con lo que acabamos de ver de systemd: si el journal
ya guarda tus mensajes, ¿para qué crear un `.log` a mano?

**No lo crees.** La frase correcta no es "dos archivos", es **dos tipos de información**:

```text
                        ingesta.sh
                             │
             ┌───────────────┴───────────────┐
             │                               │
             ↓                               ↓
     logs operacionales                  métricas
      "¿qué está pasando?"          "¿qué puedo medir?"
             │                               │
             ↓                               ↓
          stderr                            CSV
             │                               │
             ↓                               ↓
      systemd → journal                   archivo
             │                               │
             ↓                               ↓
        journalctl                     pandas / gráfica
```

Son dos preguntas distintas, y por eso conviven:

| | Responde | Formato | Dónde vive |
| --- | --- | --- | --- |
| **Logs** | ¿Qué pasó? ¿Por qué falló? ¿En qué paso va? | Prosa con niveles | stderr → journal |
| **Métricas** | ¿Cuánto tardó? ¿Cuántas filas? ¿Está empeorando? | Tidy, una fila por evento | CSV (o una tabla) |

Ejemplo del primero:

```text
[INFO ] iniciando ingesta de agosto
[INFO ] encontrado archivo agosto.csv
[WARN ] 23 filas con valores nulos
[INFO ] carga completada
```

Ejemplo del segundo:

```text
timestamp,paso,estado,segundos,filas
2026-08-12T21:40:03Z,carga,ok,12.4,12480
```

**Y `journalctl` tampoco sustituye al CSV**, que es la otra mitad de tu pregunta. Podrías
loguear "carga terminada en 12.4 segundos, 12480 filas" y leerlo perfectamente. Pero cuando
quieras *"la gráfica del tiempo de carga de los últimos 6 meses"*, tendrías que extraer
números de texto libre otra vez. El CSV te ahorra ese paso para siempre.

Un matiz honesto: el CSV es la solución **sencilla y didáctica** para empezar, no la única.
En producción esas métricas suelen ir a Prometheus, a una tabla de la base de datos, o los
logs estructurados a Loki o Elasticsearch. El concepto — separar "qué pasó" de "qué puedo
medir" — es el mismo en todos los casos; el CSV es la versión que puedes tener funcionando
hoy sin instalar nada.

## 2.4 El patrón para `ingesta.sh`

```bash
METRICAS="metricas.csv"
# el encabezado solo la primera vez
[[ -f "$METRICAS" ]] || echo "timestamp,paso,estado,segundos,filas" > "$METRICAS"

metrica() {  # uso: metrica <paso> <estado> <segundos> <filas>
  printf '%s,%s,%s,%s,%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" "$4" \
    >> "$METRICAS"
}

paso() {  # uso: paso <nombre> <comando...>
  local nombre="$1"; shift
  local t0 t1 dur estado=ok
  t0=$(date +%s.%N)                    # marca de tiempo con nanosegundos
  log INFO "inicia $nombre"
  "$@" || estado=fallo                 # ejecuta el comando; si falla, anota fallo
  t1=$(date +%s.%N)
  dur=$(echo "$t1 - $t0" | bc)         # bc hace la resta con decimales
  log INFO "termina $nombre estado=$estado dur=${dur}s"
  metrica "$nombre" "$estado" "$dur" "${FILAS:-0}"
}

paso extraer  descargar_api
paso limpiar  normalizar_csv
paso cargar   copy_a_postgres
```

Tres cosas que quizá no se leen solas:

- **`[[ -f "$METRICAS" ]] || echo ...`** — "si el archivo NO existe, escribe el encabezado".
  El `||` es el espejo del `&&`: ejecuta lo de la derecha solo si lo de la izquierda falló.
- **`"$@"`** — todos los argumentos restantes, pero **cada uno como palabra separada**. Aquí
  es crítico: `"$@"` ejecuta el comando correctamente; `"$*"` los pegaría en una sola cadena
  y no funcionaría. Regla: `$*` para mensajes de texto, `"$@"` para pasar argumentos.
- **`"$@" || estado=fallo`** — no dejamos que el fallo mate el script; lo anotamos y
  seguimos, para que la métrica quede registrada. (Es una excepción deliberada a `set -e`.)

Con eso, `metricas.csv` se vuelve un dataset histórico de tu propio pipeline. En dos semanas
puedes contestar "¿qué paso se está degradando?" con dos líneas de pandas, sin haber
instalado nada de observabilidad:

```python
import pandas as pd
df = pd.read_csv("metricas.csv", parse_dates=["timestamp"])
df.pivot_table(index="timestamp", columns="paso", values="segundos").plot()
```

---

# 3. `time`: Real / User / Sys

Cinco minutos, y es la única intuición de profiling que se transfiere entera a ingeniería de
datos.

## 3.1 Quién mide qué, y desde cuándo

El error de partida es pensar que son **tres cronómetros que alguien enciende a mano**. No
lo son: son **tres formas distintas de contabilizar lo que ocurre durante la ejecución**.
Los tres empiezan cuando el proceso arranca y terminan cuando muere; lo que cambia es qué
cuenta cada uno.

| Medida | Qué cuenta | Quién la provee |
| --- | --- | --- |
| **Real** | Tiempo de reloj de pared, de inicio a fin, **incluyendo el tiempo esperando** | `time`, mirando el reloj del sistema |
| **User** | Tiempo de CPU ejecutando **tu** código, en modo usuario | El kernel, que lleva la cuenta por proceso |
| **Sys** | Tiempo de CPU ejecutando **código del kernel** a petición de tu proceso | El kernel, misma contabilidad, otro contador |

La frase que resume todo:

> **`Real` mide duración. `User` y `Sys` miden consumo de CPU.**

Son unidades conceptualmente distintas aunque las dos se impriman en segundos. `Real` es
"cuánto esperé yo"; `User`+`Sys` es "cuánto trabajó el procesador para mí".

Un detalle de nombre que confunde a todo el mundo: **`User` no significa "tiempo del
usuario humano"**. Viene de *user space* / *user mode*, que es el modo de privilegio en el
que corre tu programa, en contraste con *kernel mode*.

Y sobre `Sys`: tu programa no puede tocar el disco, la red ni la memoria del sistema
directamente. Tiene que **pedírselo al kernel** mediante *system calls*:

```text
    tu programa
         │
         │  "ábreme este archivo"   ← open()
         ↓
      kernel                        ← este tiempo cuenta como SYS
         │
         │  habla con el disco
         ↓
       disco
```

Cada `open()`, `read()`, `write()`, `close()` o petición de red pasa por ahí. Ese tiempo se
acumula en `Sys`.

## 3.2 Un solo programa que produce los tres

En vez de tres ejemplos sueltos, este programa tiene una fase para cada medida:

```python
import time, os

# FASE 1 — ESPERAR: no pide CPU, solo deja pasar el reloj
time.sleep(2)

# FASE 2 — CALCULAR: CPU ejecutando código Python (modo usuario)
total = sum(i*i for i in range(5_000_000))

# FASE 3 — PEDIRLE COSAS AL KERNEL: una syscall write() por vuelta (modo kernel)
fd = os.open('/tmp/salida.txt', os.O_WRONLY | os.O_CREAT | os.O_TRUNC)
for i in range(400_000):
    os.write(fd, b'x\n')
os.close(fd)
```

Corrido de verdad:

```text
$ time python3 demo3.py

real    0m2.659s
user    0m0.526s
sys     0m0.133s
```

Ahora, la misma máquina, midiendo **cada fase por separado** para ver de dónde salió cada
número:

```text
### FASE 1 sola — solo esperar
real  0m2.017s     user  0m0.016s     sys  0m0.000s
       ↑ el reloj corrió              ↑ pero casi no hubo CPU

### FASE 2 sola — solo calcular
real  0m0.397s     user  0m0.396s     sys  0m0.000s
                          ↑ real ≈ user: puro cómputo

### FASE 3 sola — solo syscalls
real  0m0.335s     user  0m0.189s     sys  0m0.146s
                                             ↑ aquí sí aparece sys
```

En la línea de tiempo del programa completo:

```text
0s                     2.0s        2.4s      2.66s
│───────────────────────│───────────│──────────│
│      esperando        │ calculando│ syscalls │
│      (sleep 2)        │   (sum)   │ (write)  │
└───────────────────────┴───────────┴──────────┘
                    REAL = 2.659 s

USER = 0.526 s  ── se acumula solo en las dos franjas de la derecha
SYS  = 0.133 s  ── casi todo en la franja de syscalls
ESPERA = 2.0 s  ── la franja de la izquierda, invisible para user y sys
```

Y la cuenta cierra:

```text
REAL − (USER + SYS)  =  2.659 − (0.526 + 0.133)  =  2.000 s
                                                       ↑
                                          exactamente el sleep(2)
```

(Las fases sueltas suman un poco más que la corrida junta porque cada una paga el arranque
del intérprete de Python por separado — unos 30 ms cada vez.)

## 3.3 Qué significa exactamente `Real − (User + Sys)`

Preguntabas si es "el tiempo que tomó el sistema en acatar la orden, o cualquier actividad
que no corresponde al proceso". Ninguna de las dos, y la distinción importa.

Lo que el sistema tarda en atender tus órdenes **ya está contado en `Sys`**. Y las
actividades de otros procesos no aparecen en tu medición para nada.

La lectura correcta es más simple y más modesta:

> **Es el tiempo transcurrido durante el cual tu proceso no estaba consumiendo CPU.**

Nada más. Es una resta, no un diagnóstico. Y aquí está el punto que conviene tener claro:
**esa resta no te dice *por qué* esperó.** Pudo ser cualquiera de estas:

```text
                     tu proceso
                         │
                         ↓
                     esperando
                         │
     ┌──────────┬────────┼────────┬──────────┐
     ↓          ↓        ↓        ↓          ↓
   disco       red    sleep()    base      no había
                                de datos   CPU libre
```

Ese último caso es real y se olvida: si la máquina está saturada, tu proceso puede estar
*listo para correr* pero sin núcleo disponible. Eso también infla `Real` sin tocar `User`.

Un ejemplo donde la diferencia se vuelve concreta:

```python
resultado = postgres.execute("SELECT * FROM ventas")
```

```text
real = 5.0 s
user = 0.3 s
sys  = 0.1 s
        ↓
5.0 − 0.4 = 4.6 s de espera
```

Esos 4.6 segundos **no** significan que Linux estuvo 4.6 segundos ejecutando una syscall.
Significan: *durante 5 segundos existió este proceso, y solo 0.4 fueron CPU suya.* Los otros
4.6 los pasó esperando a Postgres — que sí estuvo trabajando duro, pero **en otro proceso,
con su propia contabilidad**. Para saber en qué recurso exactamente esperó necesitas otras
herramientas.

## 3.4 Por qué esto es *la* intuición para pipelines de datos

En una ingesta, el patrón de espera es el caso normal: estás esperando a la red, al disco, o
a que Postgres conteste. Eso cambia por completo qué optimización tiene sentido.

```text
real = 60 s              real = 60 s
user =  5 s              user = 55 s
sys  =  2 s              sys  =  3 s
   ↓                        ↓
CPU    ≈  7 s            CPU    ≈ 58 s
espera ≈ 53 s            espera ≈  2 s
   ↓                        ↓
NO es problema           SÍ es problema
de algoritmo             de procesamiento
```

| Diagnóstico | Qué NO sirve | Qué sí sirve |
| --- | --- | --- |
| `User+Sys ≪ Real` (esperando) | Reescribir el algoritmo | Paralelizar, batchear requests, reusar conexiones, `COPY` en vez de `INSERT` fila por fila |
| `User ≈ Real` (CPU) | Más hilos de I/O | Mejor algoritmo, vectorizar, mover el cálculo a SQL |
| `Sys` alto | Optimizar tu lógica | Menos syscalls: buffers más grandes, menos `open`/`close`, menos escrituras chiquitas |

La fase 3 del ejemplo de arriba es justo el tercer caso en miniatura: 400 000 llamadas a
`write()` de dos bytes cada una. Con un buffer que escribiera de a 64 KB, el mismo trabajo
haría unas 12 syscalls en lugar de 400 000.

## 3.5 Multicore: por qué `User` puede ser mayor que `Real`

**Multicore no significa "varios procesos a la vez".** Significa que el procesador tiene
varios **núcleos**, cada uno capaz de ejecutar instrucciones de forma simultánea:

```text
CPU
├── Core 1
├── Core 2
├── Core 3
└── Core 4
```

(Varios procesos a la vez puedes tenerlos incluso con un solo núcleo: el sistema los va
alternando muy rápido. Eso es *concurrencia*. Varios núcleos trabajando de verdad al mismo
tiempo es *paralelismo*.)

La analogía que lo aclara: piensa en los núcleos como **personas trabajando**.

```text
UNA PERSONA
Persona 1: ██████████ 10 min
                              REAL = 10 min    (lo que tardó en pasar)
                              USER = 10 min    (esfuerzo total invertido)

DOS PERSONAS EN PARALELO
Persona 1: ██████████ 10 min
Persona 2: ██████████ 10 min
                              REAL = 10 min    ← el reloj sigue siendo uno
                              USER = 20 min    ← 20 minutos-persona de esfuerzo
```

La tarea terminó en 10 minutos porque había dos trabajando, pero se consumieron 20
minutos-persona. `Real` es el reloj de la pared; `User` es la suma del esfuerzo de todos los
núcleos. Por eso `User > Real` no es un error: es la firma del paralelismo.

Lo comprobé en esta máquina, que tiene **2 núcleos** (`nproc` → 2). El mismo trabajo total,
hecho de dos maneras:

```text
=== en serie: 4 tandas de cálculo, una tras otra ===
real  0m1.428s
user  0m1.427s          ← user ≈ real: un solo núcleo ocupado

=== en paralelo con multiprocessing.Pool(4) ===
real  0m0.836s          ← terminó en la mitad del tiempo
user  0m1.493s          ← ¡user MAYOR que real!
sys   0m0.042s
```

`user 1.493 > real 0.836`. El esfuerzo total de CPU fue casi el mismo en los dos casos
(~1.43 s contra ~1.49 s — el extra es el costo de crear los procesos), pero repartido entre
dos núcleos el reloj marcó la mitad.

La lectura práctica: **si `User` es aproximadamente `Real` en una máquina de varios núcleos,
estás usando uno solo** y probablemente hay una mejora fácil disponible.

## 3.6 Dos notas sueltas sobre `time`

- Bash tiene un `time` **builtin** (el que da la salida de tres líneas que has visto). El
  binario `/usr/bin/time -v` es otro programa y da mucho más: memoria máxima usada (max
  RSS), fallos de página, cambios de contexto. Útil cuando sospechas que el problema es
  memoria y no tiempo.
- El formato `0m2.659s` se lee "0 minutos y 2.659 segundos".

---

# 4. `lsof` y `ss`

## 4.1 `lsof` — y el cabo suelto del archivo borrado

`lsof` = *list open files*. Lista los archivos abiertos por cada proceso. Y como en Unix
casi todo es un archivo (sockets, pipes, dispositivos), ve prácticamente todo.

**El caso que cierra tu nota:** `rm` **no borra datos**. Lo que hace es eliminar la entrada
del directorio — el *link* que apunta al contenido. Los datos reales viven en un **inodo**,
y el inodo se libera solo cuando se cumplen dos condiciones a la vez:

```text
        ¿se puede liberar el espacio?
                     │
         ┌───────────┴───────────┐
         ↓                       ↓
  ¿links = 0?            ¿nadie lo tiene abierto?
   (ya hiciste rm)        (ningún proceso con fd)
         │                       │
         └───────────┬───────────┘
                     ↓
            las DOS → se libera
            solo una → sigue ocupando disco
```

Si un proceso lo tenía abierto cuando hiciste `rm`, el archivo desaparece de `ls` y `du`
deja de contarlo — **pero sigue ocupando el disco**. El síntoma es inconfundible: **`du`
dice que hay espacio, `df` dice que no.** Ese desacuerdo es la firma del problema.

Lo reproduje completo. Creé 200 MB con un proceso escribiéndolo, lo borré, y miré `df`:

```text
=== 200 MB creados ===
/dev/vda   252G   13G   30G  29% /

=== después de rm ===
ls: cannot access '/tmp/big.log': No such file or directory
/dev/vda   252G   13G   30G  29% /        ← df NO bajó ni un byte

=== lsof +L1 ===
COMMAND  PID USER  FD  TYPE  DEVICE  SIZE/OFF  NLINK   NODE  NAME
python3 4544 root   3w  REG   254,0  200000000      0 688155  /tmp/big.log (deleted)
                    ↑                                  ↑                      ↑
              fd 3, abierto                    links = 0            el kernel te avisa
              para escritura                (ya lo borraste)

=== después de matar al proceso ===
/dev/vda   252G   12G   31G  29% /        ← el espacio volvió
```

Las dos pistas del diagnóstico son `NLINK 0` y el sufijo `(deleted)`. El espacio solo
regresó cuando murió el proceso que lo tenía abierto.

Los comandos:

```bash
sudo lsof +L1                      # archivos con NLINK < 1: borrados pero aún abiertos
sudo lsof -nP | grep '(deleted)'   # la variante con grep, mismo resultado
sudo lsof /ruta/al/archivo         # ¿quién tiene abierto ESTE archivo?
sudo lsof -p 4544                  # ¿qué tiene abierto ESTE proceso?
```

(`+L1` se lee "muéstrame los que tienen menos de 1 link". `-n` no resuelve nombres de host y
`-P` no resuelve nombres de puerto: ambos solo para que vaya más rápido.)

Y el truco para recuperar el espacio **sin matar el proceso** — sirve cuando es un servicio
en producción que no puedes reiniciar:

```bash
: > /proc/<PID>/fd/<FD>
```

Con los datos de arriba sería `: > /proc/4544/fd/3`. Se lee así: `/proc/<PID>/fd/<FD>` es
una puerta trasera al descriptor abierto del proceso, y `: >` lo trunca a cero bytes. El `:`
es el comando nulo de Bash (no hace nada, sale con éxito); lo único que importa aquí es la
redirección, que vacía el destino. El proceso sigue vivo y el disco se libera.

## 4.2 `ss` — qué proceso ocupa un puerto

`ss` = *socket statistics*. Reemplaza al viejo `netstat`. El uso que importa es averiguar
quién tiene tomado un puerto:

```bash
ss -tlnp | grep :8080
```

| Flag | Qué hace |
| --- | --- |
| `-t` | Solo TCP |
| `-l` | Solo sockets en escucha (*listening*) |
| `-n` | Numérico — no resuelve nombres de host ni puerto (mucho más rápido) |
| `-p` | Muestra el proceso dueño (necesita root para procesos ajenos) |

Vale más recordar los flags sueltos que memorizar la línea: `-t` TCP, `-l` listening, `-n`
numérico, `-p` proceso.

## 4.3 Ejercicio 5 de profiling — hecho

El enunciado: levanta un servidor mínimo en el puerto 4444, encuentra el proceso desde otra
terminal, mátalo. Lo corrí; esta es la salida real:

```text
$ python3 -m http.server 4444 &

$ ss -tlnp | grep 4444
LISTEN 0  5  0.0.0.0:4444  0.0.0.0:*  users:(("python3",pid=4172,fd=3))
                                                          ↑
                                                    esto es lo que buscas

$ lsof -i :4444                    # equivalente, por si no tienes ss
COMMAND  PID USER  FD  TYPE  DEVICE SIZE/OFF NODE NAME
python3 4172 root   3u  IPv4    6315      0t0  TCP *:4444 (LISTEN)

$ kill 4172
$ ss -tlnp | grep 4444
(puerto 4444 libre)
```

Leyendo la línea de `ss`: `LISTEN` es el estado, `0.0.0.0:4444` es dónde escucha (`0.0.0.0`
= en todas las interfaces de red), y `users:((...))` es el proceso dueño.

Para automatizarlo:

```bash
ss -tlnp | grep :4444 | grep -oP 'pid=\K[0-9]+'
```

(`-o` imprime solo lo que coincide, `-P` activa expresiones regulares de Perl, y `\K`
descarta todo lo que quedó a la izquierda — así sale el número limpio, sin el `pid=`.)

Si `ss` no está instalado, pasa en contenedores mínimos: `apt-get install iproute2`, o usa
`lsof -i :4444`, que viene en más sistemas.

---

# 5. Lo que puedes hacer hoy, en orden

1. **Levantar `python3 -m http.server 4444` y matarlo con `ss -tlnp`.** Cinco minutos, es el
   ejercicio 5 completo.
2. **Correr `time` sobre tu `ingesta.sh` actual** y mirar la brecha `Real − (User + Sys)`.
   Sabrás si tu cuello de botella es CPU o espera antes de tocar una línea de código.
3. **Meter la función `log()` con `LOG_LEVEL`** en `ingesta.sh` — cubre el requisito de
   registrar cada paso con timestamp. Incluye la validación de nivel de §1.6.
4. **Agregar `metricas.csv`** con las funciones `metrica()` y `paso()`. Es lo que en tres
   meses te va a dar la gráfica.
5. **Revisar si tienes algún `< <(...)` o pipe** en el script y decidir si necesitas
   `PIPESTATUS` ahí.

---

**Fuente:** [Debugging and Profiling — The Missing Semester of Your CS Education, MIT
(2026)](https://missing.csail.mit.edu/2026/debugging-profiling/)
