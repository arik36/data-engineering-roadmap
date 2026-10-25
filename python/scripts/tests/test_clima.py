import pandas as pd
import pytest
import requests

import clima_unificado as clima
from clima_unificado import leer, main, transformar

DATOS = {
    "daily": {
        "time": ["2026-01-01", "2026-01-02"],
        "temperature_2m_max": [25.0, 26.1],
        "temperature_2m_min": [8.0, 9.2],
    }
}


class RespuestaFalsa:
    """Imita lo mínimo de requests.Response que usa clima.leer()."""

    def __init__(self, status=200, reason="OK", text="{}", datos=DATOS):
        self.status_code = status
        self.reason = reason
        self.text = text
        self._datos = datos

    def raise_for_status(self):
        if self.status_code >= 400:
            raise requests.exceptions.HTTPError(response=self)

    def json(self):
        if self._datos is None:
            raise ValueError("no es JSON")
        return self._datos


# ---------- transformar(): recibe un dict, no toca la red ----------

def test_transformar_aplana_daily():
    df = transformar(DATOS)
    assert len(df) == 2
    assert list(df.columns) == ["time", "temperature_2m_max", "temperature_2m_min"]


def test_transformar_sin_daily():
    with pytest.raises(SystemExit) as e:
        transformar({"error": True, "reason": "algo falló"})
    assert e.value.code == 3


def test_transformar_sin_dias():
    vacio = {"daily": {"time": [], "temperature_2m_max": [], "temperature_2m_min": []}}
    with pytest.raises(SystemExit) as e:
        transformar(vacio)
    assert e.value.code == 3


# ---------- leer(): requests.get se reemplaza por uno falso ----------

def test_leer_manda_los_parametros_y_devuelve_el_json(monkeypatch):
    llamadas = []

    def get_falso(url, params=None, timeout=None):
        llamadas.append(params)
        return RespuestaFalsa()

    monkeypatch.setattr(clima.requests, "get", get_falso)

    assert leer("2026-01-01", "2026-01-02") == DATOS
    assert llamadas[0]["start_date"] == "2026-01-01"
    assert llamadas[0]["end_date"] == "2026-01-02"


@pytest.mark.parametrize("excepcion", [
    requests.exceptions.Timeout(),
    requests.exceptions.ConnectionError(),
])
def test_leer_sin_red_da_codigo_6(monkeypatch, excepcion):
    def get_falso(*args, **kwargs):
        raise excepcion

    monkeypatch.setattr(clima.requests, "get", get_falso)
    with pytest.raises(SystemExit) as e:
        leer("2026-01-01", "2026-01-02")
    assert e.value.code == 6


def test_leer_error_http_da_codigo_7(monkeypatch):
    falsa = RespuestaFalsa(status=400, reason="Bad Request",
                           text='{"reason": "fecha inválida"}')
    monkeypatch.setattr(clima.requests, "get", lambda *a, **k: falsa)
    with pytest.raises(SystemExit) as e:
        leer("no-es-fecha", "2026-01-02")
    assert e.value.code == 7


def test_leer_cuerpo_no_json_da_codigo_3(monkeypatch):
    falsa = RespuestaFalsa(datos=None)
    monkeypatch.setattr(clima.requests, "get", lambda *a, **k: falsa)
    with pytest.raises(SystemExit) as e:
        leer("2026-01-01", "2026-01-02")
    assert e.value.code == 3


# ---------- Contrato de stdout ----------

def test_main_imprime_solo_la_ruta(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(clima.requests, "get", lambda *a, **k: RespuestaFalsa())
    salida = tmp_path / "clima.csv"

    main(["--inicio", "2026-01-01", "--fin", "2026-01-02", "--salida", str(salida)])

    assert capsys.readouterr().out == f"{salida}\n"
    assert len(pd.read_csv(salida)) == 2
