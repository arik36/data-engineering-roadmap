CREATE TEMP TABLE vix_staging (LIKE vix INCLUDING DEFAULTS);

\set copiar '\\copy vix_staging FROM ' :'archivo_csv' ' WITH (FORMAT csv, HEADER true)'
:copiar

WITH Insertadas_vix AS (
    INSERT INTO vix (fecha, open, high, low, close)
    SELECT * FROM vix_staging
    ON CONFLICT (fecha) DO NOTHING
    RETURNING 1
)
SELECT COUNT(*) FROM Insertadas_vix;

