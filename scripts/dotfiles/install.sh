#!/usr/bin/env bash
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

for ruta in "$DOTFILES_DIR"/*; do
    nombre=$(basename "$ruta")
    [ "$nombre" = "install.sh" ] && continue      # no enlazar el script mismo
    destino="$HOME/.$nombre"

    if [ -L "$destino" ]; then
        rm "$destino"                              # enlace viejo: se reemplaza
    elif [ -e "$destino" ]; then
        mv "$destino" "$destino.respaldo"          # archivo real: se respalda
    fi

    ln -s "$ruta" "$destino"
    echo "enlazado: $destino -> $ruta"
done