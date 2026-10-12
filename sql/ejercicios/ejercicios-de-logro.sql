
-- SEMANA 1 .- 14 A 19 SEPT 2026
-- SQL de memoria (20 min). Sobre gdp: los cinco países con mayor valor promedio, 
-- solo entre los que tengan más de 20 años de datos. Tiene GROUP BY, HAVING, 
-- ORDER BY y LIMIT. Si sale de corrido, la semana cerró.

SELECT country_name, AVG(value) AS PromValue
FROM gdp
GROUP BY country_name
HAVING COUNT(DISTINCT (year)) > 20
ORDER BY PromValue DESC
LIMIT 5;


-- SEMANA 3 .- 28 sept A 03 oct 2026
-- a) Usando WITH y ROW_NUMBER: el año de mayor PIB de cada país,
-- mostrando país, año y valor. (Patrón "top N por grupo".)
 WITH registro_max_pais AS (
    SELECT
        country_name,
        year,
        value,
        ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY value DESC) AS rank
    FROM gdp
)
SELECT
    country_name,
    year,
    value
FROM registro_max_pais
WHERE rank = 1;

--b) Cada fila con su valor, el del año anterior, y la diferencia. (LAG.)
WITH past_year AS(
	SELECT
	country_name, 
        year, 
        value,
        CASE
          WHEN LAG(value, 1) OVER( PARTITION BY country_name ORDER BY year ) IS NULL THEN 0
          ELSE LAG(value, 1) OVER( PARTITION BY country_name ORDER BY year ) 
          END AS past_val
        FROM gdp)
SELECT 
     country_name, 
     year, 
     value,
     past_val,
     (value  - past_val) AS diff
     FROM past_year;

--c) Contar cuántos NULL hay en la columna value, de dos formas distintas.
-- Forma 1: Usando COUNT y IS NULL
SELECT COUNT(*) AS null_count
FROM gdp
WHERE value IS NULL;

-- Forma 2: Usando SUM y CASE
SELECT SUM(CASE WHEN value IS NULL THEN 1 ELSE 0 END) AS null_count
FROM gdp;

--forma 3: count sobre columna y restar el total de filas. (No es la más eficiente, pero es otra forma de hacerlo.)
SELECT (COUNT(*) - COUNT(value)) AS null_count
FROM gdp;

-- SEMANA 4 .- 04 oct A 11 oct 2026
--a) Una CTE que calcule el PIB mundial por año y otra el VIX promedio por año, 
--unidas con LEFT JOIN, ordenadas por año.
WITH pib_anual AS (
    SELECT year AS anio, SUM(value) AS pib_mundial
    FROM gdp 
    GROUP BY year
),
vix_anual AS (
    SELECT EXTRACT (YEAR FROM fecha)::INT AS anio, AVG(close) AS vix_promedio   
    FROM vix
    GROUP BY 1
)
SELECT 
    p.anio, 
    p.pib_mundial, 
    v.vix_promedio
FROM pib_anual p
LEFT JOIN vix_anual v ON p.anio = v.anio
ORDER BY p.anio;

--b) El año de mayor PIB mundial, usando ROW_NUMBER.
WITH anios_agrupados AS(
    SELECT year, sum(value) AS total
	FROM gdp
    GROUP BY year
), 
ranking_pib AS(
    SELECT year, total,
    ROW_NUMBER() OVER (ORDER BY total DESC) AS rank
    FROM anios_agrupados
)
SELECT year, total
FROM ranking_pib
WHERE rank = 1;


--c) Un DELETE con BEGIN/ROLLBACK sobre hechos_anual, verificando el conteo antes y después.
--primero contamos todos los registros de la tabla hechos_anual
SELECT COUNT(*) AS total_registros
FROM hechos_anual;
--64

BEGIN;
DELETE FROM hechos_anual
WHERE nivel_mar IS NULL
OR vix_promedio IS NULL;

SELECT COUNT(*) AS total_registros
FROM hechos_anual;
--24

ROLLBACK;
--64


