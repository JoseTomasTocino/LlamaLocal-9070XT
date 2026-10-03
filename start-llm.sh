#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
MODEL=''
CONTEXT=16384
GPU_LAYERS=auto
VRAM_RESERVE_MIB=2048
PORT=8080

usage() {
    echo "Uso: $0 [--model ARCHIVO] [--context N] [--gpu-layers N|auto] [--vram-reserve-mib N] [--port N]"
}

while (( $# )); do
    case "$1" in
        --model) MODEL=${2:?Falta el modelo}; shift 2 ;;
        --context) CONTEXT=${2:?Falta el contexto}; shift 2 ;;
        --gpu-layers) GPU_LAYERS=${2:?Faltan las capas}; shift 2 ;;
        --vram-reserve-mib) VRAM_RESERVE_MIB=${2:?Falta la reserva}; shift 2 ;;
        --port) PORT=${2:?Falta el puerto}; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Opcion desconocida: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$MODEL" ]]; then
    name=''
    [[ -r "$ROOT/selected-model.txt" ]] && IFS= read -r name < "$ROOT/selected-model.txt" || true
    name=${name//$'\r'/}
    name=${name#$'\xef\xbb\xbf'}
    name=${name:-Qwen3.8-27B-UD-Q3_K_XL.gguf}
    [[ "$name" != */* && "$name" == *.gguf ]] || { echo 'La seleccion de modelo no es valida.' >&2; exit 1; }
    MODEL="$ROOT/models/$name"
fi
[[ -f "$MODEL" ]] || { echo "No se encuentra el modelo: $MODEL" >&2; exit 1; }

SERVER="$ROOT/runtime/llama-b11351-linux/llama-server"
[[ -x "$SERVER" ]] || SERVER=$(command -v llama-server || true)
[[ -x "$SERVER" ]] || { echo 'Falta llama-server. Ejecuta ./install-linux.sh' >&2; exit 1; }

if command -v hipcc >/dev/null 2>&1; then
    ROCM_CORE=$(dirname "$(dirname "$(readlink -f "$(command -v hipcc)")")")
    export LD_LIBRARY_PATH="$ROCM_CORE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

mkdir -p "$ROOT/logs"
exec 9>"$ROOT/logs/server-linux.lock"
flock -n 9 || { echo 'Ya hay un arranque de esta instalacion en curso.' >&2; exit 1; }
printf '%s\n' "$$" > "$ROOT/logs/server-linux.pid"
export HIP_VISIBLE_DEVICES=0
exec "$SERVER" \
    --model "$MODEL" --alias qwen3.8-27b --ctx-size "$CONTEXT" \
    --device ROCm0 --gpu-layers "$GPU_LAYERS" --fit on --fit-target "$VRAM_RESERVE_MIB" \
    --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 \
    --batch-size 512 --ubatch-size 128 --parallel 1 \
    --host 127.0.0.1 --port "$PORT" --verbosity 4 --agent
