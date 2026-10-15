
import requests
import json
import pandas as pd

#. aplanar los datos
with open("python/scripts/repos.json", "r", encoding="utf-8") as f:
    contenido = json.load(f)
df = pd.DataFrame(contenido)
norm = pd.json_normalize(contenido)

print (df)
print(norm)

print(df['owner'].dtype)
print(norm['owner.id'].dtype)