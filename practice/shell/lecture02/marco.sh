#!/usr/bin/env bash

marco() {
  MARCO_DIR="$(pwd)"
  echo "Directorio guardado: $MARCO_DIR"
}

polo() {
  if [[ -z "${MARCO_DIR:-}" ]]; then
    echo "Primero ejecuta marco" >&2
    return 1
  fi

  cd "$MARCO_DIR" || return 1
}