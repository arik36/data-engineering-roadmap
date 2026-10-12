import pandas as pd

archivo_vix = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_vix-daily.csv"

vix_df = pd.read_csv(archivo_vix, encoding="utf-8-sig")

#revisar los tipos de datos de las columnas
print(vix_df.dtypes)
vix_df['DATE'] = pd.to_datetime(vix_df['DATE'], errors="coerce")
vix_df['Year'] = vix_df['DATE'].dt.year

print(vix_df["DATE"].isna().sum())

#vix_df filtrado
df_filtrado = vix_df[vix_df['Year'].notnull()]

resultado = (
    df_filtrado
    .groupby('Year')
    .agg(
    #promedio de close
        promedio_close=('CLOSE', 'mean'),
    ).reset_index()
)
#imprimir el resultado
print(resultado)