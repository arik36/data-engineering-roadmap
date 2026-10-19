import argparse
from datetime import datetime
import json
import pandas as pd
import requests
import sys

epilogo = """
Códigos de salida:
  0    éxito
  1    Fallo la conexión API
  2    No se pudo establecer conexión
  3    La petición excedio el tiempo de espera
"""


parser= argparse.ArgumentParser(
    description=("Script que brinda los datos de daily_units de la tabla Open-meteo," 
    "una fecha de inicio y brinda todos los registros de esa columna hasta la fecha actual"
    ),
    epilog = epilogo,)


parser.add_argument('Fecha_Inicio', help ="Fecha de inicio desde la cual se busca extraer los datos")

args = parser.parse_args()
FechaInicio = args.Fecha_Inicio
FechaActual = datetime.now().strftime("%Y-%m-%d")

def error(mensaje, codigo):
    print(f"Error{mensaje}", file=sys.stderr)
    sys.exit(codigo)

url= f"https://archive-api.open-meteo.com/v1/archive?latitude=21.12&longitude=-101.68&start_date={FechaInicio}&end_date={FechaActual}&daily=temperature_2m_max,temperature_2m_min"

try:
    r = requests.get(url, timeout=20)
    r.raise_for_status()

      # 1. Ver la línea inicial (Estado de la respuesta)
    print(f"--- LÍNEA INICIAL ---")
    print(f"Código: {r.status_code}")
    print(f"Razón: {r.reason}")
    print(f"Estado completo: HTTP/1.1 {r.status_code} {r.reason}\n")

    # 2. Ver las cabeceras (Headers)
    print(f"--- CABECERAS (HEADERS) ---")
    for clave, valor in r.headers.items():
        print(f"{clave}: {valor}")

    print(f"\n--- CUERPO (BODY) ---")
    print(r.text)

    # 3. Instancias de error (Ordenadas de la más específica a la general)
except requests.exceptions.Timeout:
    error(f"Error: La petición excedió el tiempo límite de espera.", 3)

except requests.exceptions.ConnectionError:
  error(
      f"Error: No se pudo conectar al servidor. Revisa tu conexión a internet.",2)

except requests.exceptions.RequestException as e:
  error(f"Fallo en la conexión con la API: {e}", 1)

# 4. Aplanar los datos (Esto solo se ejecuta si la petición fue exitosa)
datos = json.loads(r.text)
df_units = pd.DataFrame(
    list(datos["daily_units"].items()), columns=["Metrica", "Unidad"]
)

# Corrección de las comillas en el f-string
print("\n--- UNIDADES DE LAS MÉTRICAS ---")
print(df_units.to_string(index=False))  # .to_string(index=False) imprime una tabla limpia sin índices numéricos molestos

print(f"\nTAMAÑO DEL DATAFRAME: {len(df_units)}", file=sys.stderr)