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
set -x
PS4='TRACE: '

trap 'echo "falló en línea $LINENO: $BASH_COMMAND" >&2' ERR

log() {
    local nivel="$1"; shift
    printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nivel" "$*" >&2
}

directorio="${1:-}"

if [ -z "$directorio" ]; then
    log ERROR "uso: $0 <directorio>"
    exit 1
fi

if [ -d "$directorio" ]; then
    contador=0
    log INFO "iniciamos el conteo de líneas en archivos .md en el directorio $directorio"

    salida=$(find "$directorio" -type f -name "*.md") \
    || { log ERROR "no se pudo leer $directorio"; exit 2; }

    if [ -z "$salida" ]; then
        log INFO "no se encontraron archivos .md en $directorio"
        exit 0
    fi
    mapfile -t archivos <<< "$salida"   

    for archivo in "${archivos[@]}"; do
        lineas=$(wc -l < "$archivo")
        contador=$((contador + lineas))
    done

    echo "$contador"
    log INFO "conteo terminado: $contador líneas en $directorio"
else
    #echo "Error: el directorio no existe" >&2
    log ERROR "el directorio $directorio no existe"
    false
fi

