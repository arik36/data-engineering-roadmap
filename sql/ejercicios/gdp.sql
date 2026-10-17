CREATE TEMP TABLE gdp_staging (LIKE gdp INCLUDING DEFAULTS);

\set copiar '\\copy gdp_staging FROM ' :'archivo_csv' ' WITH (FORMAT csv, HEADER true)'
:copiar

WITH Insertadas_gdp AS (
    INSERT INTO gdp (country_name, country_code, year, value)
    SELECT * FROM gdp_staging
    ON CONFLICT (country_name, year) DO UPDATE
    SET value = EXCLUDED.value
    WHERE gdp.value IS DISTINCT FROM EXCLUDED.value
    RETURNING 1
)
SELECT COUNT(*) FROM Insertadas_gdp;