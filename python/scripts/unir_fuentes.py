import pandas as pd

archivo_vix = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_vix-daily.csv"
archivo_gdp = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_gdp.csv"
archivo_sea = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_epa-sea-level.csv"

vix = pd.read_csv(archivo_vix, encoding="utf-8-sig")
gdp = pd.read_csv(archivo_gdp, encoding="utf-8-sig")
sea = pd.read_csv(archivo_sea, encoding="utf-8-sig")

#agrupar gdp por año y sumar el value para tener el pib mundial por año

#1.- validar que no haya nulls en value
gdp_filtrado = gdp[gdp['Value'].notnull()]

#2.- agrupar por año y sumar el value
resultado_gdp = (
    gdp_filtrado
    .groupby('Year')
    .agg(
        pib_mundial=('Value', 'sum'),
    )
    .reset_index()
    .rename (columns={'Year': 'anio'})
    )

#extraer el año de la columna DATE en vix, agrupar por año y calcular el promedio de close
vix['anio']= pd.to_datetime(vix['DATE'], errors="coerce").dt.year

resultado_vix = (
    vix
    .groupby('anio')
    .agg(
        vix_promedio=('CLOSE', 'mean'),
    )
    .reset_index()
)

# hacemos un merge de gdp con sea por año, y luego un merge con vix por año
#queremos mostrar el año de gdp, el pib mundial, el nivel del mar csiro y el promedio de close del vix
# el doble corchete en sea[['anio', 'csiro']] es para seleccionar solo esas dos columnas y luego renombrar la columna csiro a nivel_mar
sea_filtrado = sea[
    ['Year', 'CSIRO Adjusted Sea Level']
].rename(
    columns={
        'Year': 'anio',
        'CSIRO Adjusted Sea Level': 'nivel_mar'
    }
)

resultado_final = pd.merge(
    resultado_gdp,
    sea_filtrado,
    on="anio",
    how="left"
)

resultado_final = pd.merge(
    resultado_final,
    resultado_vix,
    on="anio",
    how="left"
)

print("Todos los registros:", len(resultado_final))
print(
    "Registros nivel mar no nulos:",
    resultado_final['nivel_mar'].notna().sum()
)
print(
    "Registros VIX no nulos:",
    resultado_final['vix_promedio'].notna().sum()
)