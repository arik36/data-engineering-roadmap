--Ejercicio 1: un filtro sin índice
EXPLAIN ANALYZE SELECT * FROM vix WHERE close > 30;

-------------------------------------------------------------------------------------------------------
-- Seq Scan on vix  (cost=0.00..184.98 rows=736 width=28) (actual time=1.304..17.029 rows=735 loops=1)
  -- Filter: (close > '30'::numeric)
   --Rows Removed by Filter: 8543
 --Planning Time: 19.262 ms
 --Execution Time: 17.739 ms
 --------------------------------------------------------------------------

 --Ejercicio 2: cuándo gana el índice
EXPLAIN SELECT * FROM vix WHERE fecha = '2020-03-16';
EXPLAIN SELECT * FROM vix WHERE fecha BETWEEN '2020-03-01' AND '2020-03-31';
EXPLAIN SELECT * FROM vix WHERE fecha >= '2020-01-01';
EXPLAIN SELECT * FROM vix WHERE fecha >= '2000-01-01';

SELECT attname, correlation FROM pg_stats
WHERE tablename = 'vix' AND attname = 'fecha';

--Ejercicio 3: 
-- a) orden implícito (por la llave primaria)
EXPLAIN ANALYZE SELECT * FROM gdp ORDER BY country_name, year LIMIT 20;
-- b) Sort completo
EXPLAIN ANALYZE SELECT * FROM gdp ORDER BY value DESC;
-- c) el mismo Sort, pero con LIMIT
EXPLAIN ANALYZE SELECT * FROM gdp ORDER BY value DESC 
LIMIT 10;
-- d) Incremental Sort (prefijo country_name ya ordenado)
EXPLAIN ANALYZE SELECT * FROM gdp ORDER BY country_name, value LIMIT 20;
-- e) Sort que se va a disco
SET work_mem = '64kB';
EXPLAIN ANALYZE SELECT * FROM gdp ORDER BY value DESC;
RESET work_mem;

----Ejercicio 4:
EXPLAIN ANALYZE
SELECT g.year, g.value, s.csiro
FROM gdp g JOIN sea_level s ON s.anio = g.year
WHERE g.country_code = 'MEX';

SET enable_hashjoin = off;   -- repite la consulta: ¿qué eligió ahora?
SET enable_nestloop = off;   -- repítela otra vez: debería quedar Merge Join
RESET enable_hashjoin;
RESET enable_nestloop;