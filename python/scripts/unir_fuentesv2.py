import pandas as pd

# 1. Leer ÚNICAMENTE el archivo que ya fue procesado y resumido por Postgres
resultado_final = pd.read_csv("~/projects/data-engineering-roadmap/data/procesado/resultado.csv")

# 2. Imprimir los conteos para ver el volumen final
print("Todos los registros:", len(resultado_final))
print(
    "Registros nivel mar no nulos:",
    resultado_final['nivel_mar'].notna().sum()
)
print(
    "Registros VIX no nulos:",
    resultado_final['prom_close'].notna().sum() 
)