import csv
import os

ruta = os.path.expanduser("~/projects/data-engineering-roadmap/data/raw/2026-09-19_vix-daily.csv")
gruposAgrupados = {}

with open(ruta, newline="", encoding="utf-8-sig") as f:
    lectorDicc = csv.DictReader(f)
    cabecera= lectorDicc.fieldnames
    print("Cabecera:", cabecera)

    for fila in lectorDicc:
        #verificar años de la fecha
        fecha = fila['DATE']
        # Si viene en formato YYYY-MM-DD
        if '-' in fecha:
            año = fecha.split('-')[0]
        # Si viene en formato DD/MM/YYYY
        elif '/' in fecha:
            año = fecha.split('/')[-1]
        else:
            año = fecha[:4]

        # simulacion de group by, agrupamos por año
        if año not in gruposAgrupados:
            gruposAgrupados[año] = []
            gruposAgrupados[año].append(fila)
        else:
            gruposAgrupados[año].append(fila)
    
    #escribimos los grupos en archivos separados
    for año, filas in gruposAgrupados.items():
        nombreArchivo = f"vix-daily_{año}.csv"

        rutasalida= os.path.expanduser(f"/tmp/reto_python/{nombreArchivo}")
        with open(rutasalida, "w", newline="", encoding="utf-8-sig") as f_salida:
            escritor = csv.DictWriter(f_salida, fieldnames=cabecera)

            # se usa writeheader() para escribir la cabecera en el archivo de salida
            escritor.writeheader()
            escritor.writerows(filas)
        
    #imprimir en consola los grupos creados
    for año, filas in gruposAgrupados.items():
        print(f"Año: {año} , Número de filas: {len(filas)}")



