import pandas as pd

archivo_vix = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_vix-daily.csv"
archivo_gdp = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_gdp.csv"

vix = pd.read_csv(archivo_vix, encoding="utf-8-sig")
gdp = pd.read_csv(archivo_gdp, encoding="utf-8-sig")

# PASO 1: Extraer el año en una columna nueva usando df[...]
#dt.year es un atributo de las fechas que devuelve el año como entero
#date ya era date, pero si no lo fuera se puede convertir con pd.to_datetime()
vix['Year'] = pd.to_datetime(vix['DATE']).dt.year

# PASO 2: Resumir el VIX a 1 sola fila por año (obteniendo el promedio anual)
# Si el nombre de la columna con el valor del VIX es VIXCLOSE:
# el reset_index() es para que el resultado sea un DataFrame y no un Series, 
# y poder hacer merge después
vix_anual = vix.groupby('Year')['CLOSE'].mean().reset_index()

# PASO 3: Ahora sí, unir por 'Year'
juntos = pd.merge(gdp, vix_anual, on="Year", how="inner")

# Comprobación de filas
print("Filas GDP original:", len(gdp))
print("Filas VIX anual:", len(vix_anual))
print("Filas Merge final:", len(juntos))

print(juntos.head())