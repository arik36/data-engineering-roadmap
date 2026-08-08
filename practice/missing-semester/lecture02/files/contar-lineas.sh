#!/usr/bin/env bash

#echo "recibi: $1"

#contador=0

#for archivo in "$1"/*.md
#do
    #[ -e "$archivo" ] || continue
    #contador=$((contador + 1))
#done
    #echo "El directorio $1 contiene $contador archivos .md"

#contador=0
#while read -r archivo; do
    #contador=$((contador + 1))
#done < <(find "$1" -type f -name "*.md")
#echo "El directorio $1 contiene $contador archivos .md"

#!/usr/bin/env bash
set -euo pipefail

directorio="${1:-}"

if [ -d "$directorio" ]; then
    contador=0

    while read -r archivo; do
        lineas=$(wc -l < "$archivo")
        contador=$((contador + lineas))
    done < <(find "$directorio" -type f -name "*.md")

    echo "El directorio $directorio contiene $contador líneas en archivos .md"
else
    echo "Error: el directorio no existe" >&2
    exit 1
fi

