BEGIN;

CREATE TEMP TABLE vix_staging (LIKE vix INCLUDING DEFAULTS);

\copy vix_staging FROM 'data/raw/2026-10-11_vix-daily.csv' WITH (FORMAT csv, HEADER true);

WITH Insertadas_vix AS(
    INSERT INTO vix (SELECT * FROM vix_staging)
    ON CONFLICT (fecha) DO NOTHING
    RETURNING 1
)
SELECT COUNT(*) FROM Insertadas_vix;

CREATE TEMP TABLE gdp_staging (LIKE gdp INCLUDING DEFAULTS);

\copy gdp_staging FROM 'data/raw/2026-10-11_gdp.csv' WITH (FORMAT csv, HEADER true);

WITH Insertadas_gdp AS (
    INSERT INTO gdp (SELECT * FROM gdp_staging)
    ON CONFLICT (country_name, year) DO UPDATE
    SET value=EXCLUDED.value
    WHERE gdp.value IS DISTINCT FROM EXCLUDED.value
    RETURNING 1
)
SELECT COUNT(*) FROM Insertadas_gdp;

CREATE TEMP TABLE sea_staging (LIKE sea_level INCLUDING DEFAULTS);

\copy sea_staging FROM 'data/raw/2026-10-11_epa-sea-level.csv' WITH (FORMAT csv, HEADER true);

WITH Insertadas_sea AS (
    INSERT INTO sea_level (SELECT * FROM sea_staging)
    ON CONFLICT (anio) DO NOTHING
    RETURNING 1
)
SELECT COUNT(*) FROM Insertadas_sea;

ROLLBACK;