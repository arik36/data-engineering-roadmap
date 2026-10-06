
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


-- SEMANA 3 .- 38 sept A 03 oct 2026
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
