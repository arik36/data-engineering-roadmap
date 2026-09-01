# Permisos

**Fuente:** práctica propia del 6, 8 y 27 de agosto de 2026 · verificado en terminal
Pendiente desde el 08-06, cuando salió dentro de `ssh.md`.

---

## Modelo mental

Tres dígitos: **dueño · grupo · otros**. Cada uno suma `r`=4, `w`=2, `x`=1.
Los permisos viven en el **inodo**, no en el nombre.

Y aquí está lo que casi nadie dice: **`x` significa cosas distintas según el tipo.**

| Bit | En un archivo | En un directorio |
|---|---|---|
| `r` | leer el contenido | **listar** los nombres que contiene |
| `w` | modificar el contenido | **crear y borrar** entradas |
| `x` | ejecutarlo | **atravesarlo** — entrar, y acceder a un archivo si ya sé el nombre |

Verificado como usuario normal:

```
dir en 700 (rwx):  listar SÍ   leer a.txt SÍ   cd SÍ
dir en 600 (rw-):  listar SÍ   leer a.txt no   cd no
dir en 100 (--x):  listar no   leer a.txt SÍ   cd SÍ
dir en 400 (r--):  listar SÍ   leer a.txt no   cd no
```

**El caso `100` es el que revela el mecanismo:** no puedo ver qué hay dentro, pero **sí puedo
leer `a.txt` si sé cómo se llama**. Y el `400` al revés: veo los nombres y no puedo abrir
ninguno.

Eso explica dos cosas que ya viví: por qué `~/.ssh` necesita **700** y no 600, y por qué un
subdirectorio sin `x` hacía que `find` no pudiera descender.

## Lo que voy a usar

| Comando | Qué hace |
|---|---|
| `chmod 640 f` | fijar permisos en octal |
| `ls -l` | permisos de los archivos de un directorio |
| `ls -ld` | permisos **del directorio mismo** |
| `ls -lL` | sigue el enlace y muestra los del destino |
| `stat -c '%a %n' f` | solo el número, sin el resto |
| `umask` | ver o fijar la máscara de creación |

## Cómo se rompe

### Los tres dígitos son dueño·grupo·otros, no tres permisos del dueño

`640` no es "solo el dueño lee y escribe": **el grupo también lee.**

```
6 4 0
│ │ └── otros: nada
│ └──── grupo: leer
└────── dueño: leer + escribir
```

*(Lo confundí el 08-08.)*

### `640` no tiene bit `x` para nadie

`./script.sh` da *Permission denied*. Para ejecutar hace falta `755` o al menos `700`.

### `umask` se resta a la base, y las bases son distintas

| | Base | umask 022 | Resultado |
|---|---|---|---|
| archivo | 666 | −022 | **644** |
| directorio | 777 | −022 | **755** |

Verificado con tres máscaras:

```
umask 022 → archivo 644   directorio 755
umask 002 → archivo 664   directorio 775
umask 077 → archivo 600   directorio 700
```

La base de los archivos es 666, **no 777**: un archivo nuevo nunca nace ejecutable, por
diseño. Un directorio sí, porque sin `x` no se podría entrar.

### `mktemp` crea en 600 y **ignora el umask**

```bash
$ ( umask 000; t=$(mktemp); stat -c %a "$t" )
600
```

Con `umask 000` un `touch` habría dado 666. `mktemp` fuerza 600 a propósito: el archivo nace
privado desde el primer milisegundo, porque su contenido puede ser sensible mientras se
escribe.

**Consecuencia práctica:** si el archivo final va a ser consumido por otro proceso, hace
falta un `chmod` explícito **después del `mv`**. Es lo que hace `ingesta.sh`.

### `mv` conserva los permisos, pero solo dentro del mismo sistema de archivos

Ahí solo reescribe la entrada del directorio — el inodo no se toca, así que los permisos
viajan intactos. Al cruzar sistemas es **copia + borrado**, y la copia nace con el umask.

Otra razón para el `mktemp --tmpdir="$directorio"`: el temporal vive en el mismo sistema de
archivos que el destino, así que el `mv` es un rename y no una copia.

### Los permisos de un symlink no significan nada

Siempre salen `lrwxrwxrwx` y **Linux los ignora**. `chmod` atraviesa y cambia el destino.

`chmod -h` no existe en Linux —es de BSD— pero **`chown -h` sí**. Detalle completo en
`archivos-y-enlaces.md`.

### ssh rechaza por política propia, no por denegación del kernel

Con `644` y siendo la dueña puedo leer mi clave privada perfectamente. Es `ssh` el que se
niega a usarla.

Y los umbrales son **distintos según el archivo**:

| Archivo | Se rechaza si… |
|---|---|
| clave privada | cualquiera fuera del dueño puede **leerla** |
| `~/.ssh/config` | cualquiera fuera del dueño puede **escribirlo** |

Por eso `644` pasa en el `config` y no en una clave. La lógica está en `ssh.md`: la clave se
protege por confidencialidad, el `config` por integridad.

### Git versiona solo el bit de ejecución

```
100755  ejecutable.sh
100644  normal.sh
```

Nada más. Al clonar, el archivo nace con **mi** `umask` —típicamente 644— y el resto de los
permisos se pierde. Por eso el `chmod` va dentro del instalador, no se confía al repo.

## Pendientes

- [ ] `chmod` simbólico (`u+x`, `g-w`) cuando lo necesite
- [ ] Permisos de directorio compartido en un servidor: cuándo hace falta cambiar el grupo

## Lo que queda fuera a propósito

`setuid`, `setgid`, sticky bit, ACLs, `chown`/`chgrp` más allá de `-h`. Cobertura — llegan
cuando administre un servidor.
