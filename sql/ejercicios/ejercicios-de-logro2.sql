
CREATE TABLE tabla_logro
(nombrepais text,
 anios numeric,
 valor numeric,
 max numeric,
 PRIMARY KEY(nombrepais, valor));

\copy tabla_logro FROM 'data/procesado/resumen_gdp.csv' WITH (FORMAT CSV, HEADER);

WITH filas_insertadas AS (
    INSERT INTO tabla_logro (nombrepais, anios, valor, max)
    VALUES ('Genovia', 24, 12453436166.100546, 20023436166.100546),
           ('Gibraltar', 45, 16453436166.100546, 32023436166.100546),
           ('Afghanistan', 23, 13093436166.100546, 20497128555.69723)
    ON CONFLICT (nombrepais, valor) DO NOTHING
    RETURNING 1
)
SELECT COUNT(*) FROM filas_insertadas;