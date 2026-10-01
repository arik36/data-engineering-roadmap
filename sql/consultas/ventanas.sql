--Cada fila con el promedio de su país al lado, y una columna con la diferencia
WITH promedio_pais AS(
        SELECT country_name, 
        value, 
        AVG(value) OVER (PARTITION BY country_name) AS Average 
        FROM gdp
), promedio_resta AS(
        SELECT country_name,
        (value - Average) AS Diff, 
        Average
	    FROM promedio_pais)

SELECT * FROM promedio_resta;

--Numerar los años de cada país del más alto al más bajo (ROW_NUMBER)

SELECT 
    country_name, 
    country_code, 
    year, 
    value,
    ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY year DESC) AS nume_year
FROM gdp;

--enumerar año y contar total de años
SELECT 
    country_name, 
    year, 
    ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY year DESC) AS numero_de_fila,
    COUNT(year) OVER (PARTITION BY country_name) AS total_years
FROM gdp;

--El año de mayor PIB de cada país — esto necesita una CTE con ROW_NUMBER y luego filtrar por = 1. Es el patrón más útil de todos y se llama "top N por grupo"
WITH añospib_x_pais AS (
    SELECT
        country_name, 
        country_code, 
        year, 
        value,
        ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY value DESC) AS rank_PBI
    FROM gdp
)
SELECT 
    country_name, 
    country_code, 
    year, 
    value
FROM añospib_x_pais
WHERE rank_PBI = 1;
