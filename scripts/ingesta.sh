#!/usr/bin/env bash
set -euo pipefail

log(){
    local tipo="$1";
    #quitamos el primer argumento para que no se repita en el mensaje
    shift
    printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$tipo" "$*" >&2
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
cat <<EOF
    Uso: $0 <URL> <Directorio destino> <Columnas>

    

    Salida (stdout):
    ruta del archivo escrito
    

    Códigos de salida:
    exit 0 — Exito
    exit 1 — el HTTP no es 200
    exit 2 — la validación de contenido falla
    exit 3 — alguno de los argumentos no fue brindado
    exit 4 — directorio no existe
    exit 5 — el directorio existe pero no hay permisos suficientes
    exit 6 — formato del ultimo argumento es incorrecto

EOF
exit 0
fi

url="${1:-}"
directorio="${2:-}"
columnas="${3:-}"

# Validación de argumentos

if [ -z "$url" ] || [ -z "$directorio" ] || [ -z "$columnas" ]; then
    log ERROR "uso: $0 <URL> <Directorio destino> <Columnas>"
    exit 3
fi
if [ ! -d "$directorio" ]; then
    log ERROR "el directorio $directorio no existe"
    exit 4
fi
if [ ! -r "$directorio" ] || [ ! -w "$directorio" ]; then
    log ERROR "el directorio $directorio no tiene permisos de lectura/escritura"
    exit 5
fi

#para validar el formato de columnas, se espera un string con palabras separados por comas
# no comas al inicio ni al final, y no espacios entre palabras
regex='^[^,]+(,[^,]+)*$'

if  [[ ! "$columnas" =~ $regex ]]; then
    log ERROR "el formato del argumento columnas es incorrecto"
    exit 6
fi
