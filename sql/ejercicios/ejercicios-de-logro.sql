
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
