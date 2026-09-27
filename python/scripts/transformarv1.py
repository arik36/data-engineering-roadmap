import sys
import os
import pandas as pd

# --- PUNTO 2: Recibir argumento y validar ---
# Si no le pasas la ruta al ejecutar, falla ordenadamente
if len(sys.argv) < 2:
    print("Error: Debes proporcionar la ruta del archivo CSV a procesar.", file=sys.stderr)
    sys.exit(4)

ruta_entrada = sys.argv[1]

# Si el archivo no existe en la ruta que le pasaste, falla ordenadamente
if not os.path.exists(ruta_entrada):
    print(f"Error: El archivo {ruta_entrada} no existe.", file=sys.stderr)
    sys.exit(5)

# --- PROCESAMIENTO ---
df_csv = pd.read_csv(ruta_entrada, encoding="utf-8-sig")
df_csv.columns = df_csv.columns.str.strip()

df_filtrado = df_csv[df_csv["Value"].notnull()]

# --- PUNTOS 1 y 3: Orden de la tabla que llenaremos en potsgre, nombres correctos y "max" en lugar de "sum" ---
resultado = (
    df_filtrado.groupby("Country Name")
    .agg(anios=("Year", "count"),valor_promedio=("Value", "mean"), valor_max=("Value", "max")) # Corregido: Calculamos el máximo, no la suma
    .reset_index()
    # Renombramos la llave de agrupación al formato de la tabla
    .rename(columns={"Country Name": "country_name"}) 
)

# Forzamos el orden de las columnas para que coincidan 100% con la tabla de Postgres
resultado = resultado[["country_name", "anios", "valor_promedio", "valor_max"]]

# --- GUARDAR ---
ruta_salida = "~/projects/data-engineering-roadmap/data/procesado/resumen_gdp.csv"
ruta_salida_real = os.path.expanduser(ruta_salida)
os.makedirs(os.path.dirname(ruta_salida_real), exist_ok=True)

resultado.to_csv(ruta_salida_real, index=False)

# --- CONTRATO DE PIPELINE ---
# Imprimimos la ruta de salida (stdout) para que el paso 3 sepa dónde leerlo
print(ruta_salida_real)