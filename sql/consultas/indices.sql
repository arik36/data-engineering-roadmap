--Prueba 1: EXPLAIN ANALYZE de una consulta
-- que filtre por una columna sin índice.
EXPLAIN ANALYZE SELECT * FROM gdp WHERE value > 50000;

-- Planning Time: 22.963 ms
-- Execution Time: 19.751 ms

--Creamos un indice en value
CREATE INDEX idx_gdp_value ON gdp (value);

-- Planning Time: 5.204 ms
-- Execution Time: 4.621 ms

--Bitmap Heap Scan
EXPLAIN ANALYZE SELECT * FROM gdp WHERE value BETWEEN 3000000000 AND 3010000000;

--Index Scan
EXPLAIN ANALYZE SELECT * FROM gdp WHERE value = 3500000000;