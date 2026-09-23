import pandas as pd
from sqlalchemy import create_engine

# sin host = usa el socket Unix por defecto, igual que psql
engine = create_engine("postgresql+psycopg2://mlizz@/datos")

df = pd.read_sql("SELECT * FROM gdp", engine)

print("Filas cargadas:", len(df))

resultado = (
    df.groupby("country_name")
      .agg(PromValue=("value", "mean"), anios=("year", "nunique"))
      .query("anios > 20")
      .sort_values("PromValue", ascending=False)
      .head(5)
)

resultadoV2 = df.groupby("country_name")["value"].sum()

print(resultado)
print(resultadoV2)