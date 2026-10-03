#!/usr/bin/env bash
set -euo pipefail

url="${1:-}"

columnas= "${2:-}"

archivo=$(./scripts/ingesta.sh "$url" data/raw "$columnas")
resumen=$(python3 python/scripts/transformarv2.py "$archivo")
psql -d datos -c "\copy resumen FROM '$resumen' WITH (FORMAT csv, HEADER true)"