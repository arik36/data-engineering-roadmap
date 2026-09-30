
-- ¿Cuántas fechas de registro distintas hay por categoría?
WITH fechasxcategoria AS(
    SELECT catalogo, COUNT(DISTINCT fecha_registro) AS fechasDiff
    FROM precios
    GROUP BY catalogo
    ORDER BY fechasDiff ASC
)
SELECT * FROM fechasxcategoria;


-- brindar los cinco municipios con los promedios de precios más altos y 
-- sus cinco categorias mas compradas 
WITH municipiospr_alto AS(
    SELECT 
    municipio, 
    AVG(precio) AS promedio
    FROM precios
    GROUP BY municipio
    ORDER BY promedio DESC
    LIMIT 5
), mayores_categorias AS (
    SELECT
        mun.municipio,
        mun.promedio,
        pr.categoria,
        COUNT(*) AS cantidad_registros
    FROM municipiospr_alto mun
    INNER JOIN precios pr
        ON mun.municipio = pr.municipio
    GROUP BY
        mun.municipio,
        mun.promedio,
        pr.categoria
)

SELECT * FROM mayores_categorias;

--En el primer CTE, `GROUP BY municipio` genera una sola fila por municipio y calcula un único `promedio` para cada uno.
--Cuando hacemos el `JOIN` con `precios`, esa fila se combina con todos los registros que pertenecen al mismo municipio.
--Por eso el `promedio` se repite en todas esas filas y no cambia, ya que viene calculado desde el primer CTE.
--Después, el `GROUP BY municipio, promedio, categoria` agrupa los registros según esas tres columnas.
--Sin embargo, como cada municipio ya tiene un único promedio, `promedio` no aporta una nueva división de grupos.
--En la práctica, el verdadero grano del agrupamiento es `municipio + categoria`.
--Por eso `COUNT(*)` cuenta cuántos registros de `precios` existen para cada combinación de municipio y categoría.


--los 5 países cuyo promedio está por encima del promedio global
WITH prom_glob AS(
    SELECT AVG(precio) AS precioProm
    FROM precios
), max5 AS(
    SELECT municipio, AVG(precio) AS promun
    FROM precios
    GROUP BY municipio
    HAVING AVG(precio) > (SELECT precioProm FROM prom_glob)
    ORDER BY promun DESC
    LIMIT 5
)

SELECT * FROM max5;
SELECT * FROM prom_glob;