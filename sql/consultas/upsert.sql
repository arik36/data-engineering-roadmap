BEGIN;
---Inserta una fila con una fecha que ya existe
INSERT INTO vix (fecha, open, high, low, close)
VALUES('1990-01-02', 18.4000, 16.9033, 17.9382, 20.3423);
--ERROR:  duplicate key value violates unique constraint "vix_pkey"
--DETAIL:  Key (fecha)=(1990-01-02) already exists.

INSERT INTO vix (fecha, open, high, low, close)
VALUES('1990-01-02', 18.4000, 16.9033, 17.9382, 20.3423)
ON CONFLICT (fecha) DO NOTHING;

SELECT * FROM vix
WHERE fecha = '1990-01-02';

INSERT INTO vix (fecha, open, high, low, close)
VALUES('1990-01-02', 18.4000, 16.9033, 17.9382, 20.3423)
ON CONFLICT (fecha) DO UPDATE
SET open = EXCLUDED.open , close = EXCLUDED.close;

--   fecha    |  open   |   high    |    low    |  close
------------+---------+-----------+-----------+---------
-- 1990-01-02 | 18.4000 | 17.240000 | 17.240000 | 20.3423
--(1 row)

SELECT * FROM vix
WHERE fecha = '1990-01-02';

--   fecha    |   open    |   high    |    low    |   close
------------+-----------+-----------+-----------+-----------
-- 1990-01-02 | 17.240000 | 17.240000 | 17.240000 | 17.240000
--(1 row)

ROLLBACK;