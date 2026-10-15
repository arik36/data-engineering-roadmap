SELECT country_code, country_name, COUNT(*)
FROM gdp GROUP BY country_code, country_name HAVING COUNT(*) > 1;
--262 lineas con repeticion en la dualidad country name y country code
BEGIN;
WITH DEL_DUPP AS (
    SELECT ctid, 
           ROW_NUMBER() OVER(PARTITION BY country_name, country_code ORDER BY year) AS numb
    FROM gdp
)
DELETE FROM gdp 
WHERE ctid IN (SELECT ctid FROM DEL_DUPP WHERE numb > 1);


SELECT COUNT(*)
FROM gdp GROUP BY country_code, country_name HAVING COUNT(*) > 1;

----0 lineas con repeticion en la dualidad country name y country code
ROLLBACK;