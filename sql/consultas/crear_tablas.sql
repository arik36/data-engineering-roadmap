-- DDL --
-- 1. Tabla para el PIB (GDP)
DROP TABLE IF EXISTS gdp;
CREATE TABLE gdp (
    country_name text,
    country_code text,
    year integer,
    value numeric
);

-- 2. Tabla sea_level
DROP TABLE IF EXISTS sea_level;
CREATE TABLE sea_level (
    anio integer,
    csiro numeric,
    lower numeric,
    upper numeric, 
    noaa numeric
);

--3. Tabla vix
DROP TABLE IF EXISTS vix;
CREATE TABLE vix (
    fecha date,
    open numeric,
    high numeric,
    low numeric,
    close numeric
);

-- lo ejecutaremos con: psql -d datos -f sql/consultas/crear_tablas.sql

--ahora haremos un \copy para cada tabla, para cargar los datos desde los archivos CSV.
-- ELT - LOAD --
--psql -d datos -c "\copy gdp FROM 'data/raw/2026-10-11_gdp.csv' WITH (FORMAT csv, HEADER true)"
\copy sea_level FROM 'data/raw/2026-10-11_epa-sea-level.csv' WITH (FORMAT csv, HEADER true)--psql -d datos -c "\copy vix FROM 'data/raw/2026-10-11_vix-daily.csv' WITH (FORMAT csv, HEADER true)"
--psql -d datos -c ""

--  DML --
-- 3. construir la tabla de hechos
--la tabla central que guarda el resultado final de tus métricas 
--(los números, cálculos o "hechos" que quieres analizar) alineadas a un nivel de detalle específico.
--psql -d datos -f sql/consultas/hechos_anual.sql

--scripts de hechos_anual.sql
--DROP TABLE IF EXISTS hechos_anual;

--CREATE TABLE hechos_anual AS
--WITH gdp_anual AS (
    --SELECT year AS anio, SUM(value) AS pib_mundial
    --FROM gdp 
    --GROUP BY year
--),
--vix_anual AS (
    --SELECT EXTRACT(YEAR FROM fecha)::INT AS anio, AVG(close) AS vix_promedio
    --FROM vix 
    --GROUP BY 1
--)
--SELECT 
    --g.anio, 
    --g.pib_mundial, 
    --s.csiro AS nivel_mar, 
    --v.vix_promedio
--FROM gdp_anual g
--LEFT JOIN sea_level s ON g.anio = s.anio
--LEFT JOIN vix_anual v ON g.anio = v.anio
--ORDER BY g.anio;

--SELECT * FROM hechos_anual;

-- 4. verificar
--seguimos el nombre de columnas de potsgreSQL y no desde resumen.csv
--psql -d datos -c "SELECT COUNT(*), COUNT(nivel_mar), COUNT(vix_promedio) FROM hechos_anual;"