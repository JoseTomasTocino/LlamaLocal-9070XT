# Revision de Windows — 6 de noviembre de 2026

## Decision final tras probar ROCm 10.1

El menu y el arranque usan ahora b12110 con
ROCm 10.1 en una copia aislada `runtime/llama-b12110-rocm101`.
Es el binario oficial compilado para 10.0 ejecutado con bibliotecas 10.1;
no se ha presentado como compilacion oficial para 10.1.

Se verificaron las rutas reales de los modulos del proceso: HIP, COMGR,
kpack, hipBLAS, rocBLAS y hipBLASLt proceden de la copia/entorno 10.1.
Con el modelo seleccionado Huihui Q3: 66/66 capas GPU, Flash Attention y
respuesta correcta de 391. Tres pasadas de 1601 tokens de entrada y 128
de salida dieron medias de 892,11 tokens/s de prompt y 29,85 tokens/s de
generacion. Entrada de 15800 tokens: 898,17 tokens/s de prompt y 28,62 de
generacion, sin truncamiento. No se midio Q4 ni estabilidad prolongada.

Las cifras previas 10.0 son de otro momento y una sola pasada; la mejora
observada no permite atribuir causalmente toda la diferencia a ROCm.
Evidencias en `logs/rocm101-*.json` y `logs/rocm101.stderr.log`.
No se cambio el driver. El entorno 10.0 sigue disponible para rollback
con `-RuntimeVersion b11351 -RocmVersion 10.0`.

## Instalacion y versiones verificadas

- AMD Software 26.10.1; controlador Windows 32.0.32015.7029, fecha 18/10/2026.
- `.venv`: paquetes ROCm 10.0.0, conservados para volver atras.
- `.venv-rocm101`: rocm, rocm-sdk-core, rocm-sdk-libraries y
  rocm-sdk-device-gfx1201 en 10.1.0, desde el indice estable de AMD.
- `pip check` correcto; HIP inicializa y detecta la RX 9070 XT.
- Binario nuevo: b12110-cd959bae9, asociado a v0.9.0 mediante nightly-tag.txt.
- ZIP oficial: llama-b12110-bin-win-rocm-10.0-x64.zip.
- SHA-256 verificado:
  `097f408356dbaaa318c1b4be75f5d524bdab01541203adf16bf6e486b75deae4`.

La copia b12110-rocm101 contiene las DLL HIP, COMGR y kpack del entorno
10.1 y utiliza sus bibliotecas matematicas mediante PATH. No se cambio el
controlador. La configuracion es una combinacion comprobada localmente,
no un paquete oficial compilado especificamente para ROCm 10.1.

La API devolvio 391 correctamente y `/tools` publico las herramientas.
No se comprobo la ejecucion de ediciones ni el ciclo autonomo de herramientas.
Las pruebas se hicieron en 8081 y el perfil activo se comprobo despues en 8080.
El servidor quedo apagado a peticion del usuario al terminar la sesion.

Para volver al perfil original, detener desde el menu y ejecutar:

```powershell
.\Start-LLM.ps1 -RuntimeVersion b11351 -RocmVersion 10.0
```

Para probar b12110 con el runtime anterior:

```powershell
.\Start-LLM.ps1 -RuntimeVersion b12110 -RocmVersion 10.0
```

El menu reconoce los tres ejecutables y la parada solo actua sobre sus rutas
concretas. Modelos, binarios, entornos y registros permanecen fuera de Git.

## Comparacion inicial con ROCm 10.0

Mismo archivo GGUF, entrada repetida de 1601 tokens, salida forzada de 128,
temperatura cero, cache de prompt desactivada y parametros habituales de 16K.
Una pasada por version, ambas con ROCm 10.0; no es una comparacion estadistica ni una prueba de calidad.

| Version | Prompt tokens/s | Generacion tokens/s |
|---|---:|---:|
| b11351 | 777,39 | 22,39 |
| b12110 | 829,01 | 20,97 |

La candidata procesa esta entrada aproximadamente un 6,6% mas rapido, pero
genera aproximadamente un 6,3% mas lento. Hace falta repetir y probar otros
contextos antes de concluir una regresion. Estos valores no se comparan
directamente con las cifras de octubre, obtenidas con otro modelo.

Evidencia local ignorada por Git: `logs/candidate.stderr.log`,
`logs/candidate-generation.json`, `logs/candidate-tools.json`,
`logs/candidate-benchmark.json` y `logs/baseline-benchmark.json`.

## Fuentes consultadas

- https://github.com/ggml-org/llama.cpp/releases/tag/v0.9.0
- https://github.com/ggml-org/llama.cpp/releases/tag/b12110
- https://rocmdocs.amd.com/en/latest/about/release-notes.html
- https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md

Las opciones MCP, agentes y runtimes de herramientas continuan documentadas
upstream. No se anadieron servicios web ni herramientas externas a esta instalacion.
