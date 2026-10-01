import sys
import os
import pandas as pd
import argparse  # <-- 1. Importamos la librería argparse


def leer(ruta):
    # Si el archivo no existe en la ruta que le pasaste, falla ordenadamente
    if not os.path.exists(ruta):
        print(f"Error: El archivo {ruta} no existe.", file=sys.stderr)
        sys.exit(5)

    df_csv = pd.read_csv(ruta, encoding="utf-8-sig")
    df_csv.columns = df_csv.columns.str.strip()

    return df_csv


def transformar(df):
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
    # --- PUNTO 2: Configuración de argparse ---
    
    # 2.1 Crear el parser. 'description' se muestra al usar --help
    parser = argparse.ArgumentParser(
        description="Transforma los datos de GDP crudos y genera un resumen por país."
    )

    # 2.2 Agregar el argumento posicional.
    # Al no poner prefijos como '--' o '-', argparse lo trata como obligatorio.
    parser.add_argument(
        "ruta_entrada", 
        help="Ruta del archivo CSV a procesar (ej. data/raw/<fecha>_gdp.csv)"
    )

    # 2.3 Leer los argumentos de la línea de comandos.
    # Aquí ocurre la magia:
    # - Si el usuario pasa '--help', imprime la ayuda y hace un exit(0).
    # - Si el usuario no pasa nada, imprime un error de uso y hace un exit(2).
    args = parser.parse_args()

    ruta_salida = "~/projects/data-engineering-roadmap/data/procesado/resumen_gdp.csv"

    # 2.4 Usar el argumento accediendo como un atributo del objeto 'args'
    df = leer(args.ruta_entrada)
    resumen = transformar(df)
    salida = escribir(resumen, ruta_salida)

    # Contrato del pipeline: imprimir únicamente la ruta de salida
    print(salida)