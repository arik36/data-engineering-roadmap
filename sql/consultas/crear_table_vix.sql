CREATE TABLE vix 
    (fecha DATE, 
    open NUMERIC, 
    high NUMERIC, 
    low NUMERIC, 
    close NUMERIC);

\copy vix FROM 'data/raw/2026-09-19_vix-daily.csv' WITH (FORMAT csv, HEADER true)

SELECT EXTRACT(YEAR FROM fecha) AS anio, AVG(close), COUNT(*)
FROM vix GROUP BY 1 ORDER BY 1;
