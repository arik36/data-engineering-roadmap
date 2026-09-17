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