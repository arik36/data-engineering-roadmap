import argparse
import json
import sys
import pandas as pd
import requests

epilogo = """
Códigos de salida:
  0    éxito
  1    Fallo la conexión API
  2    No se pudo establecer conexión
  3    La petición excedio el tiempo de espera
"""

parser = argparse.ArgumentParser(
    description=(
        "Script que recibe una fecha y brinda informacion meteoroligica /n"
        " de León GTO en dicho día"
    ),
    epilog=epilogo,
)
parser.add_argument(
    "--Start", help="Fecha de la que se quiere saber el clima", required=True
)
parser.add_argument(
    "--End", help="Fecha final de la que se quiere saber el clima", required=True
)

args = parser.parse_args()

fecha_in = args.Start
fecha_out = args.End


def error(mensaje, codigo):
  print(f"Error: {mensaje}", file=sys.stderr)
  sys.exit(codigo)


# esto es un get los datos que queremos obtener estan en la url
url = f"https://archive-api.open-meteo.com/v1/archive?latitude=21.12&longitude=-101.68&start_date={fecha_in}&end_date={fecha_out}&daily=temperature_2m_max,temperature_2m_min"

try:
  r = requests.get(url, timeout=20)
  r.raise_for_status()  # Opcional pero recomendado para atrapar errores 4xx/5xx

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
      f"Error: No se pudo conectar al servidor. Revisa tu conexión a internet.",
      2,
  )

except requests.exceptions.RequestException as e:
  error(f"Fallo en la conexión con la API: {e}", 1)

# 4. Aplanar los datos (Esto solo se ejecuta si la petición fue exitosa)
datos = json.loads(r.text)
df = pd.DataFrame(datos["daily"])

# Corrección de las comillas en el f-string
print(f"TAMAÑO DEL DATAFRAME: {len(df)}", file=sys.stderr)

# 5. Hacer al dataframe CSV
df.to_csv("clima_leon.csv", index=False, encoding="utf-8")
print("Archivo 'clima_leon.csv' guardado exitosamente.")
