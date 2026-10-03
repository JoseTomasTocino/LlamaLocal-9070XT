# LlamaLocal-9070XT

Scripts para ejecutar modelos GGUF localmente mediante
[llama.cpp](https://github.com/ggml-org/llama.cpp), con un menu sencillo para
arrancar el servidor, abrir el chat, detenerlo y cambiar de modelo.

El proyecto nació para una Radeon RX 9070 XT (`gfx1201`) con 16 GB de VRAM y
32 GB de RAM. La variante principal actual utiliza Ubuntu y ROCm. También se
conservan los scripts originales de Windows como referencia funcional para el
mismo equipo.

## Funcionalidad

- Compilacion fijada a llama.cpp `b11351` (`631109b34`).
- Backend HIP/ROCm para `gfx1201`.
- API compatible con OpenAI en `http://127.0.0.1:8080/v1`.
- Interfaz web local en `http://127.0.0.1:8080`.
- Selector persistente de modelos GGUF.
- Contexto de 16K, Flash Attention y cache K/V Q8_0 de forma predeterminada.
- Autoajuste de capas GPU con 2048 MiB de reserva de VRAM.
- Arranque en segundo plano, comprobacion de salud y parada limitada al proceso
  creado por esta instalacion.

## Estado del proyecto

La instalacion de Ubuntu parte de un sistema que ya dispone de un controlador
AMD y un SDK ROCm funcional. La guia reproducible para preparar Ubuntu desde
cero hasta ese estado se documentara en un paso posterior; no forma parte aun
de este repositorio.

La configuracion se ha desarrollado para `gfx1201`. Otras GPU AMD pueden
requerir cambiar `AMDGPU_TARGETS` en `install-linux.sh` y reajustar memoria,
capas y contexto.

## Contenido del repositorio

| Archivo | Funcion |
|---|---|
| `install-linux.sh` | Descarga y compila llama.cpp con HIP para Linux |
| `ia-local` | Menu interactivo de Linux |
| `start-llm.sh` / `stop-llm.sh` | Arranque y parada directa en Linux |
| `IA-Local.bat` / `Menu-LLM.ps1` | Menu original de Windows |
| `Start-LLM.ps1` / `Stop-LLM.ps1` | Arranque y parada en Windows |
| `Model-Selection.ps1` | Seleccion persistente de modelos en Windows |
| `benchmark.py` / `test-context.py` | Utilidades de prueba |

Los modelos, runtimes compilados, descargas y registros no se versionan. Cada
usuario debe aportarlos localmente.

## Uso en Ubuntu

### Requisitos asumidos

- Linux x86-64 con una GPU AMD compatible.
- Controlador AMD, runtime y SDK ROCm ya instalados y operativos.
- `git`, `cmake`, un compilador C++ y `hipcc` disponibles en `PATH`.
- `curl`, `ss`, `flock`, `setsid` y `xdg-open` para el menu.
- Al menos un modelo GGUF dentro de `models/`.

Para la configuracion original con ROCm 7.14, el instalador comprueba la
presencia de `hip-lang-config.cmake` y, si falta, indica el paquete de
desarrollo esperado. Esto no sustituye la futura guia de instalacion completa
de ROCm.

### Compilar llama.cpp

```bash
git clone https://github.com/JoseTomasTocino/LlamaLocal-9070XT.git
cd LlamaLocal-9070XT
./install-linux.sh
```

El script clona llama.cpp `b11351` dentro de `runtime/`, compila
`llama-server` con HIP para `gfx1201` e intenta incrustar la interfaz web oficial
de esa misma revision. No descarga modelos.

Si la interfaz web no puede descargarse por un problema temporal de red, basta
con ejecutar de nuevo `./install-linux.sh`: la reconstrucción es incremental.

### Añadir modelos

Copia uno o varios archivos `.gguf` dentro del directorio `models/`:

```text
models/
└── mi-modelo.gguf
```

Los modelos quedan ignorados por Git para evitar publicar archivos enormes o
con licencias independientes. El menu permite seleccionar cualquiera de los
GGUF presentes.

### Arrancar

```bash
./ia-local
```

El menu permite encender el servidor, abrir el chat, apagarlo, actualizar el
estado, abrir el directorio y seleccionar el modelo del siguiente arranque.
Salir del menu no detiene el servidor.

También se puede trabajar sin el menu:

```bash
./start-llm.sh
./stop-llm.sh
```

Opciones de arranque disponibles:

```text
--model ARCHIVO
--context N
--gpu-layers N|auto
--vram-reserve-mib N
--port N
```

Ejemplo con mayor reserva de VRAM:

```bash
./start-llm.sh --vram-reserve-mib 5120
```

El servidor solo escucha en `127.0.0.1`; no se expone a la red local ni se
configura una clave API.

## Windows

Los scripts PowerShell y `IA-Local.bat` documentan y conservan la variante
original para Windows 11. Necesitan un paquete binario de llama.cpp con HIP y
sus bibliotecas ROCm dentro de `runtime/llama-b11351`, contenido que no se
incluye en Git.

La preparacion reproducible de ese runtime tampoco se documenta todavía. Los
scripts se mantienen principalmente para conservar las decisiones de diseño y
permitir comparar ambos entornos.

## Configuracion predeterminada

El lanzador de Linux aplica estos valores:

```text
--ctx-size 16384
--device ROCm0
--gpu-layers auto
--fit on
--fit-target 2048
--flash-attn on
--cache-type-k q8_0
--cache-type-v q8_0
--batch-size 512
--ubatch-size 128
--parallel 1
--host 127.0.0.1
--port 8080
```

El autoajuste se realiza al arrancar; no responde dinamicamente a aplicaciones
que empiecen a consumir VRAM despues. Si el escritorio u otros programas usan
mucha memoria de la GPU, conviene aumentar `--vram-reserve-mib` y reiniciar.

## Seguridad y privacidad

- El servidor escucha exclusivamente en loopback.
- No se modifican automáticamente el firewall ni el inicio del sistema.
- Los modelos y conversaciones permanecen en el equipo, salvo que otras
  herramientas utilizadas por el usuario los transmitan.
- Los registros, rutas locales, PID y configuraciones personales estan
  excluidos mediante `.gitignore`.

## Licencia

Los scripts propios de este repositorio se publican bajo la licencia MIT. Consulta
`LICENSE` para ver el texto completo.

llama.cpp, ROCm y cada modelo conservan sus respectivas licencias. La licencia
MIT de este repositorio no modifica ni sustituye las condiciones de esos
proyectos y artefactos externos.
