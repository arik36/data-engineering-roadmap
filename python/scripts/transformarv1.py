import sys
import os
import pandas as pd


# --- PUNTO 2: Recibir argumento y validar ---
if len(sys.argv) < 2:
    print(
        "Error: Debes proporcionar la ruta del archivo CSV a procesar.",
        file=sys.stderr
    )
    sys.exit(4)

ruta_entrada = sys.argv[1]


def leer(ruta):
    # Si el archivo no existe en la ruta que le pasaste, falla ordenadamente
    if not os.path.exists(ruta):
        print(f"Error: El archivo {ruta} no existe.", file=sys.stderr)
        sys.exit(5)

    df_csv = pd.read_csv(ruta, encoding="utf-8-sig")
    df_csv.columns = df_csv.columns.str.strip()

    return df_csv


def transformar(df):

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

    resultado = resultado[
        ["country_name", "anios", "valor_promedio", "valor_max"]
    ]

    return resultado


def escribir(df, ruta_salida):
    ruta_salida_real = os.path.expanduser(ruta_salida)
    os.makedirs(os.path.dirname(ruta_salida_real), exist_ok=True)

    df.to_csv(ruta_salida_real, index=False)

    return ruta_salida_real


if __name__ == "__main__":

    ruta_salida = "~/projects/data-engineering-roadmap/data/procesado/resumen_gdp.csv"

    df = leer(ruta_entrada)
    resumen = transformar(df)
    salida = escribir(resumen, ruta_salida)

    # Contrato del pipeline: imprimir únicamente la ruta de salida
    print(salida)