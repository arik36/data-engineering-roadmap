DROP TABLE IF EXISTS gdp;
CREATE TABLE gdp (
    country_name text,
    country_code text,
    year integer,
    value numeric,
    PRIMARY KEY (country_name, year)
);

-- 2. Tabla sea_level
DROP TABLE IF EXISTS sea_level;
CREATE TABLE sea_level (
    anio integer PRIMARY KEY,
    csiro numeric,
    lower numeric,
    upper numeric, 
    noaa numeric
);

--3. Tabla vix
DROP TABLE IF EXISTS vix;
CREATE TABLE vix (
    fecha date PRIMARY KEY,
    open numeric,
    high numeric,
    low numeric,
    close numeric
);
