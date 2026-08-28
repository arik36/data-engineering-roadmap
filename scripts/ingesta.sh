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
    Se debe mencionar la URL de la que se quiere descargar el archivo
    el directorio donde se quiere guardar y las columnas que se quieren 
    extraer del archivo descargado.

    Ten en cuenta que en el directorio que se indique se  van a escribir archivos, 
    de manera predeterminada y con un nombre diferenciador por la fecha exacta de 
    creación, de preferencia no modifique los nombres de este archivo.

    Salida (stdout):
    ruta del archivo escrito
    

    Códigos de salida:
    exit 0 — éxito
    exit 1 — fallo inesperado (set -e). No lo asigno yo
    exit 2 — el HTTP no es 200
    exit 3 — la validación de contenido falla
    exit 4 — falta algún argumento
    exit 5 — el directorio no existe
    exit 6 — el directorio existe pero sin permisos suficientes
    exit 7 — formato del argumento columnas incorrecto
    exit 8 — la URL no es accesible

EOF
exit 0
fi

url="${1:-}"
directorio="${2:-}"
columnas="${3:-}"

#1.- Validación de argumentos

if [ -z "$url" ] || [ -z "$directorio" ] || [ -z "$columnas" ]; then
    log ERROR "uso: $0 <URL> <Directorio destino> <Columnas>"
    exit 4
fi
if [ ! -d "$directorio" ]; then
    log ERROR "el directorio $directorio no existe"
    exit 5
fi
if [ ! -r "$directorio" ] || [ ! -w "$directorio" ]; then
    log ERROR "el directorio $directorio no tiene permisos de lectura/escritura"
    exit 6
fi

# para validar el formato de columnas, se espera un string con palabras separados por comas
# no comas al inicio ni al final, y no espacios entre palabras
regex='^[^,]+(,[^,]+)*$'

if  [[ ! "$columnas" =~ $regex ]]; then
    log ERROR "el formato del argumento columnas es incorrecto"
    exit 7
fi

# 2.- Validación de la URL

#obtenemos el nombre de la URL para usarlo como nombre de archivo
#colocamos fecha con date en lugar de usar un timestamp usamos fecha para que sí se repita
# nombre_archivo-> cut Elimina todo lo que esté después del signo '?' antes de pasarlo a basename
nombre_archivo=$(basename "${url%%\?*}")
fecha=$(date -u +%Y-%m-%d)
archivo_destino="$directorio/${fecha}_${nombre_archivo}.csv"
# aun no estamos creando el archivo destino, solo estamos definiendo su nombre

# 3.- Preparación de la descarga
# hacemos un archivo destino temporal por si falla la descarga, no se guarda un archivo vacío con el nombre final
# usamos mktemp para crear un archivo temporal, sin argumentos mktemp crea en /tmp
archivo_temporal=$(mktemp --tmpdir="$directorio" ingesta.XXXXXX)
# limpiamos el archivo temporal al salir del script, sin importar si fue exitoso o no
trap 'rm -f "$archivo_temporal"' EXIT

#4.- Descarga del archivo
# usaremos un OR para que si falla la descarga, 
# no se rompa el script por set -e y podamos capturar el código HTTP

# recordemos que un curl tiene http_code y un exit status, 
# los http_code no son igual a un exit status  
# un http_code 404 o 500 da un exit status de 0, 
# por lo que al usar un OR, todo lo que este entre llaves se ejecutará si
# el comando falla (no si el http_code es de un error) y
# si no falla, se ejecutará el código que sigue después de las llaves
http_code=$(curl -sS -o "$archivo_temporal" -w "%{http_code}" "$url") || {
    log ERROR "la URL $url no es accesible"
    exit 8
}

if [ "$http_code" -ne 200 ]; then
    log ERROR "la URL $url devolvió un código diferente a 200: $http_code"
    exit 2
fi

# 5. Si todo salió bien, mover el temporal al destino final
mv "$archivo_temporal" "$archivo_destino"
echo "$archivo_destino"