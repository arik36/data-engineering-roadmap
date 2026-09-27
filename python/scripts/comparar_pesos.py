# ¿Cuántas filas trae el CSV vs. cuántas hay en la DB para un mismo país?
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://mlizz@/datos")
df = pd.read_sql("SELECT * FROM gdp", engine)

ruta="~/projects/data-engineering-roadmap/data/raw/2026-09-19_gdp.csv"

df_csv = pd.read_csv(ruta, encoding="utf-8-sig")
print(df_csv["Country Name"].value_counts().head())   # filas por país en el CSV

print(df.groupby("country_name")["value"].nunique().sort_values(ascending=False).head())