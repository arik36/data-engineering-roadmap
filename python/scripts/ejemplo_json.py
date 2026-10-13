
import json
import pandas as pd

# Leemos el archivo JSON desde el disco
with open("python/scripts/vix_salida.json", "r", encoding="utf-8") as f:
    contenido = json.load(f)

# Extraemos solo dos filas paralelas
#dates = contenido["DATE"]
#closes = contenido ["CLOSE"]
#filas = list(zip (dates, closes))

#  Convertimos esas filas en un DataFrame de Pandas asignando nombres a las columnas
#df = pd.DataFrame(filas, columns=["DATE", "CLOSE"])
df = pd.DataFrame(contenido)

# Verificamos el resultado
print("\nDataFrame resultante:")
print(df)
print("\nForma del DataFrame (shape):", df.shape)