# Resultados de Windows — 2 de octubre de 2026

Estas mediciones corresponden a Qwen3.8-27B-UD-Q3_K_XL, llama.cpp b11351 y ROCm 10.0. No son benchmarks de Q4 ni de Linux.

## Perfil de mayor rendimiento (predeterminado actual)

Margen 2048 MiB, 66/66 capas GPU, 16K y Flash Attention. Prueba de 1860 tokens de entrada: 845,77 tokens/s; 128 tokens de salida: 32,31 tokens/s. Evidencia local: `logs/aggressive-benchmark.json` (no versionada).

## Perfil conservador medido (historico)

Contexto 16.384, una sesión, Flash Attention confirmado como enabled, caché K/V Q8_0. El autoajuste de este perfil eligió 56/66 capas según el contador de llama.cpp (55 capas repetidas más salida; el modelo contiene además tensores MTP que no se usan en esta prueba). Pesos GPU: 10.024,42 MiB; pesos CPU mapeados: 2.167,73 MiB. No se activó inferencia visual ni MTP.

El margen de 5.120 MiB compensa que HIP sobreestima la memoria libre frente a los contadores de Windows y que Chrome/escritorio consumieron aproximadamente 3–4 GiB. El autoajuste se realiza al arrancar; no adapta capas en caliente cuando otra aplicación consume VRAM.

| Prueba HIP conservadora | Entrada | Salida | Procesamiento | Generación |
|---|---:|---:|---:|---:|
| Media de 3 pasadas, caché de prompt desactivada | 1.927 tokens | 128 tokens | 487,74 tokens/s | 13,76 tokens/s |
| Contexto largo, sin truncamiento | 15.800 tokens | 128 tokens | 496,48 tokens/s | 11,20 tokens/s |

Las mediciones usan un texto sintético repetido, temperatura 0 y 128 tokens forzados en el benchmark. No son una evaluación de calidad. La comprobación de conversación usa el endpoint OpenAI y un prompt separado.

Picos de memoria observados por contadores Windows durante las pruebas finales:

| Medida | Pico |
|---|---:|
| VRAM dedicada del proceso | 11.129,30 MiB / 10,87 GiB |
| Memoria GPU compartida del proceso | 95,07 MiB |
| VRAM dedicada total del sistema | 14.570,27 MiB / 14,23 GiB |
| RAM residente del servidor (working set) | 13.274,88 MiB / 12,96 GiB |
| Memoria privada del servidor | 12.283,57 MiB / 11,995 GiB |
| RAM física usada por todo el sistema | 28.850,28 MiB / 28,17 GiB |

La memoria compartida GPU estuvo entre 91,07 y 95,07 MiB, sin crecimiento sostenido en estas pruebas. Esto no prueba ausencia de cualquier evento de paginación del driver; se evitó la saturación observada en las configuraciones más agresivas. La RAM del proceso incluye mapeos y asignaciones del runtime y no equivale únicamente a los pesos de las capas CPU. Las categorías de memoria no deben sumarse entre sí.

## Rendimiento con más VRAM libre

También se midieron estos perfiles durante el ajuste:

- Máximo offload con margen de 2.048 MiB: alrededor de 910 tokens/s de entrada y 33,8 tokens/s de generación, pero margen insuficiente con las aplicaciones abiertas; se descartó como configuración predeterminada.
- 62 capas, margen de 4.096 MiB: 664 tokens/s de entrada y 22 tokens/s de generación; picos de VRAM total de 16.071,84 MiB, demasiado cerca del límite.

Tras cerrar voluntariamente aplicaciones que usan GPU, se puede parar y reiniciar con `-VramReserveMiB 2048`. El autoajuste intentará aumentar las capas. Volver a medir memoria, especialmente si se abren juegos u otras aplicaciones GPU. No se garantiza el rendimiento del perfil agresivo con la carga actual del escritorio.

Para ampliar contexto, usar `-Context 32768` manteniendo inicialmente el margen. No se ha probado 32K; debe volver a verificarse memoria y estabilidad.

ROCm/HIP ha funcionado en todas las pruebas. No fue necesario recurrir a Vulkan y no hay una comparación HIP/Vulkan medida.

