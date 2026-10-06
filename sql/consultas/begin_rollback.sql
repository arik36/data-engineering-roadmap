--dentro de BEGIN/ROLLBACK: borra los años anteriores a 1990,
-- comprueba el conteo, y revierte. Comprueba que el conteo volvió al original.

datos=> SELECT COUNT(*) FROM gdp;
 count
-------
 13979
(1 row)

datos=> BEGIN;
BEGIN
datos=*> DELETE FROM gdp
WHERE year < 1990;
DELETE 5401
datos=*> SELECT COUNT(*) FROM gdp;
 count
-------
  8578
(1 row)

datos=*> ROLLBACK;
ROLLBACK
datos=> SELECT COUNT(*) FROM gdp;
 count
-------
 13979
(1 row)