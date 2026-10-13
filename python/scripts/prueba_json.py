import json
import pandas as pd

# 1. Creamos un data frame de vix
ruta = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_vix-daily.csv"
df_vix = pd.read_csv(ruta, encoding="utf-8-sig")

# 2. Pasamos el dataframe a JSON y lo guardamos en el disco
df_vix.to_json("vix_salida.json", orient="records", indent=4)

print("¡Guardado exitosamente!")