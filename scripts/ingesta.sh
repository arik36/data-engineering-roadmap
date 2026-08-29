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
#usamos % para quitar la extensión .csv del nombre del archivo, si es que la tiene
archivo_destino="$directorio/${fecha}_${nombre_archivo%.csv}.csv"
# aun no estamos creando el archivo destino, solo estamos definiendo su nombre

# 3.- Preparación de la descarga
# hacemos un archivo destino temporal por si falla la descarga, no se guarda un archivo vacío con el nombre final
# usamos mktemp para crear un archivo temporal, sin argumentos mktemp crea en /tmp

# OJO: mktemp crea a 600 por diseño
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

# 4.- Validación del contenido
# validamos que el archivo temporal cumpla los siguientes criterios:
# 1. No esté vacío
# 2. Que tenga al menos una línean de datos (la primera línea es el cabezal)
# 3. Que contenga el número de columnas que se espera

# -s pregunta si el archivo tiene tamaño mayor a 0, si no tiene tamaño mayor a 0,
# significa que está vacío, por lo que no cumple el criterio 1
# si pasa el if sabemos que tiene almenos una línea.
if [ ! -s "$archivo_temporal" ]; then
    log ERROR "el archivo descargado está vacío"
    exit 3
fi

# para el punto 2 podriamos pensar en usar wc -l, 
# pero si el archivo no tiene saltos de línea, 
# wc -l devuelve 0, por lo que usamos grep para contar las líneas
# usamos -lt 2 porque si el archivo tiene una sola línea en realidad 
# es el cabezal del archivo, por lo que no hay datos
if [ "$(grep -c '^' "$archivo_temporal")" -lt 2 ]; then
    log ERROR "el archivo descargado no tiene líneas"
    exit 3
fi

#punto 3: validamos que las columnas del archivo descargado sean las mismas 
#que las que se esperan
# para esto usamos head -n 1 para obtener la primera línea del archivo temporal
# comparamos que los nombres de las columnas sean los mismos

IFS=',' read -ra pedidas <<< "$columnas"
# comprobamos que cada columna pedida esté en el archivo temporal sin importar el orden

# ahora trabajamos con el cabezal del archivo temporal, quitamos los saltos de línea 
# y retornos de carro, las comas al inicio y al final del cabezal se agregan para 
# que la búsqueda de columnas sea más precisa
cabecera=",$(head -n 1 "$archivo_temporal" | tr -d '\r'),"

# Declaramos una variable vacía antes del bucle, y dentro, 
# en lugar de exit 3, vamos pegando el nombre de la columna que falta.
columnas_faltantes=""
for columna in "${pedidas[@]}"; do
    if [[ "$cabecera" != *,"$columna,"* ]]; then
        columnas_faltantes="$columnas_faltantes, $columna"
    fi
done

if [ -n "$columnas_faltantes" ]; then
    # Quitamos la primera coma y espacio sobrantes usando ${variable#patrón}
    columnas_limpias="${columnas_faltantes#, }"
    log ERROR "las siguientes columnas no se encuentran en el archivo descargado: $columnas_limpias"
    exit 3
fi

# 5. Si todo salió bien, mover el temporal al destino final
# mv aqui hace que el archivo temporal se mueva al destino final, si el archivo destino 
# ya existe, mv lo sobreescribe

# mv conserva los permisos del archivo temporal, por lo que si el archivo temporal es 600, 
# el archivo destino también será 600.
# el chmod va después del mv, no después del mktemp. 
# Si lo ponemos antes, estamos dando permisos a un archivo que quizá se borra sin llegar
# a destino. Igual que la validación: primero verificas, luego expones.

mv "$archivo_temporal" "$archivo_destino"
chmod 644 "$archivo_destino"
echo "$archivo_destino"