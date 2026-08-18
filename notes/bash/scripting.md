# Scripting: rutas y ubicación del script

Fuente: MS 2026 L2 · BashFAQ/028 · práctica de `install.sh` · 2026-08-05

## Modelo mental

Una ruta que **no** empieza con `/` necesita un punto de referencia, y **el punto de
referencia depende de quién la lea**:

| Quién la lee | Le pega adelante |
|---|---|
| un comando que escribo | mi `pwd` |
| un enlace simbólico | la carpeta donde vive el enlace |
| un script | el `pwd` de quien lo invocó |

El bug clásico es que una ruta relativa se **calcula** midiendo desde un punto y se **usa**
midiendo desde otro. Era correcta cuando se calculó y deja de serlo después.

Una ruta absoluta no tiene punto de referencia: arranca en `/` y llega al mismo lugar sin
importar quién la lea.

> La pregunta de siempre: **¿desde dónde se va a medir esta ruta, y quién la va a medir?**

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `dirname RUTA` | devuelve la carpeta |
| `basename RUTA` | devuelve el nombre del archivo |
| `readlink RUTA` | el texto guardado en el enlace, **un solo salto** |
| `readlink -f RUTA` | sigue la cadena completa y devuelve ruta absoluta |
| `pwd` | dónde estoy, **siempre en absoluto** |
| `$0` | el nombre con el que se invocó el script |
| `$BASH_SOURCE` | la ruta del archivo que se está ejecutando |

## Cómo se rompe

### `$0` es el nombre de la invocación, no la ubicación

`$0` guarda literalmente lo que escribí. Si escribí una ruta relativa, `dirname "$0"`
devuelve una ruta relativa.

```bash
$ cd /tmp && ./donde.sh
$0 = ./donde.sh        dirname = .

$ cd / && /tmp/donde.sh
$0 = /tmp/donde.sh     dirname = /tmp
```

### Una ruta relativa guardada en un enlace se resuelve desde otro lado

```bash
$ ln -s "./bashrc" ~/.bashrc      # el enlace vive en /home/mlizz
$ cat ~/.bashrc
cat: /home/mlizz/.bashrc: No such file or directory
```

`ln -s` guarda el destino **como texto**, sin verificarlo ni convertirlo. `./bashrc` se
resuelve desde `/home/mlizz`, no desde donde corrí el comando.

**En un instalador, el destino de `ln -s` va siempre en ruta absoluta.**

Las relativas sirven cuando el enlace y su destino viven juntos y se mueven juntos —dentro
de un mismo repo, por ejemplo—. Ahí la relación no cambia al copiar la carpeta.

### El arreglo: `cd` + `pwd`

```bash
DIR="$(cd "$(dirname "$0")" && pwd)"
```

- `pwd` **no tiene versión relativa**: ése es todo el truco
- resuelve la ruta *mientras* el punto de referencia todavía es el correcto
- corre en una subshell `$( )`, así que **no cambia mi directorio actual**
- el `&&` evita imprimir una ruta falsa si el `cd` falla

### Si el script se alcanza por un enlace, `$0` apunta al enlace

Pasa cuando pongo el script en el `PATH`:

```bash
$ ln -s ~/repo/scripts/install.sh ~/bin/instalar
$ bash ~/bin/instalar
$0 = /home/mlizz/bin/instalar
dirname = /home/mlizz/bin      ← carpeta del enlace, no del script
```

`dirname` y `pwd` hicieron su trabajo bien. El problema es que `$0` traía el enlace.

```bash
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
```

`readlink -f` resuelve la cadena antes de que `dirname` la toque.
**Ojo:** `readlink` a secas da un solo salto y puede devolver ruta relativa. Hace falta `-f`.

### `readlink -f` no es portable

Es de GNU. En macOS el `readlink` nativo se comporta distinto. Por eso BashFAQ/028 propone
un bucle manual en vez de una línea, y por eso dice que en el caso general el problema no
tiene solución limpia. Su primer consejo es **no depender de la ubicación del script**.

### Con `source`, `$0` no sirve — usar `$BASH_SOURCE`

```bash
$ bash prueba.sh
$0 = prueba.sh          $BASH_SOURCE = prueba.sh

$ source prueba.sh
$0 = bash               $BASH_SOURCE = prueba.sh
```

`source` ejecuta en la shell actual, así que `$0` sigue siendo el de la shell.
`$BASH_SOURCE` sí trae la ruta del archivo en los dos casos — por eso BashFAQ/028 la
prefiere sobre `$0` en bash.

### `[ -e ]` miente sobre los enlaces rotos

```bash
$ ls -l roto
lrwxrwxrwx ... roto -> ./no-existe
$ [ -e roto ] && echo si || echo no
no
$ [ -L roto ] && echo si || echo no
si
```

`-e` **sigue el enlace** y responde por el destino. Sobre un enlace roto dice que no existe,
aunque el enlace esté ahí. `-L` pregunta si el archivo es un enlace, sin seguirlo.

Un instalador necesita los dos: `-L` primero (enlace viejo, se reemplaza), `-e` después
(archivo real, se respalda). Solo con `-e`, un enlace roto sería invisible y `ln -s` fallaría
con "File exists" sobre un archivo que el script cree que no existe.

### Un script sin manejo de errores falla a la mitad

Al chocar con un "File exists", el bucle dejó un enlace hecho y el otro no. Estado
inconsistente. Un instalador debería hacer todo o nada.


## Lo que creí y estaba mal

- Creí que el problema era que `dirname` tomaba la ruta del script en vez de la
  de la shell. Es al revés: `dirname "$0"` mide desde el `pwd` de la shell, y
  ahí la ruta era **correcta**. Se rompe después, cuando el enlace la vuelve a
  medir desde su propia carpeta.

- Creí que fallaba solo cuando el nombre no llevaba carpetas (`./bashrc`). Falla
  igual con carpetas (`./tmp/bashrc`). Lo único que decide es si empieza con `/`.

- Creí que la condición para que funcionara era que la carpeta de dotfiles fuera
  el home. La condición real es que **la shell esté parada en el home**, porque
  ahí coinciden los dos puntos de referencia.

- Creí que `readlink` a secas devolvía el archivo real. Da un solo salto y puede
  devolver ruta relativa. Hace falta `-f`.

## Pendientes

- [X] `set -euo pipefail` — viernes de esta semana
- [ ] La variante portable de BashFAQ/028 con bucle, para cuando importe macOS
