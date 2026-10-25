import argparse
import os
import sys

import pandas as pd
import requests

URL_API = "https://archive-api.open-meteo.com/v1/archive"
LATITUD = 21.12      # León, Gto.
LONGITUD = -101.68
TIMEOUT_SEGUNDOS = 20

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


class ErrorPipeline(Exception):

  def __init__(self, mensaje, codigo):
    super().__init__(mensaje)
    self.codigo = codigo


def leer(inicio, fin):
    # Hace el GET a la API y devuelve el JSON ya convertido a dict.
    # Los parámetros van en un dict: requests arma la query string.
    params = {
        "latitude": LATITUD,
        "longitude": LONGITUD,
        "start_date": inicio,
        "end_date": fin,
        "daily": "temperature_2m_max,temperature_2m_min",
    }

    # Orden de los except: de lo más específico a lo más general
    try:
        r = requests.get(URL_API, params=params, timeout=TIMEOUT_SEGUNDOS)
        r.raise_for_status()
    except requests.exceptions.Timeout:
        raise ErrorPipeline("la petición excedió el tiempo límite de espera.", 6)
    except requests.exceptions.ConnectionError:
        raise ErrorPipeline("no se pudo conectar al servidor. Revisa tu conexión a internet.", 6)
    except requests.exceptions.HTTPError as e:
        raise ErrorPipeline(f"la API respondió {e.response.status_code} {e.response.reason}:"
            f"{e.response.text[:200]}", 7)
    except requests.exceptions.RequestException as e:
        raise ErrorPipeline(f"falló la petición a la API: {e}", 6)
    print(f"API respondió: HTTP {r.status_code} {r.reason}", file=sys.stderr)

    # Código 3: respuesta 200 pero el cuerpo no es JSON
    try:
        return r.json()
    except ValueError:
        raise ErrorPipeline("la API respondió, pero el cuerpo no es un JSON válido.", 3)
    


def transformar(datos):
    # Aplana el bloque "daily" de la respuesta en una tabla
    # (una fila por día, una columna por variable).
    if not isinstance(datos, dict) or "daily" not in datos:
        raise ErrorPipeline("la respuesta de la API no trae la clave 'daily'.", 3)

    df = pd.DataFrame(datos["daily"])

    if df.empty:
        raise ErrorPipeline("la API no devolvió ningún día en ese rango de fechas.", 3)
    return df


def escribir(df, ruta_salida):
    ruta_real = os.path.expanduser(ruta_salida)
    carpeta = os.path.dirname(ruta_real)
    if carpeta:  # dirname es "" si la ruta no incluye carpeta
        os.makedirs(carpeta, exist_ok=True)
    df.to_csv(ruta_real, index=False)
    return ruta_real


def main(argv=None):
  parser = argparse.ArgumentParser(
      description=(
          "Descarga las temperaturas máxima y mínima diarias de "
          "León, Gto. en un rango de fechas y las guarda en un CSV."
      ),
      epilog=EPILOGO,
      formatter_class=argparse.RawDescriptionHelpFormatter,
  )
  parser.add_argument(
      "--inicio", required=True, help="Fecha inicial, formato AAAA-MM-DD"
  )
  parser.add_argument(
      "--fin", required=True, help="Fecha final, formato AAAA-MM-DD"
  )
  parser.add_argument(
      "--salida", required=True, help="Ruta del CSV de salida"
  )
  args = parser.parse_args(argv)

  try:
    datos = leer(args.inicio, args.fin)
    df = transformar(datos)
    print(f"Filas descargadas: {len(df)}", file=sys.stderr)
    salida = escribir(df, args.salida)
    print(salida)
  except ErrorPipeline as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(e.codigo)

if __name__ == "__main__":
    main()