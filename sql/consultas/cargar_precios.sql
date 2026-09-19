CREATE TABLE precios (
    producto TEXT,
    presentacion TEXT,
    marca TEXT,
    categoria TEXT,
    catalogo TEXT,
    precio NUMERIC,
    fecha_registro DATE,
    cadena_comercial TEXT,
    giro TEXT,
    nombre_comercial TEXT,
    direccion TEXT,
    estado TEXT,
    municipio TEXT,
    latitud NUMERIC,
    longitud NUMERIC
);

\copy precios FROM '/home/mlizz/canastamx-datos/crudo/QQP_2025/03-2025_01.csv' WITH (FORMAT csv, HEADER true)

--18-09-2026
-- 1. saber el promedio de precios por catalogo
SELECT catalogo, AVG(precio) AS promedio
FROM precios
GROUP BY catalogo;
      catalogo       |       promedio
---------------------+-----------------------
 Basicos             |   68.7097709582262822
 Electrodomesticos   | 6724.9360529418842498
 Frutas y Legumbres  |   47.7754062140391254
 Medicamentos        |  501.6764028703785346
 Mercados            |   80.4332937710437710
 Pacic               |   34.9956894760279056
 Pescados y Mariscos |  211.9033546915725456
(7 rows)

-- 2.saber el numero de filas por catalogo y el numero de precios no nulos
SELECT catalogo, COUNT(*) AS filas, COUNT(precio) AS precios_no_nulos
FROM precios
GROUP BY catalogo;
      catalogo       | filas  | precios_no_nulos
---------------------+--------+------------------
 Basicos             | 315270 |           315270
 Electrodomesticos   |  41555 |            41555
 Frutas y Legumbres  |  34760 |            34760
 Medicamentos        | 147437 |           147437
 Mercados            |  11880 |            11880
 Pacic               |  26948 |            26948
 Pescados y Mariscos |   9208 |             9208
(7 rows)

--3. ¿Cuál es el precio máximo por fecha de registro?
SELECT fecha_registro, MAX (precio) AS precioMax
FROM precios
GROUP BY fecha_registro
ORDER BY fecha_registro;
 fecha_registro | preciomax
----------------+-----------
 2025-03-03     |     69999
 2025-03-04     |     69999
 2025-03-05     |     42949
 2025-03-06     |     69999
 2025-03-07     |     42999
 2025-03-10     |     42999
 2025-03-11     |     42949
 2025-03-12     |     54999
 2025-03-13     |     54999
 2025-03-14     |     46699
(10 rows)

--4 ¿Cuántas fechas de registro distintas hay por categoría?
SELECT fecha_registro, COUNT(DISTINCT fecha_registro) AS fechasDiff
FROM precios
GROUP BY fecha_registro
ORDER BY fecha_registro;
 fecha_registro | fechasdiff
----------------+------------
 2025-03-03     |          1
 2025-03-04     |          1
 2025-03-05     |          1
 2025-03-06     |          1
 2025-03-07     |          1
 2025-03-10     |          1
 2025-03-11     |          1
 2025-03-12     |          1
 2025-03-13     |          1
 2025-03-14     |          1
(10 rows)
