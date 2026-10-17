#!/usr/bin/env bash
set -euo pipefail

log(){
    local tipo="$1";
    shift
    printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$tipo" "$*" >&2
}
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
#aqui ${1:-} es el primer argumento pasado al script, y si no se pasa ningún argumento, se asigna un valor por defecto de cadena vacía.
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
cat <<EOF
    Uso: $0
    Orquesta la ingesta de las 3 fuentes (GDP, Sea Level, VIX), 
    las carga en PostgreSQL aplicando idempotencia y genera la tabla de hechos anual.

    Salida:
    Actualiza la base de datos 'datos' y la tabla 'hechos_anual'.
EOF
#hacemos exit 0 para que el script termine correctamente, y no con un error, ya que el usuario pidió ayuda y no es un error.
exit 0
fi

log INFO "Iniciando pipeline de datos..."

# 1. Definir las fuentes centralizadas arriba
# Formato: URL | Columnas esperadas | Nombre de tabla SQL
URL_GDP="https://raw.githubusercontent.com/datasets/gdp/master/data/gdp.csv"
COLS_GDP="Country Name,Country Code,Year,Value"
TABLA_GDP="gdp"

URL_SEA="https://raw.githubusercontent.com/datasets/sea-level-rise/master/data/epa-sea-level.csv"
COLS_SEA="Year,CSIRO Adjusted Sea Level,Lower Error Bound,Upper Error Bound,NOAA Adjusted Sea Level"
TABLA_SEA="sea_level"

URL_VIX="https://raw.githubusercontent.com/datasets/finance-vix/master/data/vix-daily.csv"
COLS_VIX="DATE,OPEN,HIGH,LOW,CLOSE"
TABLA_VIX="vix"

#2. Ingestar y transformar cada fuente
log INFO "Procesando GDP..."
ingesta_gdp=$("$RAIZ/scripts/ingesta.sh" "$URL_GDP" "$RAIZ/data/raw" "$COLS_GDP")


log INFO "Procesando Sea Level..."
ingesta_sea=$("$RAIZ/scripts/ingesta.sh" "$URL_SEA" "$RAIZ/data/raw" "$COLS_SEA")

log INFO "Procesando VIX..."
ingesta_vix=$("$RAIZ/scripts/ingesta.sh" "$URL_VIX" "$RAIZ/data/raw" "$COLS_VIX")

# 3. Limpiar 
# Adiós al TRUNCATE: Las tablas de producción ya no se vacían
# ahora deben retener su información histórica y acumular únicamente los registros nuevos o actualizados.
log INFO "Cargando $TABLA_GDP en la base de datos..."

filas_cambiadas_gdp=$(psql -d datos -v ON_ERROR_STOP=1 -v archivo_csv="$ingesta_gdp" -t -A -f "$RAIZ/sql/ejercicios/gdp.sql")
log INFO "Filas insertadas/actualizadas en GDP: $filas_cambiadas_gdp"

log INFO "Cargando $TABLA_SEA en la base de datos..."

filas_cambiadas_sea=$(psql -d datos -v ON_ERROR_STOP=1 -v archivo_csv="$ingesta_sea" -t -A -f "$RAIZ/sql/ejercicios/sea.sql")
log INFO "Filas insertadas/actualizadas en SEA: $filas_cambiadas_sea"

log INFO "Cargando $TABLA_VIX en la base de datos..."

filas_cambiadas_vix=$(psql -d datos -v ON_ERROR_STOP=1 -v archivo_csv="$ingesta_vix" -t -A -f "$RAIZ/sql/ejercicios/vix.sql")
log INFO "Filas insertadas/actualizadas en VIX: $filas_cambiadas_vix"

# 4. Generar la tabla de hechos final (Transformación)
log INFO "Generando tabla de hechos anual..."
psql -d datos -v ON_ERROR_STOP=1 -f sql/consultas/hechos_anual.sql

log INFO "¡Pipeline ejecutado exitosamente de punta a punta!"