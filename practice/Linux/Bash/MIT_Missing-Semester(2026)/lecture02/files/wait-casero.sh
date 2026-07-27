#!/usr/bin/env bash

pidwait() {
    if [[ $# -ne 1 ]]; then
        echo "Uso: pidwait PID" >&2
        return 1
    fi

    pid="$1"

    until ! kill -0 "$pid" 2>/dev/null; do
        sleep 2
    done

    echo "El proceso $pid ha terminado."
}