import csv
import os


# os.path.expanduser traduce el '~' a la ruta completa real (ej. /home/usuario/...)
ruta = os.path.expanduser("~/canastamx-datos/crudo/QQP_2025/03-2025_01.csv")

with open(ruta, newline="", encoding="utf-8-sig") as f:
    #lector = csv.reader(f)
    #cabecera = next(lector)
    #print(cabecera)

    lectorDict = csv.DictReader(f)
    print("Cabecera:", lectorDict.fieldnames)
   
    contador = 0
    productoscaros = []
    for fila in lectorDict:
        contador += 1
        if float(fila['precio'])>= 1500:        
            #crear una lista con los datos de la fila
            productoscaros.append([fila['producto'], fila['precio']])
            
    print("Número de filas:", contador)
    print("Productos caros:")

    for producto in productoscaros:
        print(producto)