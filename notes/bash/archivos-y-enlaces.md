# Archivos y enlaces

Fuente: `man ln`, `man readlink` + experimentos propios en `/tmp` · 2026-08-04 y 2026-08-10
Consolida lo que estaba repartido en `enlaces-simbolicos.md` y en `entorno.md` §7–8.

## Modelo mental

Un **inodo** es donde el sistema de archivos guarda todo lo de un archivo *menos su nombre*:
permisos, dueño, tamaño, fechas y dónde están los bloques de datos.

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
De ahí salen las dos formas de enlace:

| | Enlace duro (`ln`) | Simbólico (`ln -s`) |
|---|---|---|
| Qué es | otro nombre para **el mismo inodo** | archivo aparte, con **inodo propio**, cuyo contenido es una ruta en texto |
| Cruza sistemas de archivos | **no** — el inodo solo tiene sentido dentro del suyo | sí, guarda una cadena |
| Puede quedar colgado | no | **sí** |
| Sobrevive si borro el original | sí | no |

La ruta de un symlink se resuelve **en el momento de acceder**, no al crearlo. Por eso puede
apuntar al vacío desde el primer segundo.

Y explica cosas que si no parecen arbitrarias:

```bash
$ mv a.txt b.txt      # inodo 573494 → 573494   solo cambió la entrada del directorio
$ cp b.txt c.txt      # inodo 573494 → 573495   archivo nuevo, datos duplicados
```

`mv` dentro del mismo sistema de archivos es instantáneo aunque el archivo pese 4 GB: no
mueve datos, reescribe una línea de la tabla.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `ln -s objetivo enlace` | crear enlace simbólico |
| `ln -sfn objetivo enlace` | reapuntar un enlace existente que va a un directorio |
| `ln a b` | enlace duro |
| `readlink e` | el texto guardado, un solo salto |
| `readlink -f e` | resuelve la cadena; **permite que el último componente no exista** |
| `readlink -e e` | resuelve la cadena; **exige que todo exista**. Exit 1 si no |
| `ls -li` | listado con número de inodo |
| `stat -c '%i %h' f` | inodo y cuántos nombres lo apuntan |

Opciones de `ln`: `-f` borra lo que ya esté · `-n` no sigue un enlace-a-directorio ·
`-T` trata el destino como archivo aunque sea directorio · `-i` pregunta antes.

Mnemónico: **`-n`** = *No sigas el enlace*. **`-T`** = el *Target* no es un directorio.

Para validar en un instalador, el que sirve es **`readlink -e`**: es el único que verifica
que el enlace *resuelve*, no solo que existe.

## Cómo se rompe

Todos verificados en terminal. El patrón común: **el comando sale con 0 y el resultado está
mal.** Ninguno grita.

### Un destino relativo se resuelve contra la carpeta del enlace

```bash
$ cd /tmp/prueba/dotfiles && echo "contenido real" > bashrc
$ ln -s bashrc /tmp/prueba/enlace
$ readlink /tmp/prueba/enlace
bashrc
$ cat /tmp/prueba/enlace
cat: /tmp/prueba/enlace: No such file or directory
```

El enlace vive en `/tmp/prueba/`, así que `bashrc` se busca ahí — no en el directorio donde
corrí el comando. **En un instalador, el destino va siempre en ruta absoluta.**

Las relativas sirven cuando el enlace y su destino viven juntos y se mueven juntos, dentro
de un mismo repo. Ahí la relación no cambia al copiar la carpeta.

### `ln -s` no verifica el destino, y no adivina extensiones

```bash
$ ln -s ~/borrarluego rutaAejemplo     # el archivo real es borrarluego.txt
$ cat rutaAejemplo
cat: rutaAejemplo: No such file or directory
```

Guardó la ruta sin `.txt`. El enlace se creó igual, roto desde el primer momento, con exit 0.

**Crear un enlace y verificar que su destino existe son dos operaciones distintas.** Es
intencional: permite enlazar a algo que se va a crear después o a un disco sin montar.

### Si el último argumento resuelve a directorio, `ln` crea el enlace ADENTRO

```bash
$ ln -s /tmp/rev/proyecto actual        # actual -> proyecto/
$ ln -s /tmp/rev/otro actual
$ readlink actual
/tmp/rev/proyecto                        ← no cambió
$ ls proyecto/
otro                                     ← se creó aquí adentro
```

**`-f` no tiene nada que ver con esto.** Verificado: `ln -sf` hace exactamente lo mismo que
`ln -s` en este caso — anida igual. La regla es la convención de "último argumento es
directorio", la misma de `cp` y `mv`; y un symlink a directorio cuenta como directorio para
efectos de resolución.

```bash
$ ln -sn /tmp/rev/otro actual
ln: failed to create symbolic link 'actual': File exists
```

`-n` sí impide entrar — y entonces choca con que el nombre ya existe. Por eso:

- **`-n`** dice "no entres, trátalo como archivo normal"
- **`-f`** borra lo que ya estaba ahí

**Hacen falta los dos, por razones distintas. Para reapuntar: `ln -sfn`.**

Y el anidamiento deja basura: el `proyecto/otro` que se creó no lo limpia un `ln -sfn`
posterior.

> Corregido el 2026-08-11: la versión anterior de esta nota atribuía el anidamiento a `-f`.
> Sin `-f` pasa lo mismo.

### `-f` no borra directorios reales, y `-n` tampoco protege de ellos

`-f` solo borra archivos y enlaces. Y un directorio **real** no lo salva ni `-n`:

```bash
$ mkdir realdir
$ ln -sfn /tmp/p/real.txt realdir
$ echo $?
0
$ ls realdir/
real.txt                    ← se creó adentro, otra vez
```

Sale con 0 y anida. `-n` solo evita seguir un **enlace** a directorio; contra un directorio
de verdad no hace nada.

El único que se niega es `-T`:

```bash
$ ln -sfT /tmp/p/real.txt realdir
ln: realdir: cannot overwrite directory
```

Para reemplazar un directorio real hay que borrarlo antes, con `rmdir` o `rm -r`.

### `ln -sfn` destruye el destino aunque el origen no exista

```bash
$ echo "archivo real e importante" > real.txt
$ ln -sfn /tmp/v/NO-EXISTE real.txt
$ echo $?
0
$ cat real.txt
cat: real.txt: No such file or directory
```

El archivo real se perdió y `ln` salió con 0. **`ln` no valida el origen.**

Validar todo antes de modificar nada. Una validación puesta después del respaldo es peor que
no tenerla: deja un respaldo huérfano y ningún enlace.

### Escribir a través de un enlace trunca el ARCHIVO REAL

```bash
$ echo "MIS ALIAS IMPORTANTES" > original.txt
$ ln -s /tmp/v2/original.txt enlace.txt
$ echo "algo nuevo" > enlace.txt
$ cat original.txt
algo nuevo
```

El enlace sigue siendo enlace; lo que se sobrescribió fue el archivo del otro lado. Un `>`
sobre lo que parece "solo un enlace" borra el original en el repo.

### Un enlace colgado se ve normal en `ls`

```bash
$ rm real.txt
$ ls -l enlace.txt
lrwxrwxrwx 1 mlizz mlizz 8 enlace.txt -> real.txt     # ahí sigue
$ cat enlace.txt
cat: enlace.txt: No such file or directory
```

El error dice "no existe" señalando un archivo que `ls` acaba de listar. Lo que no existe es
el destino, pero el mensaje nombra el enlace.

### `[ -e ]` y `[ -L ]` dan respuestas opuestas sobre un enlace roto

```bash
$ [ -e enlace.txt ] && echo sí || echo no
no          # -e sigue el enlace: el destino no existe
$ [ -L enlace.txt ] && echo sí
sí          # -L mira el enlace mismo: ahí está
```

Un instalador necesita los dos: `-L` primero (enlace viejo, se reemplaza), `-e` después
(archivo real, se respalda). Solo con `-e`, un enlace roto sería invisible y `ln -s` fallaría
con "File exists" sobre algo que el script cree que no existe.

### `readlink -f` no detecta enlaces colgados

```bash
$ readlink -f /tmp/v/enlace ; echo $?
/tmp/v/bashrc
0
$ readlink -e /tmp/v/enlace ; echo $?
1
```

`-f` devolvió alegremente una ruta que no existe, con exit 0. `-e` no imprimió nada y salió
con 1. **En un `if`, el que sirve es `-e`.**

Con `-f` sí se resuelve la ubicación de un script (`readlink -f "$0"`), porque ahí el archivo
sí existe y lo que se quiere es seguir la cadena. Ver `scripting.md`.

### Los permisos de un symlink no significan nada

```bash
$ ls -l real.txt enlace.txt
lrwxrwxrwx  enlace.txt -> real.txt
-rw-------  real.txt

$ chmod 644 enlace.txt          # se lo pedí AL ENLACE
$ ls -l real.txt enlace.txt
lrwxrwxrwx  enlace.txt -> real.txt      ← sin cambio
-rw-r--r--  real.txt                    ← cambió este
```

El symlink tiene su propio inodo, y ese inodo tiene bits de permisos — por eso `ls -l`
muestra algo. Pero **el kernel de Linux nunca los consulta**: están ahí, siempre en
`rwxrwxrwx`, y no significan nada. Lo que decide si puedo leer o escribir son los permisos
del destino.

En Linux **no hay forma de cambiarlos**, precisamente porque no se usan:

```bash
$ chmod -h 600 enlace.txt
chmod: invalid option -- 'h'
```

`-h` es de BSD/macOS. Ojo con la asimetría: **`chown -h` sí existe en Linux** —el dueño de un
enlace sí importa en algunos contextos— pero `chmod -h` no.

## El patrón completo: qué atraviesa y qué no

| Atraviesan (actúan sobre el destino) | Actúan sobre el enlace |
|---|---|
| `cat`, editores | `rm` |
| `>`, `>>` | `mv` |
| `chmod`, `chown` | `ln -sfn` |
| `[ -e ]`, `[ -f ]`, `[ -d ]` | `[ -L ]` |
| `readlink -f`, `readlink -e` | `readlink` a secas, `ls -l` |

**La regla que unifica: lo que toca el contenido atraviesa; lo que toca el nombre, no.**

`chmod` parece metadato y por eso confunde, pero los permisos viven en el inodo del destino,
así que va del lado del contenido.

> **Y de ahí sale el patrón general de toda la nota:** casi cada herramienta de enlaces tiene
> una variante que atraviesa y otra que no — `-e` vs `-L`, `readlink -f` vs `-e`, `ln` con
> `-n` y sin él. Elegir la equivocada es el error más común.

### El enlace duro no cruza sistemas de archivos

```bash
$ echo datos > a.txt && ln a.txt b.txt
$ ls -li a.txt b.txt
4707 -rw-r--r-- 2 mlizz mlizz  a.txt
4707 -rw-r--r-- 2 mlizz mlizz  b.txt
$ rm a.txt && cat b.txt
datos
```

Mismo inodo, contador en 2. `rm` quita el nombre, no el inodo — los datos se liberan cuando
el contador llega a cero.

`ln a.txt /mnt/c/b.txt` falla: el número de inodo solo tiene sentido dentro de su propio
sistema de archivos. Un symlink sí cruza, porque guarda una cadena.

## Symlinks vivos en mi sistema

```
lrwxrwxrwx  1 mlizz mlizz  23 .aws   -> /mnt/c/Users/mlizz/.aws/
lrwxrwxrwx  1 mlizz mlizz  25 .azure -> /mnt/c/Users/mlizz/.azure/
```

La `l` inicial de los permisos y la flecha son la firma. Son **dos instaladores distintos**
—AWS CLI crea `~/.aws`, Azure CLI crea `~/.azure`— que resolvieron el mismo problema que mis
dotfiles: la config tiene que estar en una ruta fija del lado de Linux, pero los archivos
reales viven del lado de Windows.

## Pendientes

- [x] ~~`ln -sfT` vs `-sfn`~~ → `-T` es el único que se niega a sobrescribir un directorio real
- [x] ~~Permisos: ¿los del enlace o los del destino?~~ → los del destino; los del enlace no se usan
- [ ] ¿Qué hace mi editor al guardar sobre un symlink: escribe a través, o lo reemplaza por
      un archivo normal? Probar con VS Code antes de confiar
