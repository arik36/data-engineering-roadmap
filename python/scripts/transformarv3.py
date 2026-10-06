import sys
import os
import pandas as pd
import argparse

#a diferencia de v2, ahora ademas de recibir el nombre del archivo de entrada, 
# tambien recibe el grupo, tiempo, valor por el cual se va a filtrar el dataframe, 
#y el nombre del archivo de salida

#asi que debemos modificar la forma en que se reciben los argumentos, y 
#agregar validaciones para cada uno de ellos

def error(mensaje, codigo):
    print(f"Error: {mensaje}", file=sys.stderr)
    sys.exit(codigo)


def leer(ruta):
    # Código 3: el archivo no existe, está vacío o no tiene filas de datos
    if not os.path.exists(ruta):
        error(f"El archivo '{ruta}' no existe.", 3)

    if os.path.getsize(ruta) == 0:
        error(f"El archivo '{ruta}' está vacío.", 3)

    try:
        df = pd.read_csv(ruta, encoding="utf-8-sig")
    except pd.errors.EmptyDataError:
        error(f"El archivo '{ruta}' está vacío o es inválido.", 3)

    df.columns = df.columns.str.strip()

    if df.empty:
        error(f"El archivo '{ruta}' solo tiene cabecera, sin filas de datos.", 3)

    return df


def validar_columnas(df, requeridas):
    # Código 4: faltan columnas. Se listan TODAS las que faltan
    faltan = [c for c in requeridas if c not in df.columns]
    if faltan:
        error(
            f"faltan las columnas {faltan}. "
            f"Disponibles: {list(df.columns)}",
            4,
        )


def transformar(df, grupo, tiempo, valor):
    validar_columnas(df, [grupo, tiempo, valor])

    # Código 5: la columna de valor debe ser numérica.
    # No se convierte con to_numeric(errors="coerce"): eso volvería NaN
    # el texto basura y el fallo pasaría en silencio.
    if not pd.api.types.is_numeric_dtype(df[valor]):
        error(
            f"la columna '{valor}' no es numérica (tipo: {df[valor].dtype}). "
            f"Revisa que sea la columna correcta o que no tenga texto mezclado.",
            5,
        )

    df_filtrado = df[df[valor].notnull()]

    # Código 3: si todos los valores son nulos no hay nada que resumir
    if df_filtrado.empty:
        error(f"la columna '{valor}' no tiene ningún valor no nulo.", 3)

    resultado = (
        df_filtrado
        .groupby(grupo)
        .agg(
            n_registros=(tiempo, "count"),
            valor_promedio=(valor, "mean"),
            valor_max=(valor, "max"),
        )
        .reset_index()
        .rename(columns={grupo: "grupo"})
    )

    return resultado[["grupo", "n_registros", "valor_promedio", "valor_max"]]


def escribir(df, ruta_salida):
    ruta_real = os.path.expanduser(ruta_salida)
    carpeta = os.path.dirname(ruta_real)
    if carpeta:  # dirname es "" si la ruta no incluye carpeta
        os.makedirs(carpeta, exist_ok=True)
    df.to_csv(ruta_real, index=False)
    return ruta_real


if __name__ == "__main__":
    epilogo = """
Códigos de salida:
  0    éxito
  2    error de uso (lo pone argparse)
  3    el archivo de entrada no existe, está vacío o no tiene datos utilizables
  4    faltan una o más columnas pedidas
  5    la columna de valor no es numérica
"""

    parser = argparse.ArgumentParser(
        description="Resume un CSV: agrupa por una columna y calcula "
                    "conteo, promedio y máximo de otra.",
        epilog=epilogo,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument("ruta_entrada", help="Ruta del archivo CSV a procesar")
    parser.add_argument("--grupo", required=True,
                        help="Columna por la que agrupar")
    parser.add_argument("--tiempo", required=True,
                        help="Columna cuyos registros se cuentan")
    parser.add_argument("--valor", required=True,
                        help="Columna numérica a resumir")
    parser.add_argument("--salida", required=True,
                        help="Ruta del CSV de salida")
    args = parser.parse_args()

    df = leer(args.ruta_entrada)
    resumen = transformar(df, args.grupo, args.tiempo, args.valor)
    salida = escribir(resumen, args.salida)

    # Contrato del pipeline: imprimir únicamente la ruta de salida
    print(salida)