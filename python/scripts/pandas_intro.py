import pandas as pd

df = pd.read_csv("~/projects/data-engineering-roadmap/data/raw/2026-09-19_epa-sea-level.csv")
print(df.shape)      # (filas, columnas)
print(df.columns.tolist())
print(df.head())
print(df.dtypes)