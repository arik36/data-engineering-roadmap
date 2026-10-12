#un script con argparse que reciba dos rutas de CSV, 
#las una por una columna que se le pase como argumento, 
#e imprima cuántas filas quedaron. Con try/except y códigos de salida.
import argparse
import pandas as pd
import sys

# 1. Configurar argparse
parser = argparse.ArgumentParser(description="Unir dos archivos CSV por una columna común")
parser.add_argument("archivo1", type=str, help="Ruta al primer archivo CSV")
parser.add_argument("archivo2", type=str, help="Ruta al segundo archivo CSV")
parser.add_argument("columna", type=str, help="Nombre de la columna para hacer el merge")

args = parser.parse_args()

# 2. Intentar cargar los archivos
try:
    df1 = pd.read_csv(args.archivo1)
    df2 = pd.read_csv(args.archivo2)
except FileNotFoundError as e:
    print(f"Error de archivo: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error al leer los CSV: {e}")
    sys.exit(1)

# 3. Validar que la columna exista en ambos DataFrames
try:
    if args.columna not in df1.columns or args.columna not in df2.columns:
        raise ValueError(f"La columna '{args.columna}' no existe en uno de los archivos CSV.")
except ValueError as e:
    print(f"Error de validación: {e}")
    sys.exit(2)

# 4. Hacer el merge protegido con try-except (donde realmente puede fallar)
try:
    # CORREGIDO: on=args.columna sin comillas para usar el valor de la variable
    juntos = pd.merge(df1, df2, on=args.columna, how="left")
    
    print(f"¡Merge exitoso!")
    print(f"Filas en el resultado final: {len(juntos)}")
    
except Exception as e:
    print(f"Error durante el cruce de datos (merge): {e}")
    sys.exit(3)