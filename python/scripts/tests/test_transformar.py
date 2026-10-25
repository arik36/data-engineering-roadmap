import pandas as pd
import pytest

from transformar_unificado import main, transformar, leer


# ---------- Las tres pruebas de la lección ----------

def test_agrupa_y_promedia():
    df = pd.DataFrame({
        "pais":  ["MX", "MX", "US"],
        "anio":  [2000, 2001, 2000],
        "valor": [10.0, 20.0, 50.0],
    })
    r = transformar(df, "pais", "anio", "valor")

    assert len(r) == 2
    assert list(r.columns) == ["grupo", "n_registros", "valor_promedio", "valor_max"]
    mx = r.loc[r["grupo"] == "MX"].iloc[0]
    assert mx["n_registros"] == 2
    assert mx["valor_promedio"] == 15.0
    assert mx["valor_max"] == 20.0


def test_descarta_nulos():
    df = pd.DataFrame({
        "pais":  ["MX", "MX", "MX", "US"],
        "anio":  [2000, 2001, 2002, 2000],
        "valor": [10.0, None, 30.0, None],
    })
    r = transformar(df, "pais", "anio", "valor")

    assert list(r["grupo"]) == ["MX"]     # US solo tenía nulos: desaparece
    assert r["n_registros"].iloc[0] == 2  # la fila nula no se cuenta
    assert r["valor_promedio"].iloc[0] == 20.0


def test_falta_columna(capsys):
    df = pd.DataFrame({"pais": ["MX"]})
    with pytest.raises(SystemExit) as e:
        transformar(df, "pais", "anio", "valor")

    assert e.value.code == 4
    err = capsys.readouterr().err
    assert "anio" in err and "valor" in err  # se listan TODAS las que faltan


# ---------- Resto de la tabla de códigos ----------

def test_columna_no_numerica():
    df = pd.DataFrame({"pais": ["MX"], "anio": [2000], "valor": ["texto"]})
    with pytest.raises(SystemExit) as e:
        transformar(df, "pais", "anio", "valor")
    assert e.value.code == 5


def test_todo_nulo():
    nan = float("nan")
    df = pd.DataFrame({"pais": ["MX", "US"], "anio": [2000, 2001], "valor": [nan, nan]})
    with pytest.raises(SystemExit) as e:
        transformar(df, "pais", "anio", "valor")
    assert e.value.code == 3


def test_archivo_inexistente(tmp_path):
    with pytest.raises(SystemExit) as e:
        leer(str(tmp_path / "no_existe.csv"))
    assert e.value.code == 3


# ---------- Contrato de stdout ----------

def test_main_imprime_solo_la_ruta(tmp_path, capsys):
    entrada = tmp_path / "entrada.csv"
    entrada.write_text("pais,anio,valor\nMX,2000,10\nMX,2001,20\nUS,2000,50\n")
    salida = tmp_path / "sub" / "resumen.csv"  # la carpeta "sub" no existe aún

    main([str(entrada), "--grupo", "pais", "--tiempo", "anio",
          "--valor", "valor", "--salida", str(salida)])

    assert capsys.readouterr().out == f"{salida}\n"  # nada más que la ruta
    assert len(pd.read_csv(salida)) == 2
