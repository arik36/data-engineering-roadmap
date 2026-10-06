#!/usr/bin/env bash
set -euo pipefail

#url="${1:-}"

#columnas="${2:-}"

#archivo=$(./scripts/ingesta.sh "$url" data/raw "$columnas")
#resumen=$(python3 python/scripts/transformarv2.py "$archivo")
#psql -d datos -c "\copy resumen FROM '$resumen' WITH (FORMAT csv, HEADER true)"

# ORQUESTADOR DE PIPELINE - FUNCIONES MEJORADAS 03 de octubre 2026
# aqui haremos que transformarv3.py no tenga escrito en script el nombre de las columnas, 

#al ejecutar el script, se le pasará como argumento el nombre de las columnas que se quieren extraer del archivo csv, y el script generará un nuevo archivo csv con solo esas columnas.
# el $# es el número de argumentos que se le pasan al script, y $1, $2, $3, etc.
# -ne significa "no es igual a", por lo que si el número de argumentos no es igual a 5, se imprime un mensaje de uso y se sale con código de error 4.
if [ $# -ne 5 ]; then
    echo "uso: $0 <URL> <col-grupo> <col-tiempo> <col-valor> <tabla>" >&2
    exit 4
fi

#se establecen las variables con los argumentos pasados al script
#esto es para que transformarv3.py pueda recibir los nombres de las 
#columnas como argumentos, y no tener que estar escritos en el script.

# ademas para indicar lo que efectuara cada argumento en el dataframe 
url="$1"; grupo="$2"; tiempo="$3"; valor="$4"; tabla="$5"

#url = desde donde se descargará el archivo csv
#data/raw = donde se guardará el archivo csv descargado
#grupo, tiempo, valor = nombres de las columnas que se quieren extraer del archivo csv
archivo=$(./scripts/ingesta.sh "$url" data/raw "$grupo,$tiempo,$valor")

# las banderas --grupo, --tiempo, --valor, --salida son para que transformarv3.py pueda recibir 
#los nombres de las columnas como argumentos, y no tener que estar escritos en el script, 
#argparse se encarga de parsear los argumentos y asignarlos a las variables correspondientes, 
#y luego se genera un nuevo archivo csv con solo esas columnas, que se guarda en data/procesado con el nombre resumen_${tabla}.csv
resumen=$(python3 python/scripts/transformar.py "$archivo" \
    --grupo "$grupo" --tiempo "$tiempo" --valor "$valor" \
    --salida "data/procesado/resumen_${tabla}.csv")

#$tabla es el nombre de que el usuario quiera poner a la base de datos donde
# se copiarán los datos del archivo csv generado por transformarv3.py
# se usa ON_ERROR_STOP=1 para que si hay un error en la copia, 
#se detenga la ejecución del script y se muestre el error en la consola
psql -d datos -v ON_ERROR_STOP=1 \
    -c "\copy $tabla (grupo, n_registros, valor_promedio, valor_max) FROM '$resumen' WITH (FORMAT csv, HEADER true)"