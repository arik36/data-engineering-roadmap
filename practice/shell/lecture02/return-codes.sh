#!/usr/bin/env bash

if [[ -f "$1" && -r "$1" && -s "$1" ]]; then 
    echo "Probando el archivo $1"

    contador=0

    > exito.txt
    > error.txt

    until ! bash "$1" >> exito.txt 2>> error.txt; do
        contador=$((contador + 1))
    done

    
    cat exito.txt
    cat error.txt

    echo "El script $1 se ejecutó $contador veces con éxito antes de fallar."
    echo "Falló en la ejecución número $((contador + 1))."
else
    echo "El archivo $1 no es un script válido o no se puede leer." >&2
fi