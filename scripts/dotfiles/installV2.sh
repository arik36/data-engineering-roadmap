#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

enlazar() {
    local track="$DOTFILES_DIR/$1"
    local link="$2"

    if [ ! -f "$track" ]; then
        echo "ERROR: no existe el origen $track" >&2
        return 1
    fi

#    1.- Ya es tu enlace, apuntando al lugar correcto → no hay nada que hacer
#    2.- Es un enlace, pero a otro lado → se reemplaza
#    3.- Es un archivo real, con contenido → aquí está el peligro
    if [ -L "$link" ]; then
       if [ "$(readlink -e "$link")" = "$track" ]; then
            echo "ya enlazado: $link -> $track"
            return 0
        else
            rm "$link"                              # enlace viejo: se reemplaza
        fi
    elif [ -e "$link" ]; then
        echo "Existe un archivo real en $link"
        #un respaldo con fecha y hora para no perder el archivo
        mv "$link" "$link.respaldo.$(date +%Y%m%d%H%M%S)"          # archivo real: se respalda
    fi

    #crear el directorio padre de link.
    mkdir -p "$(dirname "$link")"
    ln -snf "$track" "$link"

    # Verificar si el enlace se resolvió correctamente
    # el !readlink -e "$link" quiere decir que si el enlace no se puede resolver, entonces hay un error
    if ! readlink -e "$link" >/dev/null; then
        echo "ERROR: el enlace $link no resuelve" >&2
        return 1
    fi

    echo "enlazado: $track -> $link"
}

enlazar bashrc "$HOME/.bashrc"
enlazar bash_aliases "$HOME/.bash_aliases"
enlazar ssh/config "$HOME/.ssh/config"

