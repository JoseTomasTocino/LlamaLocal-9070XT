#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERSION=b11351
DEST="$ROOT/runtime/llama-$VERSION-linux"
SOURCE="$DEST/source"

for command_name in git cmake g++ hipcc; do
    command -v "$command_name" >/dev/null || { echo "Falta el comando: $command_name" >&2; exit 1; }
done
if [[ ! -f /opt/rocm/lib/cmake/hip-lang/hip-lang-config.cmake ]]; then
    cat >&2 <<'EOF'
Faltan las cabeceras y los archivos CMake de desarrollo de ROCm.
La instalacion actual contiene el runtime, pero no el SDK necesario para compilar.

Instalalos una sola vez con:
  sudo apt install amdrocm-core-dev7.14-gfx1201

Despues vuelve a ejecutar ./install-linux.sh. Los modelos no se descargaran.
EOF
    exit 1
fi
mkdir -p "$DEST"
if [[ ! -d "$SOURCE/.git" ]]; then
    git clone --branch "$VERSION" --depth 1 https://github.com/ggml-org/llama.cpp.git "$SOURCE"
fi

ROCM_PATH=/opt/rocm
ROCM_CORE=$(dirname "$(dirname "$(readlink -f "$(command -v hipcc)")")")
export ROCM_PATH
cmake -S "$SOURCE" -B "$SOURCE/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_NUMBER=11351 \
    -DLLAMA_BUILD_COMMIT=631109b34 \
    -DGGML_HIP=ON \
    -DAMDGPU_TARGETS=gfx1201 \
    -DCMAKE_HIP_COMPILER_ROCM_ROOT="$ROCM_PATH" \
    -DCMAKE_BUILD_RPATH="$ROCM_CORE/lib" \
    -DCMAKE_INSTALL_RPATH="$ROCM_CORE/lib" \
    -DCMAKE_PREFIX_PATH="$ROCM_PATH"
cmake --build "$SOURCE/build" --config Release --target llama-server -j"$(nproc)"
ln -sfn "source/build/bin/llama-server" "$DEST/llama-server"

echo
echo "Instalado llama.cpp $VERSION con HIP para gfx1201."
echo 'Los modelos existentes no se han modificado ni descargado de nuevo.'
echo 'Inicia el menu con: ./ia-local'
