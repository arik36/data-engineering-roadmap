import pandas as pd
import pytest

from unirfuentes_unificado import main, transformar


def fuentes():
    """Tres fuentes mínimas. GDP tiene 2000, 2001 y 2002; sea y vix no
    cubren todos esos años, y sea trae un 2003 que GDP no tiene."""
    vix = pd.DataFrame({
        "DATE":  ["2000-01-02", "2000-06-01", "2001-01-03"],
        "CLOSE": [20.0, 30.0, 10.0],
    })
    gdp = pd.DataFrame({
        "Year":  [2000, 2000, 2001, 2002],
        "Value": [100.0, 50.0, 200.0, 300.0],
    })
    sea = pd.DataFrame({
        "Year": [2000, 2001, 2003],
        "CSIRO Adjusted Sea Level": [6.5, 6.7, 7.0],
    })
    return vix, gdp, sea


def test_une_por_anio_de_gdp():
    vix, gdp, sea = fuentes()
    r = transformar(vix, gdp, sea)

    assert list(r.columns) == ["anio", "pib_mundial", "nivel_mar", "vix_promedio"]
    assert list(r["anio"]) == [2000, 2001, 2002]   # 2003 (solo en sea) no aparece

    a2000 = r.loc[r["anio"] == 2000].iloc[0]
    assert a2000["pib_mundial"] == 150.0           # 100 + 50
    assert a2000["nivel_mar"] == 6.5
    assert a2000["vix_promedio"] == 25.0           # (20 + 30) / 2

    a2002 = r.loc[r["anio"] == 2002].iloc[0]
    assert pd.isna(a2002["nivel_mar"])             # left merge: sin dato -> NaN
    assert pd.isna(a2002["vix_promedio"])


def test_no_modifica_los_dataframes_de_entrada():
    vix, gdp, sea = fuentes()
    transformar(vix, gdp, sea)
    assert "anio" not in vix.columns


def test_falta_columna(capsys):
    vix, gdp, sea = fuentes()
    with pytest.raises(SystemExit) as e:
        transformar(vix, gdp.drop(columns="Value"), sea)

    assert e.value.code == 4
    assert "gdp" in capsys.readouterr().err        # dice cuál fuente falló


def test_close_no_numerica():
    vix, gdp, sea = fuentes()
    vix["CLOSE"] = ["a", "b", "c"]
    with pytest.raises(SystemExit) as e:
        transformar(vix, gdp, sea)
    assert e.value.code == 5


def test_vix_sin_fechas_validas():
    vix, gdp, sea = fuentes()
    vix["DATE"] = ["x", "y", "z"]
    with pytest.raises(SystemExit) as e:
        transformar(vix, gdp, sea)
    assert e.value.code == 3


# ---------- Contrato de stdout ----------

def test_main_imprime_solo_la_ruta(tmp_path, capsys):
    (tmp_path / "vix.csv").write_text(
        "DATE,CLOSE\n2000-01-02,20\n2000-06-01,30\n2001-01-03,10\n")
    (tmp_path / "gdp.csv").write_text(
        "Country Name,Year,Value\nA,2000,100\nB,2000,50\nA,2001,200\nA,2002,300\n")
    (tmp_path / "sea.csv").write_text(
        "Year,CSIRO Adjusted Sea Level\n2000,6.5\n2001,6.7\n")
    salida = tmp_path / "unido.csv"

    main(["--vix", str(tmp_path / "vix.csv"), "--gdp", str(tmp_path / "gdp.csv"),
          "--sea", str(tmp_path / "sea.csv"), "--salida", str(salida)])

    captura = capsys.readouterr()
    assert captura.out == f"{salida}\n"                 # stdout: solo la ruta
    assert "Todos los registros: 3" in captura.err      # diagnósticos: a stderr
    assert len(pd.read_csv(salida)) == 3
