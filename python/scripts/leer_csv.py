import csv
ruta = "/tmp/capstone/04-2025_01.csv"
with open(ruta, newline="", encoding="utf-8-sig") as f:
    lector = csv.reader(f)
    cabecera = next(lector)
    #imprimir la cabecera
    print(cabecera)
    contador = 0
    for fila in lector:
        contador += 1
    #imprimir el número de filas
    print("Número de filas:", contador)