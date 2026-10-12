DROP TABLE IF EXISTS hechos_anual;

CREATE TABLE hechos_anual AS
WITH gdp_anual AS (
    SELECT year AS anio, SUM(value) AS pib_mundial
    FROM gdp 
    GROUP BY year
),
vix_anual AS (
    SELECT EXTRACT(YEAR FROM fecha)::INT AS anio, AVG(close) AS vix_promedio
    FROM vix 
    GROUP BY 1
)
SELECT 
    g.anio, 
    g.pib_mundial, 
    s.csiro AS nivel_mar, 
    v.vix_promedio
FROM gdp_anual g
LEFT JOIN sea_level s ON g.anio = s.anio
LEFT JOIN vix_anual v ON g.anio = v.anio
ORDER BY g.anio;

SELECT * FROM hechos_anual;