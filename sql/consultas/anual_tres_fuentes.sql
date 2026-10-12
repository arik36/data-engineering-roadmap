--creacion de tabla sea
CREATE TABLE sea_level (
			anio INTEGER,
            csiro NUMERIC,
            lower NUMERIC,
            upper NUMERIC, 
            noaa NUMERIC);

\copy sea_level FROM 'data/raw/2026-09-19_epa-sea-level.csv' WITH (FORMAT csv, HEADER true)

----------
--agrupar por año y de cada año sumar el value para obtener el pib mundial
WITH Proceso_Completo AS(
WITH gdp_anual AS (
    SELECT year AS anio, SUM(value) AS pib_mundial
    FROM gdp GROUP BY year
),
vix_anual AS (
    SELECT EXTRACT(YEAR FROM fecha)::INT AS anio, AVG(close) AS vix_promedio
    FROM vix GROUP BY 1
)
SELECT g.anio, g.pib_mundial, s.csiro AS nivel_mar, v.vix_promedio
FROM gdp_anual g
LEFT JOIN sea_level s ON g.anio = s.anio
LEFT JOIN vix_anual  v ON g.anio = v.anio
ORDER BY g.anio)
--Contar cuantos nulls deja el left join
SELECT COUNT(*) AS Todo_los_Registros, COUNT(nivel_mar) AS Registros_Nivel_Mar_non_Null, COUNT(vix_promedio) AS Registros_VIX_non_Null
FROM Proceso_Completo;

--ejemplo similar el 10/08/2026
WITH resultado_gdp AS (
    SELECT year AS anio, SUM(value) AS year_value
    FROM gdp
    WHERE value IS NOT NULL
    GROUP BY year
), 
resultado_vix AS (
    SELECT EXTRACT(YEAR FROM fecha) AS anio, AVG(close) AS prom_close
    FROM vix
    GROUP BY 1
),
resultado_sea AS (
    SELECT anio, csiro AS nivel_mar
    FROM sea_level
)
SELECT 
    g.anio, 
    g.year_value, 
    s.nivel_mar, 
    v.prom_close
FROM resultado_gdp g
LEFT JOIN resultado_sea s ON g.anio = s.anio
LEFT JOIN resultado_vix v ON g.anio = v.anio
ORDER BY g.anio;

--psql -c "..." --csv > resultado.csv