import sys
import os
import pandas as pd
import argparse

def leer(ruta):
    # Código 3: El archivo no existe o está vacío
    if not os.path.exists(ruta):
        print(f"Error: El archivo '{ruta}' no existe.", file=sys.stderr)
        sys.exit(3)
        
    if os.path.getsize(ruta) == 0:
        print(f"Error: El archivo '{ruta}' está vacío.", file=sys.stderr)
        sys.exit(3)

    try:
        df_csv = pd.read_csv(ruta, encoding="utf-8-sig")
    except pd.errors.EmptyDataError:
        print(f"Error: El archivo '{ruta}' está vacío o es inválido.", file=sys.stderr)
        sys.exit(3)
        
    df_csv.columns = df_csv.columns.str.strip()
    return df_csv

def transformar(df):
    # Código 4: Falta una columna esperada
    columnas_esperadas = ["Value", "Country Name", "Year"]
    for col in columnas_esperadas:
        if col not in df.columns:
            print(f"Error: Falta la columna esperada '{col}' en el CSV.", file=sys.stderr)
            sys.exit(4)

    df_filtrado = df[df["Value"].notnull()]

    resultado = (
        df_filtrado
        .groupby("Country Name")
        .agg(
            anios=("Year", "count"),
            valor_promedio=("Value", "mean"),
            valor_max=("Value", "max")
        )
        .reset_index()
        .rename(columns={"Country Name": "country_name"})
    )

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
    # Tabla de códigos de salida documentada en el epilog
    epilogo = """
Códigos de salida:
  0    éxito
  2    error de uso (lo pone argparse)
  3    el archivo de entrada no existe o está vacío
  4    falta una columna esperada
"""

    parser = argparse.ArgumentParser(
        description="Procesa y resume un archivo CSV de GDP.",
        epilog=epilogo,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument("ruta_entrada", help="Ruta del archivo CSV a procesar")
    args = parser.parse_args()

    ruta_salida = "~/projects/data-engineering-roadmap/data/procesado/resumen_gdp.csv"

    df = leer(args.ruta_entrada)
    resumen = transformar(df)
    salida = escribir(resumen, ruta_salida)

    # Contrato del pipeline: imprimir únicamente la ruta de salida
    print(salida)