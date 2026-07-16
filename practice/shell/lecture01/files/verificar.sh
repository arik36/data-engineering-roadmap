#!/bin/bash

if [ -f "$1" ]; then
    echo "El archivo existe."
else
    echo "El archivo no existe."
fi