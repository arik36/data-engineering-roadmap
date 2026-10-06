# Práctica (30 min): carga dos de tus CSV en dos DataFrames y únelos por year.
# Va a chocar con dos cosas, y las dos son el trabajo del día:
import pandas as pd
#1er archivo 
archivo_izq = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_epa-sea-level.csv"
archivo_der = "~/projects/data-engineering-roadmap/data/raw/2026-09-19_gdp.csv"


#el left join hace que todo lo que está en izq se mantenga, y lo que no tenga match en der se rellena con NaN
izq = pd.read_csv(archivo_izq, encoding="utf-8-sig")
der = pd.read_csv(archivo_der, encoding="utf-8-sig")


#hacer merge en year
juntos = pd.merge(izq, der, on="Year", how="inner")

#year en izq es una clave 1 a 1, pero en der es una clave 1 a muchos. 
#Por eso el resultado tiene la misma cantidad de filas que der.
print(len(izq), len(der), len(juntos))
# me dio 144 13979 13979



