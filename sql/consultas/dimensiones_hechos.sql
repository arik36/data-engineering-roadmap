
CREATE TABLE dim_pais AS
SELECT DISTINCT country_code, country_name FROM gdp;
--262

CREATE TABLE hechos_gdp AS
SELECT country_code, year, value FROM gdp;
--13979

WITH datos_unidos AS (
    SELECT dim.country_code, dim.country_name, hc.year, hc.value
    FROM dim_pais dim
    INNER JOIN hechos_gdp hc
    ON dim.country_code = hc.country_code
)
SELECT COUNT(*) 
FROM datos_unidos;
--13979