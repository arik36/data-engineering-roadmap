import csv
import os

ruta = os.path.expanduser("~/canastamx-datos/crudo/QQP_2025/03-2025_01.csv")

conteos = {}
with open(ruta, newline="", encoding="utf-8-sig") as f:
    lector = csv.DictReader(f)
    for fila in lector:
        clave = fila["categoria"]  
        conteos[clave] = conteos.get(clave, 0) + 1

for categoria, total in sorted(conteos.items(), key=lambda x: -x[1])[:10]:
    print(categoria, total)