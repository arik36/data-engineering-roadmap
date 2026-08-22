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

log() {
    local nivel="$1"; shift
    printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$nivel" "$*" >&2
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
cat <<EOF 
Uso: $0 <directorio>

Cuenta el número total de líneas de todos los archivos .md dentro de un directorio.

Salida (stdout):
Devuelve únicamente un número entero que representa el total de líneas contadas.

Códigos de salida:
0 - Éxito
1 - Error de uso (falta el directorio)
2 - El directorio especificado no existe
3 - Error al intentar leer el directorio
EOF
exit 0
fi

directorio="${1:-}"

if [ -z "$directorio" ]; then
    log ERROR "uso: $0 <directorio>"
    exit 1
fi

if [ -d "$directorio" ]; then
    contador=0
    log INFO "iniciamos el conteo de líneas en archivos .md en el directorio $directorio"

    salida=$(find "$directorio" -type f -name "*.md") \
    || { log ERROR "no se pudo leer $directorio"; exit 3; }

    if [ -z "$salida" ]; then
        log INFO "no se encontraron archivos .md en $directorio"
        #aun si no hay archivos, el conteo se regresa como 0, no es un error
        echo "0" 
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
    exit 2
fi

