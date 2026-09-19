import csv
import os

ruta = os.path.expanduser("~/canastamx-datos/crudo/QQP_2025/03-2025_01.csv")

conteos = {}
with open(ruta, newline="", encoding="utf-8-sig") as f:
    lector = csv.DictReader(f)
    for fila in lector:
        valor_de_precio= float(fila["precio"]) # Convertir el valor de precio a float
        if valor_de_precio is not None:
            valor_de_catalogo = fila["catalogo"]
            conteos[valor_de_catalogo] = conteos.get(valor_de_catalogo, 0) + valor_de_precio  # Sumar el valor de precio en lugar de contar
        else:
            print(f"Advertencia: valor de precio nulo en la fila {fila}")
    for categoria_precio, total_precio in sorted(conteos.items(), key=lambda x: -x[1])[:10]:
        print(categoria_precio, total_precio)


#escribir salida en un archivo CSV
salida_ruta = os.path.expanduser("~/projects/data-engineering-roadmap/python/scripts/salidas/suma.csv")
with open(salida_ruta, mode="w", newline="", encoding="utf-8-sig") as r:
    escritor = csv.writer(r)
    escritor.writerow(["categoria_precio", "total_precio"])
    for categoria_precio, total_precio in sorted(conteos.items(), key=lambda x: -x[1])[:10]:
        escritor.writerow([categoria_precio, total_precio])
    print(f"Archivo de salida generado en: {salida_ruta}")

