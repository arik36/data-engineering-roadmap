import argparse
import os
import sys
 
import pandas as pd

EPILOGO = """
Salida estándar: únicamente la ruta del CSV generado.
Diagnósticos y errores van a stderr.
 
Códigos de salida (cada script usa solo los que le aplican;
el significado de cada número es el mismo en los tres):
  0    éxito
  2    error de uso (lo pone argparse)
  3    entrada inexistente, vacía o sin datos utilizables
  4    faltan una o más columnas requeridas
  5    la columna de valor no es numérica
  6    sin conexión con la API o tiempo de espera agotado
  7    la API respondió con un error HTTP
"""

def error(mensaje, codigo):
    print(f"Error: {mensaje}", file=sys.stderr)
    sys.exit(codigo)

# Verificar si las columnas que pide el usuario son todas las del que el dataframe contiene
def validar_columnas(df, requeridas):
    # Código 4: faltan columnas. Se listan TODAS las que faltan
    faltan = [c for c in requeridas if c not in df.columns]
    if faltan:
        error(
            f"faltan las columnas {faltan}. "
            f"Disponibles: {list(df.columns)}",
            4,
        )

def validar_numerica(df, columna, fuente="tabla"):
    # Código 5: la columna debe ser numérica.
    # No se convierte con to_numeric(errors="coerce"): eso volvería NaN
    # el texto basura y el fallo pasaría en silencio.
    if not pd.api.types.is_numeric_dtype(df[columna]):
        error(
            f"{fuente}: la columna '{columna}' no es numérica "
            f"(tipo: {df[columna].dtype}). Revisa que sea la columna "
            f"correcta o que no tenga texto mezclado.",
            5,
        )
        
def leer(ruta):
    # Código 3: el archivo no existe, está vacío o no tiene filas de datos
    ruta = os.path.expanduser(ruta)
 
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
 
 
def transformar(df, grupo, tiempo, valor):
    validar_columnas(df, [grupo, tiempo, valor])
    validar_numerica(df, valor)
 
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
 
 
def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Resume un CSV: agrupa por una columna y calcula "
                    "conteo, promedio y máximo de otra.",
        epilog=EPILOGO,
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
    args = parser.parse_args(argv)
 
    df = leer(args.ruta_entrada)
    resumen = transformar(df, args.grupo, args.tiempo, args.valor)
    salida = escribir(resumen, args.salida)
 
    # Contrato del pipeline: imprimir únicamente la ruta de salida
    print(salida)
 
 
if __name__ == "__main__":
    main()