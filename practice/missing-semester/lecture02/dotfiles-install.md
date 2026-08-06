# Lección 2 · `install.sh` con enlaces simbólicos

Fecha: 2026-08-05 · Ejercicio: *Aliases and Dotfiles*, punto 5
Fuente: `missing.csail.mit.edu/2026/command-line-environment/`

> Enunciado: *"Set up a method to install your dotfiles quickly on a new machine.
> This can be as simple as a shell script that calls `ln -s` for each file."*

---

## Fallo 1 · `ln -s` no sobrescribe

```bash
$ ln -s /ruta/al/repo/bashrc ~/.bashrc
ln: failed to create symbolic link '/home/mlizz/.bashrc': File exists
```

No es un estorbo: es protección. Hay que borrar o respaldar el destino antes.

Respaldo previo:

```bash
$ cp ~/.bashrc ~/.bashrc.respaldo
```

---

## Fallo 2 · El bucle no encontró nada

```bash
DOTFILES="$HOME/projects/data-engineering-roadmap/scripts/dotfiles"
for archivo in "$DOTFILES"/*; do
    echo "encontré: $archivo"
done
```

No imprimió ningún dotfile. Diagnóstico:

```bash
$ ls "$DOTFILES"
$ ls -a "$DOTFILES"
.  ..  .bash_aliases  .bashrc
```

**El glob `*` no coincide con nombres que empiezan con punto.** Los archivos se llamaban
`.bashrc` y `.bash_aliases`, así que el bucle corrió sin error y sin hacer nada.

Es lo mismo que en Bandit nivel 3 con `...Hiding-From-You`.

**Solución elegida:** renombrar sin punto en el repo. El script agrega el punto al enlazar.

```bash
$ git mv .bashrc bashrc
$ git mv .bash_aliases bash_aliases
```

Efecto lateral: VS Code dejó de resaltar la sintaxis, porque detecta el lenguaje por el
nombre y no tiene regla para `bashrc` sin punto. Se arregla con `files.associations`.

---

## Fallo 3 · El script se enlazó a sí mismo

```bash
$ bash scripts/dotfiles/install.sh
ln: failed to create symbolic link '/home/mlizz/.bashrc': File exists
ln: failed to create symbolic link '/home/mlizz/.install.sh': File exists
```

El bucle recorre toda la carpeta, e `install.sh` vive ahí. Hay que excluirlo:

```bash
[ "$nombre" = "install.sh" ] && continue
```

Y el primer error muestra la falta de idempotencia: se queja de un enlace que **ya estaba
correcto**. Un instalador tiene que poder correrse dos veces.

---

## Fallo 4 · Ruta relativa en el destino de `ln -s`

Con `DOTFILES="$(dirname "$0")"`, corriendo desde `scripts/dotfiles/`:

```
$0        = install.sh
DOTFILES  = .
comando   = ln -s "./bashrc" "/home/mlizz/.bashrc"
```

```bash
$ ls -l ~/.bashrc
lrwxrwxrwx ... /home/mlizz/.bashrc -> ./bashrc
$ cat ~/.bashrc
cat: /home/mlizz/.bashrc: No such file or directory
```

El enlace existe; su destino no. `ln -s` **guarda el texto tal cual**, y ese texto se
interpreta desde donde vive el enlace (`/home/mlizz`), no desde donde se creó.

Detalle cruel: el error nombra el enlace, no el destino que falta.

### Las cuatro invocaciones probadas

Mismo script, sin cambiarle una letra:

| Shell parada en | Comando | Guardó | ¿Funciona? |
|---|---|---|---|
| raíz del repo | `bash scripts/dotfiles/install.sh` | `scripts/dotfiles/bashrc` | ❌ |
| dentro de dotfiles | `bash install.sh` | `./bashrc` | ❌ |
| **el home** | `bash projects/.../install.sh` | `projects/.../bashrc` | ✅ |
| `/tmp` | `bash /ruta/absoluta/install.sh` | ruta absoluta | ✅ |

El tercero funciona **por coincidencia**: la shell estaba parada en el mismo directorio
donde vive el enlace, así que los dos puntos de referencia coinciden.

---

## El arreglo

```bash
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
```

Traza desde `.../sql`, invocando `bash ./tmp/install.sh`:

```
[1] $0                  = ./tmp/install.sh
[2] dirname "$0"        = ./tmp
[3] cd ./tmp && pwd     = /home/mlizz/.../sql/tmp
[4] DOTFILES_DIR        = /home/mlizz/.../sql/tmp
[5] mi pwd NO cambió    = /home/mlizz/.../sql
[6] ln -s "/home/mlizz/.../sql/tmp/bashrc" "/home/mlizz/.bashrc"
[7] leerlo              -> SOY EL BASHRC REAL
```

Probado desde las cuatro carpetas de la tabla: las cuatro guardaron la misma ruta absoluta.

---

## Fallo 5 · El script alcanzado por un enlace

```bash
$ ln -s ~/projects/.../install.sh ~/bin/instalar
$ bash ~/bin/instalar
```

```
$0             = /home/mlizz/bin/instalar
dirname        = /home/mlizz/bin
DOTFILES_DIR   = /home/mlizz/bin        ← carpeta del enlace, no del script
ln -s "/home/mlizz/bin/bashrc" ...
cat: No such file or directory
```

`$0` guarda el nombre de la invocación, y ese nombre era el enlace.

```bash
$ readlink -f ~/bin/instalar
/home/mlizz/projects/data-engineering-roadmap/scripts/dotfiles/install.sh
```

Arreglo: `"$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"`.
Hoy no hace falta — nadie invoca este script por un enlace.

---

## Script final

```bash
#!/usr/bin/env bash
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

for ruta in "$DOTFILES_DIR"/*; do
    nombre=$(basename "$ruta")
    [ "$nombre" = "install.sh" ] && continue
    destino="$HOME/.$nombre"

    if [ -L "$destino" ]; then
        rm "$destino"
    elif [ -e "$destino" ]; then
        mv "$destino" "$destino.respaldo"
    fi

    ln -s "$ruta" "$destino"
    echo "enlazado: $destino -> $ruta"
done
```

## Prueba destructiva

```bash
$ git status                     # nada sin commitear
$ ls -l ~/.bashrc.respaldo       # el respaldo existe
$ rm ~/.bashrc
$ bash scripts/dotfiles/install.sh
$ ls -l ~/.bashrc ~/.bash_aliases
lrwxrwxrwx ... /home/mlizz/.bash_aliases -> /home/mlizz/projects/.../bash_aliases
lrwxrwxrwx ... /home/mlizz/.bashrc       -> /home/mlizz/projects/.../bashrc
```

Terminal nueva —no `source`— y `ll`, `gs` funcionan.

## Pendientes

- [ ] Alias `ll` y `la` están duplicados en `bashrc` y en `bash_aliases`. Dejar solo los de
      `bash_aliases`
- [ ] Probar la variante con `readlink -f` creando el enlace en `~/bin/`
