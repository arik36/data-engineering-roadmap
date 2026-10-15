import pandas as pd

print("--- 1. Lista de escalares ---")
# Genera 3 filas y 1 columna (shape 3, 1)
df1 = pd.DataFrame([1, 2, 3])
print(df1)
print("\n")

print("--- 2. Lista de listas ---")
# Genera 3 filas y 2 columnas (shape 3, 2)
df2 = pd.DataFrame([[1, 2], [3, 4], [5, 6]])
print(df2)
print("\n")

print("--- 3. Lista de diccionarios ---")
# El caso ideal: 2 filas y 2 columnas (shape 2, 2)
df3 = pd.DataFrame([{"a": 1, "b": 2}, {"a": 3, "b": 4}])
print(df3)
print("\n")

print("--- 4. Diccionario de escalares ---")
try:
    # Esto lanza ValueError porque faltan las filas
    df4_error = pd.DataFrame({"a": 1, "b": 2})
except ValueError as e:
    print("¡Dio error tal como se predijo! Mensaje:")
    print(e)
    print("\nPara solucionarlo, le damos un índice explícito:")
    df4_arreglado = pd.DataFrame({"a": 1, "b": 2}, index=[0])
    print(df4_arreglado)
print("\n")

print("--- 5. Diccionario de listas ---")
# Las listas internas dan las filas: 2 filas y 2 columnas (shape 2, 2)
df5 = pd.DataFrame({"a": [1, 3], "b": [2, 4]})
print(df5)
print("\n")

print("--- 6. Diccionario de diccionarios ---")
# No da error de sintaxis, pero mete diccionarios enteros dentro de las celdas
df6 = pd.DataFrame({"a": {"x": 1, "y": 2}, "b": {"x": 3, "y": 4}})
print(df6)
print("Contenido de la celda 'a':", df6["a"]["x"]) # Sigue siendo un diccionario anidado