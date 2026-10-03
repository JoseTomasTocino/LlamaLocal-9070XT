#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PID_FILE="$ROOT/logs/server-linux.pid"
if [[ ! -r "$PID_FILE" ]]; then echo 'La IA ya esta apagada.'; exit 0; fi
read -r pid < "$PID_FILE"
expected=$(readlink -f -- "$ROOT/runtime/llama-b11351-linux/llama-server" 2>/dev/null || true)
actual=''
[[ "$pid" =~ ^[0-9]+$ ]] && actual=$(readlink -f -- "/proc/$pid/exe" 2>/dev/null || true)
if [[ -z "$actual" || "$actual" != "$expected" ]]; then
    rm -f -- "$PID_FILE"
    echo 'La IA ya esta apagada; se ha limpiado un PID antiguo.'
    exit 0
fi
kill "$pid"
for _ in {1..50}; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
done
if kill -0 "$pid" 2>/dev/null; then
    echo 'El servidor no termino a tiempo; no se ha forzado su cierre.' >&2
    exit 1
fi
rm -f -- "$PID_FILE"
echo 'IA apagada. La memoria se esta liberando.'
