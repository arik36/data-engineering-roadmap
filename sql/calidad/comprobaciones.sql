-- 1. conteo
SELECT COUNT(*) AS filas FROM vix;

-- 2. tasa de nulos por columna
-- contamos todas las filas totales contra las filas que en close tienen valores
--(COUNT(*) - COUNT(close)) columnas close que son nulas 
--Dime qué tanto por ciento de la columna close está corrupto o sin datos
SELECT COUNT(*) - COUNT(close) AS nulos_close,
       ROUND(100.0 * (COUNT(*) - COUNT(close)) / COUNT(*), 2) AS pct_nulos_close
FROM vix;

SELECT COUNT(*) - COUNT(open) AS nulos_open,
       ROUND(100.0 * (COUNT(*) - COUNT(open)) / COUNT(*), 2) AS pct_nulos_open
FROM vix;

-- 3. rango: el VIX histórico nunca ha pasado de ~90 ni bajado de ~8
SELECT COUNT(*) AS fuera_de_rango FROM vix WHERE close < 5 OR close > 100;

--4. obtener limites
SELECT MIN(close), MAX(close), AVG(close) FROM vix;
--datos=> SELECT MIN(close), MAX(close), AVG(close) FROM vix;
--  min    |    max    |         avg
----------+-----------+---------------------
-- 9.140000 | 82.690000 | 19.4257921965940936
--(1 row)