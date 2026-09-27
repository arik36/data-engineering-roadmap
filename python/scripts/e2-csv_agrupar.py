import csv
import os

# Este script agrupa los datos de un archivo CSV por la columna "Country Name" y 
# suma los valores de la columna "Value" para cada país.
# Luego, escribe los resultados en un nuevo archivo CSV.

ruta = os.path.expanduser("~/projects/data-engineering-roadmap/data/raw/2026-09-19_gdp.csv")

conteos = {}
with open(ruta, newline="", encoding="utf-8-sig") as f:
    lector = csv.DictReader(f)
    for fila in lector:
        valor_de_value= float(fila["Value"]) # Convertir el value de precio a float
        if valor_de_value is not None:
            valor_de_paises = fila["Country Name"]
            conteos[valor_de_paises] = conteos.get(valor_de_paises, 0) + valor_de_value  # Sumar el valor de precio en lugar de contar
        else:
            print(f"Advertencia: valor de precio nulo en la fila {fila}")
    for categoria_precio, total_precio in sorted(conteos.items(), key=lambda x: -x[1])[:5]:
        print(categoria_precio, total_precio)


#escribir salida en un archivo CSV
salida_ruta = os.path.expanduser("~/projects/data-engineering-roadmap/python/scripts/salidas/e2-csv_agrupar.csv")
with open(salida_ruta, mode="w", newline="", encoding="utf-8-sig") as r:
    escritor = csv.writer(r)
    escritor.writerow(["country_name", "total_value"])
    for categoria_precio, total_precio in sorted(conteos.items(), key=lambda x: -x[1])[:5]:
        escritor.writerow([categoria_precio, total_precio])
    print(f"Archivo de salida generado en: {salida_ruta}")

