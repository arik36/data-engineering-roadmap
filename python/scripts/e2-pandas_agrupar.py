import pandas as pd
from sqlalchemy import create_engine
# Este script agrupa los datos de un archivo CSV por la columna "country_name" y 
# suma la columna "value" para cada país.


# sin host = usa el socket Unix por defecto, igual que psql
engine = create_engine("postgresql+psycopg2://mlizz@/datos")

df = pd.read_sql("SELECT * FROM gdp", engine)

print("Filas cargadas:", len(df))
df_filtrado = df[(df["year"] > 2000) & (df["value"] > 1e9)]

resultado = (
    df_filtrado.groupby("country_name")
      .agg(TotalValue=("value", "sum"), anios=("year", "nunique"))
      .query("anios > 20")
      .sort_values("TotalValue", ascending=False)
      .head(5)
      .reset_index()
)
# al hacer el groupby, el índice del dataframe resultante es la columna por la que se agrupó. 
# Para guardar en un CSV sin índice, se puede usar reset_index() o index=False en to_csv()
resultadoV2 = df.groupby("country_name")["value"].sum().reset_index()

ruta="~/projects/data-engineering-roadmap/python/scripts/salidas/e2-pandas_agrupar.csv"
resultado.to_csv(ruta, index=False)

print(resultado)
print(resultadoV2)