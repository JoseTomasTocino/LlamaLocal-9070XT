# Windows: instalacion local y uso

## Selector de modelos (menu BAT)

La opcion **6** de `IA-Local.bat` lista los archivos `.gguf` de `models`, muestra su tamano y guarda el elegido en `selected-model.txt`. `Model-Selection.ps1` es el ayudante compartido por el menu y el arranque; conservarlo junto a los otros scripts. La pantalla distingue el modelo seleccionado para el proximo arranque del modelo actualmente en uso.

Para cambiar: **6 -> elegir modelo -> 3 (apagar si estaba encendida) -> 1 (encender)**. Elegir no interrumpe una conversacion ni arranca dos modelos a la vez. El arranque conserva el contexto 16K, HIP, Flash Attention y ajuste automatico de capas. Pasar `-Model` explicitamente al script sigue teniendo prioridad sobre la seleccion guardada.

Q4 solicitado: `models/Qwen3.8-27B-UD-Q4_K_M.gguf` (15,33 GiB). Su descarga e integridad se registran en `logs/model-q4-manifest.json` y `logs/model-q4-sha256.txt`. Las instrucciones historicas de descarga Q4 que aparecen mas abajo solo hacen falta si se elimina el archivo.

## Perfil actual: mayor rendimiento

Actualizado a peticion del usuario: `Start-LLM.ps1` y el menu BAT usan ahora `VramReserveMiB = 2048`, en lugar de 5120. Reiniciado y verificado: **66/66 capas GPU**, Flash Attention activado y contexto 16K. Prueba posterior al cambio: 1.860 tokens de entrada a **845,77 tokens/s** y 128 de salida a **32,31 tokens/s** (`logs/aggressive-benchmark.json`). El ajuste de capas ocurre al arrancar, no continuamente. Para volver al perfil anterior, iniciar con `-VramReserveMiB 5120`.

El arranque usa actualmente un margen de 2048 MiB. Los resultados de los perfiles anteriores se conservan en [resultados de Windows](resultados-windows.md). Las mediciones son del 2 de octubre de 2026, no comprobaciones actuales de rendimiento.

Instalado y verificado el 2 de octubre de 2026 en Windows 11 Pro 26200, Ryzen 7 9700X, 32 GB DDR5-6000 y RX 9070 XT de 16 GB. Driver conservado: AMD Software 26.8.1 / 32.0.31041.1004.

## Instalación

- llama.cpp oficial b11351 (identificador comunicado por el ejecutable: b11351-631109b34), backend HIP/ROCm.
- ROCm 10.0.0 estable, bibliotecas y paquete específico gfx1201 instalados en `.venv`. No se instalaron PyTorch ni aplicaciones alternativas.
- Runtime aislado del ROCm 7.0/7.1 privado de AMD Chat; PATH modificado únicamente para el proceso del servidor.
- Se usó el binario oficial: detecta RDNA4 y ejecuta correctamente Flash Attention. No había una necesidad demostrada de compilar ni de instalar otro SDK de desarrollo.
- Hugging Face CLI 2.1.1 en `.venv`.
- Modelo Q3 descargado: `unsloth/Qwen3.8-27B-GGUF`, `Qwen3.8-27B-UD-Q3_K_XL.gguf`, revisión `4ca720788d1e01f1bff70c033e0d0028fd02e502`.
- Tamaño del modelo: 13.146.393.504 bytes (12,24 GiB). Es una cuantización dinámica de Unsloth; no tiene el mismo tamaño que otros Q3_K_XL.
- SHA-256 verificado: `8c2a45ff85e7674ca185ec8eb6cdeab0e617ed9d8018caed0b64380eb2a67a5e`.
- ZIP oficial verificado: `2075d0fc178564ca2b78ad8d1dd45beca2ba56a74170c9dd8dd0616eed27aa5b`.

## Arranque y parada

Para uso diario, hacer doble clic en **IA-Local.bat**. Su menu permite encender y abrir el chat (1), abrir el chat (2), apagar (3), actualizar estado (4), abrir la carpeta (5) o salir (0). Salir del menu no apaga la IA. El arranque se realiza en segundo plano y guarda registros en `logs/menu-*.log`. `Menu-LLM.ps1` es el ayudante del menu: debe permanecer junto al BAT. Usa Windows PowerShell incluido en Windows, sin instalar programas ni cambiar la politica de ejecucion del sistema.

El menu muestra si el servidor esta encendido. No ejecutar otro en el mismo puerto. El script actual incluye `--agent`: habilita herramientas de archivos y terminal con los permisos del proceso, sin aislamiento automatico de carpetas. No incluye por si solo un buscador web.

```powershell
pwsh -NoProfile -File "C:\Users\Jose\Documents\ChatGPT\IA local\Start-LLM.ps1"
```

Ejemplo equivalente para Q3; el menu utiliza el modelo guardado en el selector. El script configura ademas el PATH local de ROCm:

```powershell
& "C:\Users\Jose\Documents\ChatGPT\IA local\runtime\llama-b11351\llama-server.exe" --model "C:\Users\Jose\Documents\ChatGPT\IA local\models\Qwen3.8-27B-UD-Q3_K_XL.gguf" --alias qwen3.8-27b --ctx-size 16384 --device ROCm0 --gpu-layers auto --fit on --fit-target 2048 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 128 --parallel 1 --host 127.0.0.1 --port 8080 --verbosity 4 --agent
```

Parar únicamente los servidores de esta instalación:

```powershell
pwsh -NoProfile -File "C:\Users\Jose\Documents\ChatGPT\IA local\Stop-LLM.ps1"
```

Las rutas absolutas de los ejemplos corresponden al equipo original; adaptarlas si la carpeta cambia. Esta guia describe la instalacion comprobada y no es todavia un instalador automatizado de Windows.

API OpenAI: http://127.0.0.1:8080/v1

Interfaz web: http://127.0.0.1:8080

Prueba comprobada con curl de Windows:

```powershell
curl.exe --fail http://127.0.0.1:8080/v1/chat/completions -H "Content-Type: application/json" --data-binary "@C:\Users\Jose\Documents\ChatGPT\IA local\test-request.json"
```

Devuelve 391 para 17 por 23. El JSON desactiva thinking para esta prueba corta. No hay clave API; escucha solo en loopback. No se modificó el firewall ni se configuró inicio automático.

## Resultados y limites

Consulta [las mediciones de Windows](resultados-windows.md) para comparar los perfiles y ver consumo de RAM/VRAM. No hay medidas equivalentes de Q4 ni una comparacion con Vulkan.

## Cambiar a Q4_K_M

Q4 ya esta descargado y su SHA-256 fue verificado en esta instalacion. Archivo: `Qwen3.8-27B-UD-Q4_K_M.gguf`, 16.464.440.224 bytes (15,33 GiB); requiere margen adicional para cachés y probablemente más offload CPU.

Para esta instalacion basta con elegir Q4 en la opcion 6 del menu y reiniciar. Los siguientes comandos de descarga solo son necesarios en una instalacion nueva o si se elimina el archivo:

```powershell
Set-Location "C:\Users\Jose\Documents\ChatGPT\IA local"
.\Stop-LLM.ps1
.\.venv\Scripts\hf.exe download unsloth/Qwen3.8-27B-GGUF Qwen3.8-27B-UD-Q4_K_M.gguf --revision 4ca720788d1e01f1bff70c033e0d0028fd02e502 --local-dir models
.\Start-LLM.ps1 -Model "C:\Users\Jose\Documents\ChatGPT\IA local\models\Qwen3.8-27B-UD-Q4_K_M.gguf"
```

Conserva 16K y autoajuste. Vigilar también los 32 GB de RAM; durante la prueba Q3 quedó poco margen de RAM física con las otras aplicaciones abiertas. La velocidad Q4 no se ha medido.

## Evidencia y fuentes

Registros en `logs`: `server-final.stderr.log`, `memory.csv`, `memory-summary.json`, `benchmark-1.json` a `benchmark-3.json`, `context-16k.json`, `basic-generation.json`, `curl-test.json`, checksums y listado de paquetes. Las pasadas anteriores tienen prefijos `initial-` y `62layers-`.

- https://github.com/ggml-org/llama.cpp/releases/tag/b11351
- https://rocmdocs.amd.com/en/latest/install/rocm.html
- https://rocm.docs.amd.com/projects/ai-ecosystem/en/latest/inference/llamacpp.html
- https://huggingface.co/unsloth/Qwen3.8-27B-GGUF

No se cambiaron BIOS, drivers, configuración global de Windows ni bibliotecas de AMD Chat.
