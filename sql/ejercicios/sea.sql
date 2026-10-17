CREATE TEMP TABLE sea_staging (LIKE sea_level INCLUDING DEFAULTS);

\set copiar '\\copy sea_staging FROM ' :'archivo_csv' ' WITH (FORMAT csv, HEADER true)'
:copiar

WITH Insertadas_sea AS (
    INSERT INTO sea_level (anio, csiro, lower, upper, noaa)
    SELECT * FROM sea_staging
    ON CONFLICT (anio) DO NOTHING
    RETURNING 1
)
SELECT COUNT(*) FROM Insertadas_sea;


