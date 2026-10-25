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


def validar_columnas(df, requeridas, fuente="tabla"):
    # Código 4: faltan columnas. Se listan TODAS las que faltan
    faltan = [c for c in requeridas if c not in df.columns]
    if faltan:
        error(
            f"{fuente}: faltan las columnas {faltan}. "
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


def transformar(vix, gdp, sea):
    validar_columnas(vix, ["DATE", "CLOSE"], "vix")
    validar_columnas(gdp, ["Year", "Value"], "gdp")
    validar_columnas(sea, ["Year", "CSIRO Adjusted Sea Level"], "sea")
    validar_numerica(vix, "CLOSE", "vix")
    validar_numerica(gdp, "Value", "gdp")

    # --- GDP: PIB mundial por año (suma de Value, sin nulos) ---
    gdp_filtrado = gdp[gdp["Value"].notnull()]
    if gdp_filtrado.empty:
        error("gdp: la columna 'Value' no tiene ningún valor no nulo.", 3)

    resultado_gdp = (
        gdp_filtrado
        .groupby("Year")
        .agg(pib_mundial=("Value", "sum"))
        .reset_index()
        .rename(columns={"Year": "anio"})
    )

    # --- VIX: promedio de CLOSE por año (el año sale de DATE) ---
    fechas = pd.to_datetime(vix["DATE"], errors="coerce")
    invalidas = int(fechas.isna().sum())
    if invalidas == len(vix):
        error("vix: la columna 'DATE' no contiene ninguna fecha válida.", 3)
    if invalidas:
        print(f"Aviso: vix: se descartaron {invalidas} filas con fecha inválida.",
              file=sys.stderr)

    resultado_vix = (
        vix
        .assign(anio=fechas.dt.year)  # assign no modifica el df original
        .groupby("anio")
        .agg(vix_promedio=("CLOSE", "mean"))
        .reset_index()
    )

    # --- SEA: nivel del mar por año ---
    sea_filtrado = sea[["Year", "CSIRO Adjusted Sea Level"]].rename(
        columns={
            "Year": "anio",
            "CSIRO Adjusted Sea Level": "nivel_mar",
        }
    )

    # Un renglón por cada año de GDP; si no hay dato en sea o vix, queda NaN
    resultado = pd.merge(resultado_gdp, sea_filtrado, on="anio", how="left")
    resultado = pd.merge(resultado, resultado_vix, on="anio", how="left")

    return resultado[["anio", "pib_mundial", "nivel_mar", "vix_promedio"]]


def escribir(df, ruta_salida):
    ruta_real = os.path.expanduser(ruta_salida)
    carpeta = os.path.dirname(ruta_real)
    if carpeta:  # dirname es "" si la ruta no incluye carpeta
        os.makedirs(carpeta, exist_ok=True)
    df.to_csv(ruta_real, index=False)
    return ruta_real


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Une tres fuentes por año (PIB mundial, nivel del mar y "
                    "promedio del VIX) en un solo CSV.",
        epilog=EPILOGO,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--vix", required=True, help="Ruta del CSV de VIX diario")
    parser.add_argument("--gdp", required=True, help="Ruta del CSV de PIB")
    parser.add_argument("--sea", required=True,
                        help="Ruta del CSV de nivel del mar (EPA)")
    parser.add_argument("--salida", required=True, help="Ruta del CSV de salida")
    args = parser.parse_args(argv)

    vix = leer(args.vix)
    gdp = leer(args.gdp)
    sea = leer(args.sea)

    resultado = transformar(vix, gdp, sea)

    # Diagnósticos: a stderr para no romper el contrato de stdout
    print(f"Todos los registros: {len(resultado)}", file=sys.stderr)
    print(f"Registros nivel mar no nulos: {resultado['nivel_mar'].notna().sum()}",
          file=sys.stderr)
    print(f"Registros VIX no nulos: {resultado['vix_promedio'].notna().sum()}",
          file=sys.stderr)

    salida = escribir(resultado, args.salida)

    # Contrato del pipeline: imprimir únicamente la ruta de salida
    print(salida)


if __name__ == "__main__":
    main()