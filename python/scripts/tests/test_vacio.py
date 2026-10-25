import pandas as pd
import pytest
from clima_unificadov2 import ErrorPipeline as ErrorClima, transformar
from unirfuentes_unificadov2 import (
    ErrorPipeline as ErrorUnir,
    validar_numerica,
)
from transformar_unificadov2 import (
    ErrorPipeline as ErrorTransf, 
    transformar as transf,
)
#1.- prueba diccionario vacio
def test_transformar_vacio():
  dicc_invalido = {}

  # Usamos el alias de clima
  with pytest.raises(ErrorClima) as exc_info:
    transformar(dicc_invalido)

  assert exc_info.value.codigo == 3

#2.- prueba columna no numerica
def test_columna_incorrecta():
  dicc_no_num = {"sabores": ["fresa", "mango"]}
  df = pd.DataFrame(dicc_no_num)

  # Usamos el alias de unirfuentes
  with pytest.raises(ErrorUnir) as exc_info:
    validar_numerica(df, "sabores", fuente="tabla")

  assert exc_info.value.codigo == 5

#3.- Una columna de valor con todos los valores nulos
def test_transformar_value():
  dicc_val = {"sabores": ["fresa", "mango"],
               "fecha": ['24-10-26', '23-11-26'],
               "value": [None, None]}

  df = pd.DataFrame(dicc_val)
  with pytest.raises(ErrorTransf) as exc_info:
    transf(df, "sabores", "fecha", "value")
    

  assert exc_info.value.codigo == 3