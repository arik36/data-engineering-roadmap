# scripts

Herramientas de línea de comandos del `data-engineering-roadmap`. Las dos siguen el mismo contrato: **el resultado va a `stdout`, los logs van a `stderr`, y el código de salida identifica el modo de falla.**

---

# contar-lineas.sh

## Qué es y por qué existe
`contar-lineas.sh` es una herramienta de automatización diseñada para medir el volumen de documentación en un proyecto. Existe para proporcionar una forma rápida y programable de auditar cuántas líneas de texto en formato Markdown (`.md`) hay en una estructura de directorios, garantizando que el resultado pueda ser consumido por otros programas sin requerir limpieza de texto adicional.

## Ejemplos de uso
Al ejecutar el script en diferentes escenarios, esta es la salida real esperada. Nota cómo los logs se imprimen con formato de fecha, mientras que el resultado numérico se imprime solo.

**Sin argumentos:**
```text
$ ./contar-lineas.sh
2026-08-21T00:00:00Z [ERROR] uso: ./contar-lineas.sh <directorio> (usa --help para más información)
```

**Con un directorio que no existe:**
```text
$ ./contar-lineas.sh /noexiste
2026-08-21T00:00:00Z [ERROR] el directorio /noexiste no existe
```

**Con un directorio sin archivos `.md`:**
```text
$ ./contar-lineas.sh /tmp/vacio
2026-08-21T00:00:00Z [INFO] iniciamos el conteo de líneas en archivos .md en el directorio /tmp/vacio
2026-08-21T00:00:00Z [INFO] no se encontraron archivos .md en /tmp/vacio
0
```

**Con un directorio válido (camino feliz):**
```text
$ ./contar-lineas.sh /tmp/prueba-md
2026-08-21T00:00:00Z [INFO] iniciamos el conteo de líneas en archivos .md en el directorio /tmp/prueba-md
2026-08-21T00:00:00Z [INFO] conteo terminado: 15 líneas en /tmp/prueba-md
15
```

## El contrato de salida
Este script aplica una separación estricta de flujos: **el resultado numérico siempre va a `stdout`, y los registros de información/error (logs) siempre van a `stderr`.**

Este diseño es fundamental para la programabilidad. Permite capturar de manera limpia el número resultante en una variable para operaciones posteriores, mientras el usuario aún puede ver los logs en su pantalla. 

Ejemplo que justifica este contrato:
```bash
# Los logs se mostrarán en la terminal, pero la variable 'total' 
# almacenará estrictamente el número, nunca el texto del log.
total=$(./contar-lineas.sh /ruta/al/proyecto)

echo "El total para enviar a la base de datos es: $total"
```

## Dependencias
Como todo artefacto de software, este script declara lo que da por sentado sobre su entorno de ejecución. Para funcionar de manera aislada o en otra máquina, asume que el sistema cuenta con:
* `bash` (intérprete)
* `find` (búsqueda de archivos)
* `wc` (conteo de líneas)

## Códigos de salida

| Código | Significado |
| :--- | :--- |
| `0` | **Éxito:** El conteo finalizó correctamente (incluso si el resultado es 0 líneas). |
| `1` | **Error de uso:** No se proporcionó el argumento del directorio. |
| `2` | **Error de entrada:** El directorio especificado no existe. |
| `3` | **Error de ejecución:** Falló el escaneo del directorio (ej. falta de permisos). |

---

# ingesta.sh

## Qué es y por qué existe
`ingesta.sh` descarga un archivo CSV desde una URL, lo valida antes de aceptarlo, y lo deja en un directorio con un nombre fechado.

Existe para ser el primer paso de un pipeline de datos, y su trabajo real no es descargar: es **no dejar entrar un archivo roto**. Antes de que el archivo aparezca en su ruta final, el script comprueba que la respuesta HTTP sea `200`, que el archivo no venga vacío, que traiga al menos una línea de datos además del encabezado, y que el encabezado contenga las columnas que el resto del pipeline espera.

La descarga va primero a un archivo temporal en el mismo directorio destino, y solo se mueve al nombre definitivo si todas las validaciones pasan. Un `trap ... EXIT` borra el temporal pase lo que pase. La consecuencia importante: **nunca existe un archivo con el nombre definitivo a medio escribir o inválido** — para quien lea ese directorio, el archivo aparece completo o no aparece.

## Cómo se invoca

```bash
./ingesta.sh <URL> <directorio-destino> <columnas>
./ingesta.sh --help
```

Camino feliz — el script no imprime logs cuando todo sale bien, solo la ruta:

```text
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/population/main/data/population.csv" \
      "/home/mlizz/projects/data-engineering-roadmap/data/raw" \
      "Country Name,Year,Value"
/home/mlizz/projects/data-engineering-roadmap/data/raw/2026-09-01_population.csv
```

La segunda vez el mismo día, no descarga nada:

```text
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/population/main/data/population.csv" \
      "/home/mlizz/projects/data-engineering-roadmap/data/raw" \
      "Country Name,Year,Value"
2026-09-01T09:00:00Z [INFO] el archivo /home/.../data/raw/2026-09-01_population.csv ya existe, no se descargará de nuevo
/home/mlizz/projects/data-engineering-roadmap/data/raw/2026-09-01_population.csv
```

## Los tres argumentos

| # | Argumento | Qué es |
| :--- | :--- | :--- |
| 1 | `<URL>` | URL del CSV a descargar. **El nombre del archivo de salida se deriva de aquí:** se descarta el query string (todo lo que siga a `?`) y se toma el `basename`. |
| 2 | `<directorio-destino>` | Dónde se escribe el archivo. **Debe existir** y tener permisos de lectura y escritura — el script no lo crea. Ahí se escriben tanto el temporal como el archivo final. |
| 3 | `<columnas>` | Lista separada por comas de las columnas que debe traer el encabezado. Se comprueban **todas**, y **el orden no importa**. |

**Formato del argumento `<columnas>`:** sin comas al inicio ni al final, y sin comas dobles. Los espacios *dentro* de un nombre de columna sí se permiten, así que `"Country Name,Year,Value"` es válido. Se rechazan `",a,b"`, `"a,b,"` y `"a,,b"`.

**Nombre del archivo de salida:** `<AAAA-MM-DD>_<nombre>.csv`, con la fecha en **UTC**. Si el CSV de origen ya termina en `.csv`, la extensión no se duplica. El archivo final queda con permisos `644`.

## El contrato de salida

Igual que `contar-lineas.sh`, con flujos separados:

* **`stdout`** — una sola línea: la ruta del archivo escrito. Nada más.
* **`stderr`** — todos los logs, con formato `AAAA-MM-DDTHH:MM:SSZ [INFO|ERROR] mensaje`.
* **`--help`** va a `stdout` y sale con `0`: no es un error, es lo que se pidió.

```bash
# 'ruta' contiene estrictamente la ruta del archivo, nunca el texto de un log.
ruta=$(./ingesta.sh "$URL" "$DESTINO" "Country Name,Year,Value")
wc -l < "$ruta"
```

El contrato se cumple igual haya descarga o no: en el caso idempotente `stdout` emite la misma ruta. **Quien llama no necesita saber cuál de los dos casos ocurrió** — pide una ruta y recibe una ruta.

## Dependencias

* `bash` (intérprete, con `set -euo pipefail`)
* `curl` (descarga y captura del código HTTP)
* Utilidades estándar: `date`, `basename`, `mktemp`, `head`, `tr`, `grep`, `mv`, `chmod`, `rm`

## Códigos de salida

| Código | Significado |
| :--- | :--- |
| `0` | **Éxito:** el archivo se descargó, validó y escribió. También cubre el caso idempotente (ya existía) y `--help`. |
| `1` | **Fallo inesperado:** lo asigna `set -e`, no el script. Si aparece, es un error no previsto. |
| `2` | **HTTP distinto de 200:** el servidor respondió, pero con otro código (404, 500…). |
| `3` | **Validación de contenido:** el archivo llegó vacío, sin datos más allá del encabezado, o le faltan columnas pedidas. |
| `4` | **Error de uso:** falta alguno de los tres argumentos. |
| `5` | **Error de entrada:** el directorio destino no existe. |
| `6` | **Error de permisos:** el directorio existe pero no tiene lectura/escritura. |
| `7` | **Error de uso:** el formato del argumento `<columnas>` es incorrecto. |
| `8` | **URL inaccesible:** falló el propio `curl` (DNS, conexión rechazada, timeout). |

**La diferencia entre `8` y `2` importa.** `curl` sale con `0` aunque el servidor conteste `404` o `500` — un código HTTP no es un código de salida. Por eso son dos casos distintos: `8` significa *no se pudo hablar con el servidor*, y `2` significa *el servidor contestó, pero no lo que esperábamos*. Para quien reintenta, no son lo mismo.

## El flujo interno, en orden

Todo el comportamiento del script —incluido el que sorprende— sale de este orden. Los números entre paréntesis son las líneas de `ingesta.sh`.

```
1. ¿--help?                      (12–40)    → exit 0
2. validar argumentos            (48–68)    → exit 4, 5, 6, 7
3. construir archivo_destino     (75–78)      fecha + nombre de la URL
4. ¿archivo_destino existe?      (82–86)    → exit 0   ← idempotencia
5. crear temporal + trap         (93–95)
6. curl                          (107–115)  → exit 8, exit 2
7. validar contenido             (126–168)  → exit 3
8. mv + chmod + echo             (180–182)  → exit 0
```

**El paso 4 corta antes del 6 y del 7.** Esa sola frase explica el resultado más confuso de las pruebas de abajo.

## Idempotencia

El nombre del archivo lleva la fecha UTC, y **antes de tocar la red** el script comprueba si ese archivo ya existe. Si existe, escribe la ruta a `stdout` y sale con `0` sin descargar nada.

En la práctica: **correrlo dos veces el mismo día no vuelve a descargar.** Un reintento después de un fallo de red no vuelve a golpear el servidor.

**La idempotencia no prohíbe actualizar.** Lo que prohíbe es que una repetición *accidental* cambie el estado. Un reprocesamiento *intencional* —un futuro `--force`— sería una operación distinta, invocada a propósito, y no violaría nada: el comportamiento por defecto seguiría siendo idempotente y actualizar sería otra cosa que se pide explícitamente. No están en conflicto por naturaleza; solo lo estarían si se quisiera que el mismo comando hiciera las dos. *(`--force` todavía no está implementado.)*

**Detalle de orden, que conviene saber:** la comprobación de idempotencia ocurre *antes* de validar las columnas. Si el archivo del día ya existe, el script devuelve esa ruta sin revalidar el encabezado. Es coherente con "no repitas trabajo ya hecho", pero significa que cambiar el argumento `<columnas>` no fuerza una revalidación el mismo día.

## Pruebas

Cinco pruebas contra tres orígenes reales, en `/tmp/capstone`. La idea no es demostrar que el camino feliz funciona —eso es lo fácil— sino que **cada modo de falla se dispara donde debe y deja el disco como debe**.

| # | Origen | Qué comprueba | Paso del flujo | Esperado |
|---|---|---|---|---|
| 1 | GDP | camino feliz completo | 1→8 | `0` + la ruta |
| 2 | sea-level | la validación es "contiene", no "igual a" | 7 | `0` pidiendo 2 de 5 columnas |
| 3 | VIX | un tercer origen, otro formato de cabecera | 1→8 | `0` + la ruta |
| 4 | VIX en minúsculas | rechazo de datos **con HTTP 200** | 7 | `3`, y **sin archivo** |
| 5 | GDP repetido | idempotencia | 4 | `0`, y `mtime` sin cambiar |

### Preparación: mirar la cabecera antes de invocar

No se puede pedir columnas sin saber cómo se llaman. Por eso el primer paso fue leer solo la primera línea de cada CSV:

```text
$ curl -sS https://raw.githubusercontent.com/datasets/gdp/master/data/gdp.csv | head -1
Country Name,Country Code,Year,Value
curl: (23) Failure writing output to destination

$ curl -sS https://raw.githubusercontent.com/datasets/sea-level-rise/master/data/epa-sea-level.csv | head -1
Year,CSIRO Adjusted Sea Level,Lower Error Bound,Upper Error Bound,NOAA Adjusted Sea Level

$ curl -sS https://raw.githubusercontent.com/datasets/finance-vix/master/data/vix-daily.csv | head -1
DATE,OPEN,HIGH,LOW,CLOSE
curl: (23) Failure writing output to destination
```

**Ese `curl: (23)` no es un fallo del servidor ni del archivo.** Es esto: `head -1` imprime una línea y se cierra. Cuando `head` cierra su extremo del pipe, `curl` sigue escribiendo y recibe un `EPIPE` — *escritura a una tubería sin lector*. `curl` lo reporta como error 23.

Y explica por qué el de `sea-level` **no** dio el error: la tubería de Linux tiene un búfer de 64 KB. `epa-sea-level.csv` pesa 6 KB, así que `curl` terminó de escribir *antes* de que `head` cerrara. `gdp.csv` (562 KB) y `vix-daily.csv` (481 KB) no caben, siguen escribiendo, y se topan con la tubería cerrada.

Lo interesante para nuestro tema es que **el error no se ve en `$?`**:

```bash
curl -sS "$url" | head -1
echo "$?"                    # → 0   (el de head)
echo "${PIPESTATUS[@]}"      # → 23 0  (curl sí falló)
```

Es exactamente el modo de falla de `notes/bash/errores.md`: *bash reporta el estado del último comando, y en un pipe eso miente*. Aquí es inofensivo —solo queríamos ver la cabecera— pero en un script sería un fallo silencioso.

### Prueba 1 — camino feliz

```text
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/gdp/master/data/gdp.csv" \
    /tmp/capstone "Country Name,Country Code,Year,Value"; echo "exit: $?"
/tmp/capstone/2026-09-02_gdp.csv
exit: 0
```

Recorre los ocho pasos. Sin logs, porque el camino feliz no emite ninguno: la única salida es la ruta en `stdout`, tal como dice el contrato.

### Prueba 2 — la validación es "contiene", no "igual a"

```text
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/sea-level-rise/master/data/epa-sea-level.csv" \
    /tmp/capstone "Year,CSIRO Adjusted Sea Level"; echo "exit: $?"
/tmp/capstone/2026-09-02_epa-sea-level.csv
exit: 0
```

**Es más sutil de lo que parece.** Ese CSV tiene cinco columnas y solo se pidieron dos. Si la validación comparara la cabecera completa contra el argumento, habría fallado. Que pase con `0` demuestra cómo está escrita, en las líneas 157–161:

```bash
for columna in "${pedidas[@]}"; do
    if [[ "$cabecera" != *,"$columna,"* ]]; then
        columnas_faltantes="$columnas_faltantes, $columna"
    fi
done
```

Recorre **una por una** las columnas pedidas y busca cada una dentro de la cabecera. No compara cadenas completas. Por eso el orden tampoco importa.

El truco de las comas está en la línea 152:

```bash
cabecera=",$(head -n 1 "$archivo_temporal" | tr -d '\r'),"
```

Se le pegan comas al principio y al final para que **toda** columna quede rodeada de comas, incluidas la primera y la última. Así el patrón `*,"$columna,"*` es una comparación exacta de nombre completo: buscar `,Year,` nunca coincide por accidente con `,Year_2,`. El `tr -d '\r'` quita el retorno de carro por si el CSV viene con finales de línea de Windows — sin eso, la última columna de la cabecera sería `Value\r` y nunca coincidiría.

### Prueba 3 — un tercer origen

```text
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/finance-vix/master/data/vix-daily.csv" \
    /tmp/capstone "DATE,CLOSE"; echo "exit: $?"
/tmp/capstone/2026-09-02_vix-daily.csv
exit: 0
```

Otro camino feliz, con una cabecera en mayúsculas. **Esta prueba crea el archivo que va a arruinar la siguiente.**

### Prueba 4 — el rechazo de datos… que la primera vez no probó nada

La intención era pedir las mismas columnas en **minúsculas** y ver el rechazo, porque la comparación de bash distingue mayúsculas. Esto es lo que salió:

```text
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/finance-vix/master/data/vix-daily.csv" \
    /tmp/capstone "date,close"; echo "exit: $?"
2026-09-02T02:14:14Z [INFO] el archivo /tmp/capstone/2026-09-02_vix-daily.csv ya existe, no se descargará de nuevo
/tmp/capstone/2026-09-02_vix-daily.csv
exit: 0
```

Salió `0`. No rechazó nada. **Y la razón es que la validación nunca llegó a correr.**

#### Por qué: el nombre del archivo no depende de las columnas

Mira cómo se construye el destino, líneas 75–78:

```bash
nombre_archivo=$(basename "${url%%\?*}")          # → vix-daily.csv
fecha=$(date -u +%Y-%m-%d)                        # → 2026-09-02
archivo_destino="$directorio/${fecha}_${nombre_archivo%.csv}.csv"
                                                  # → /tmp/capstone/2026-09-02_vix-daily.csv
```

El nombre sale de **dos cosas: la fecha y la URL.** El argumento `<columnas>` no aparece por ningún lado.

Entonces sigue la ejecución paso a paso:

| Paso | Prueba 3 (`DATE,CLOSE`) | Prueba 4 (`date,close`) |
|---|---|---|
| 3. construir nombre | `2026-09-02_vix-daily.csv` | `2026-09-02_vix-daily.csv` ← **el mismo** |
| 4. ¿existe? | no → sigue | **sí** → `echo` ruta, `exit 0` |
| 6. `curl` | descarga | **nunca corre** |
| 7. validar columnas | compara y pasa | **nunca corre** |
| 8. `mv` | escribe el archivo | nunca corre |

La línea 82 es la que corta:

```bash
if [ -f "$archivo_destino" ]; then
    log INFO "el archivo $archivo_destino ya existe, no se descargará de nuevo"
    echo "$archivo_destino"
    exit 0
fi
```

El archivo existía porque **lo había creado la prueba 3, cuarenta segundos antes**. El script vio un archivo con ese nombre, dio por hecho que el trabajo ya estaba hecho, y salió con éxito. Las minúsculas nunca se compararon contra nada: el string `"date,close"` se guardó en una variable en la línea 44 y jamás se usó.

Eso es lo que quiere decir **"la idempotencia se comió la validación"**: el atajo del paso 4 saltó por encima del paso 7, que era justo el que se quería medir.

#### Por qué hizo falta el `rm`

Para que la prueba midiera algo, había que quitar la condición que la cortaba. Borrar el archivo hace que `[ -f "$archivo_destino" ]` sea falso, el paso 4 no dispare, y la ejecución llegue hasta la validación:

```text
$ rm /tmp/capstone/2026-09-02_vix-daily.csv
$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/finance-vix/master/data/vix-daily.csv" \
    /tmp/capstone "date,close"; echo "exit: $?"
2026-09-02T02:19:38Z [ERROR] las siguientes columnas no se encuentran en el archivo descargado: date, close
exit: 3

$ ls -l /tmp/capstone/
total 560
-rw-r--r-- 1 mlizz mlizz   6249 Sep  1 20:10 2026-09-02_epa-sea-level.csv
-rw-r--r-- 1 mlizz mlizz 562767 Sep  1 20:09 2026-09-02_gdp.csv
```

Ahora sí: descargó de verdad, comparó `date` y `close` contra la cabecera `DATE,OPEN,HIGH,LOW,CLOSE`, no encontró ninguna —la comparación de bash distingue mayúsculas— y salió con `3`.

**Y el `ls -l` de después es la mitad que importa.** El exit `3` dice que el script *supo* que los datos estaban mal; el `ls` demuestra que además *no dejó nada*. El archivo `vix-daily` no está en la lista: la descarga fue a un temporal (línea 93), la validación falló antes del `mv` (línea 180), y el `trap ... EXIT` de la línea 95 borró el temporal al salir. **Un fallo de datos no ensucia el directorio.** Sin ese `ls` solo sabrías el código de salida, no el efecto real.

#### El problema de diseño que esto destapa

Dos invocaciones con **columnas distintas** producen el mismo archivo y el mismo `exit 0`. El script no puede distinguirlas porque **la identidad del artefacto no captura todo lo que lo produjo**: el nombre codifica fecha y origen, pero no el contrato que se validó.

En la práctica significa que el script confía en que la corrida anterior validó lo mismo que estás pidiendo ahora — y eso no tiene por qué ser cierto. Es la misma limitación que la nota de "Detalle de orden" en la sección de idempotencia, vista desde el lado de quien la sufre.

### Prueba 5 — idempotencia medida en el disco, no en la salida

```text
$ ls -l --time-style=full-iso /tmp/capstone/*gdp*
-rw-r--r-- 1 mlizz mlizz 562767 2026-09-01 20:09:11.410613107 -0600 /tmp/capstone/2026-09-02_gdp.csv

$ ./ingesta.sh "https://raw.githubusercontent.com/datasets/gdp/master/data/gdp.csv" \
    /tmp/capstone "Country Name,Year,Value"; echo "exit: $?"
2026-09-02T02:14:55Z [INFO] el archivo /tmp/capstone/2026-09-02_gdp.csv ya existe, no se descargará de nuevo
/tmp/capstone/2026-09-02_gdp.csv
exit: 0

$ ls -l --time-style=full-iso /tmp/capstone/*gdp*
-rw-r--r-- 1 mlizz mlizz 562767 2026-09-01 20:09:11.410613107 -0600 /tmp/capstone/2026-09-02_gdp.csv
```

#### Por qué el `ls -l` va antes y después

**Porque la idempotencia no se ve en la salida.** El script imprime la misma ruta y sale con `0` en los dos casos —haya descargado o no— y eso es a propósito: es el contrato de la sección anterior. Pero justo por eso la salida no sirve para *comprobar* la idempotencia.

Lo único que distingue "no descargué" de "descargué y reemplacé" es **si el archivo se volvió a escribir**. Y eso se ve en la fecha de modificación:

```
antes:    20:09:11.410613107
después:  20:09:11.410613107     ← idéntica, al nanosegundo
```

Si hubiera descargado otra vez, el `mv` de la línea 180 habría puesto un archivo nuevo en esa ruta y el `mtime` sería el de ese instante. Que no cambie **es la prueba de que el paso 4 cortó la ejecución.**

Es el mismo principio del `ls` de la prueba 4: comprobar el efecto en el disco, no solo el código de salida. Un script puede decir `0` y haber hecho algo distinto de lo que dice.

*(Detalle: aquí se pidieron 3 de las 4 columnas del GDP, distintas a las de la prueba 1. No importó — por lo mismo que en la prueba 4, el paso 4 cortó antes de mirarlas.)*

#### Qué significa cada columna de `ls -l`

```
-rw-r--r--  1  mlizz  mlizz  562767  Sep  1 20:09  2026-09-02_gdp.csv
    │       │    │      │       │         │              └── nombre
    │       │    │      │       │         └── fecha de modificación (mtime)
    │       │    │      │       └── tamaño en bytes
    │       │    │      └── grupo
    │       │    └── dueño
    │       └── número de enlaces duros al inodo
    └── tipo + permisos
```

El primer campo se lee en cuatro trozos:

```
-        rw-       r--       r--
tipo     dueño     grupo     otros
```

* **tipo** — `-` archivo normal, `d` directorio, `l` enlace simbólico.
* **`rw-`** el dueño lee y escribe, no ejecuta.
* **`r--`** el grupo solo lee. **`r--`** los demás solo leen.

Eso es `644`, que es exactamente lo que pone la línea 181 (`chmod 644`). Verlo en el `ls` confirma que el `chmod` corrió: `mktemp` crea a `600` por diseño y `mv` conserva los permisos del temporal, así que sin ese `chmod` el archivo saldría `-rw-------` y nadie más podría leerlo.

#### Por qué `--time-style=full-iso`

Sin esa bandera, `ls -l` muestra `Sep 1 20:09` — **solo hasta el minuto**. Dos corridas separadas por segundos se verían con la misma fecha, y la prueba no probaría nada: un `mtime` "igual" podría ser en realidad una reescritura ocurrida dentro del mismo minuto.

Con `--time-style=full-iso` sale `2026-09-01 20:09:11.410613107 -0600`: fecha completa, hora con **nanosegundos** y zona horaria. A esa resolución, dos escrituras distintas no pueden coincidir por casualidad. La bandera convierte una observación sugerente en una prueba.

### La inspección final

```text
$ ls -l /tmp/capstone/
total 1032
-rw-r--r-- 1 mlizz mlizz   6249 Sep  1 20:10 2026-09-02_epa-sea-level.csv
-rw-r--r-- 1 mlizz mlizz 562767 Sep  1 20:09 2026-09-02_gdp.csv
-rw-r--r-- 1 mlizz mlizz 481368 Sep  1 20:12 2026-09-02_vix-daily.csv
```

**`ls -l` del directorio** responde tres preguntas de una vez: que están los tres archivos esperados y ninguno de más (nada de temporales `ingesta.XXXXXX` olvidados), que el nombre fechado se aplicó a los tres, y que ninguno pesa `0` bytes — un archivo vacío sería la firma de una descarga que falló a medias.

```text
$ head -2 /tmp/capstone/*.csv
==> /tmp/capstone/2026-09-02_epa-sea-level.csv <==
Year,CSIRO Adjusted Sea Level,Lower Error Bound,Upper Error Bound,NOAA Adjusted Sea Level
1880,0,-0.952755905,0.952755905,

==> /tmp/capstone/2026-09-02_gdp.csv <==
Country Name,Country Code,Year,Value
Afghanistan,AFG,2000,3521418059.923445

==> /tmp/capstone/2026-09-02_vix-daily.csv <==
DATE,OPEN,HIGH,LOW,CLOSE
1990-01-02,17.240000,17.240000,17.240000,17.240000
```

**`head -2` sobre el comodín** imprime las dos primeras líneas de cada archivo, con separadores `==> nombre <==` porque son varios archivos.

Dos líneas y no una, porque cada una prueba algo distinto:

* la **primera** es la cabecera, y confirma que las columnas son las que se pidieron;
* la **segunda** es un registro de datos, y confirma que hay filas de verdad y no solo cabecera — que es justo el caso que atrapa la validación de la línea 136.

Y las dos juntas confirman lo más importante: **que el archivo es un CSV y no una página de error guardada con extensión `.csv`**. Un servidor puede devolver `200` con un HTML de "servicio no disponible"; el tamaño en `ls` se vería razonable y el nombre sería correcto. La única forma de descartarlo es mirar el contenido.

## Operación desde `cron`

Un script tiene dos vidas: la de tu terminal, donde tú lo invocas y ves qué pasa, y la de las 3 de la mañana, cuando corre solo. Esta sección es para la segunda.

Pensado para correr desde `cron`. Ejemplo de ejecución diaria a las 3:00, con los logs a `logs/ingesta.log`:

```cron
0 3 * * * /home/mlizz/projects/data-engineering-roadmap/scripts/ingesta.sh "https://raw.githubusercontent.com/datasets/population/main/data/population.csv" "/home/mlizz/projects/data-engineering-roadmap/data/raw" "Country Name,Year,Value" > /dev/null 2>> /home/mlizz/projects/data-engineering-roadmap/logs/ingesta.log
```

> **Las rutas son de ejemplo.** Cámbialas por las tuyas.

Cuatro cosas que hay que saber antes de copiarla:

* **`cron` corre con un `PATH` mínimo y sin tu entorno**, así que **todas** las rutas van absolutas: la del script, la del destino y la del log. Esto le ahorra media hora a quien lo copie.

* **El destino y `logs/` deben existir de antemano.** El script sale con `5` si el directorio destino no existe, y la redirección `2>>` falla si `logs/` no existe. Y el destino **no debe estar en `/tmp`**: ese directorio se borra al reiniciar.

* **`> /dev/null` descarta la ruta y `2>>` acumula los logs.** Si quisieras conservar las rutas descargadas, redirige `stdout` a su propio archivo — el contrato de salida es justo lo que hace posible mandar cada canal a un sitio distinto.

* **La línea no se ejecuta en la terminal.** El `0 3 * * *` del inicio es la programación, no parte del comando; pegarla en el shell da `0: command not found`. Va dentro de `crontab -e`, y se comprueba con `crontab -l`.

### Verificación sin entorno

`env -i` borra todo el entorno, que es lo más parecido a como lo verá `cron`. Si funciona ahí, funciona a las 3 de la mañana:

```text
$ env -i /bin/bash --noprofile --norc -c \
    '/home/mlizz/projects/data-engineering-roadmap/scripts/ingesta.sh \
     "https://raw.githubusercontent.com/datasets/population/main/data/population.csv" \
     "/home/mlizz/projects/data-engineering-roadmap/data/raw" \
     "Country Name,Year,Value"; echo "exit: $?"'
/home/mlizz/projects/data-engineering-roadmap/data/raw/2026-09-01_population.csv
exit: 0
```
