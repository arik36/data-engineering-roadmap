WITH gdp_sin_nulos AS(
    SELECT country_name, country_code, year, value
    FROM gdp
    WHERE value IS NOT NULL
), 
grupos_pais AS(SELECT country_name, country_code, year, value, 
       NTILE(3) OVER (ORDER BY value) AS tramo
       FROM gdp_sin_nulos)
SELECT tramo, COUNT(*) 
FROM grupos_pais
GROUP BY tramo
ORDER BY tramo;