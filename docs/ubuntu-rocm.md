# Preparar Ubuntu y ROCm para una Radeon RX 9070 XT

Esta guia deja un Ubuntu recién instalado en el estado previo a ejecutar
`install-linux.sh`: controlador AMD operativo, ROCm y SDK HIP disponibles para
compilar llama.cpp.

La receta reproduce la configuracion comprobada en este proyecto el 4 de
octubre de 2026. Esta deliberadamente fijada a estas versiones:

| Componente | Version comprobada |
|---|---|
| Ubuntu | 26.04.1 LTS (`resolute`) |
| Kernel | `7.0.0-34-generic` |
| GPU | Radeon RX 9070 XT, PCI ID `1002:7550` |
| Arquitectura GPU | `gfx1201` |
| AMDGPU | paquete instalador 31.40.1, DKMS 6.19.14 |
| ROCm | 10.0.0-4, paquete para `gfx1201` |

AMD publica versiones nuevas con frecuencia. No mezcles repositorios o
paquetes de distintas versiones sin comprobar antes las matrices de
compatibilidad. Para otro Ubuntu, kernel o GPU, consulta la documentacion
oficial enlazada al final en lugar de copiar los comandos literalmente.

## 1. Comprobar el sistema de partida

Los comandos siguientes no modifican nada:

```bash
cat /etc/os-release
uname -r
lspci -nnk | grep -A 4 -Ei 'vga|display|3d'
```

Para esta receta se espera Ubuntu 26.04 x86-64 y una RX 9070 XT. El dispositivo
puede aparecer inicialmente con el controlador `amdgpu` incluido en Ubuntu;
los pasos siguientes instalan el conjunto AMD que se uso durante las pruebas.

Actualiza el sistema antes de instalar el controlador:

```bash
sudo apt update
sudo apt full-upgrade
sudo reboot
```

Después del reinicio instala las herramientas necesarias:

```bash
sudo apt install \
  build-essential ca-certificates cmake curl git gnupg pciutils wget \
  "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"
```

## 2. Instalar el repositorio y controlador AMDGPU

Descarga el instalador oficial fijado a 31.40.1 para Ubuntu 26.04:

```bash
wget -P /tmp \
  https://repo.radeon.com/amdgpu-install/31.40.1/ubuntu/resolute/amdgpu-install_31.40.1.314001-1_all.deb
sudo apt install /tmp/amdgpu-install_31.40.1.314001-1_all.deb
sudo apt update
```

Instala el controlador de kernel y las bibliotecas graficas de AMD:

```bash
sudo apt install amdgpu-dkms amdgpu-lib
sudo reboot
```

Si Secure Boot esta activado, Ubuntu puede solicitar la creacion y posterior
confirmacion de una clave MOK para cargar el modulo DKMS. No desactives Secure
Boot ni aceptes cambios de firmware a ciegas: sigue el flujo que muestre
Ubuntu y comprueba el modulo despues del reinicio.

Verifica que la GPU utiliza `amdgpu`:

```bash
lspci -nnk | grep -A 4 -Ei 'vga|display|3d'
lsmod | grep '^amdgpu'
```

## 3. Registrar el repositorio ROCm 10

Instala la clave oficial del repositorio estable de ROCm:

```bash
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
curl -fsSL https://stable.repo.amd.com/rocm/gpg/packages.gpg | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/amdrocm-stable.gpg >/dev/null
```

Añade el repositorio de Ubuntu 26.04 en un archivo independiente. Se usa un
nombre propio para no sobrescribir los repositorios creados por
`amdgpu-install`:

```bash
sudo tee /etc/apt/sources.list.d/amdrocm-stable.sources >/dev/null <<'EOF'
X-Repo-Id: amdrocm-stable
Types: deb
URIs: https://stable.repo.amd.com/rocm/core/packages/ubuntu2604/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/amdrocm-stable.gpg
Enabled: yes
EOF
sudo apt update
```

Antes de instalar, comprueba que APT ofrece la serie esperada:

```bash
apt-cache policy amdrocm-core-dev10.0-gfx1201
```

## 4. Instalar ROCm y el SDK para `gfx1201`

El metapaquete de desarrollo instala el runtime optimizado para la RX 9070 XT,
ademas de las cabeceras, archivos CMake y compiladores necesarios para
construir llama.cpp:

```bash
sudo apt install amdrocm-core-dev10.0-gfx1201
```

No hace falta instalar PyTorch, TensorFlow ni otro framework para este
proyecto.

## 5. Dar acceso a la GPU al usuario

Añade el usuario que ejecutara llama.cpp a los grupos de dispositivos AMD:

```bash
sudo usermod -aG render,video "$USER"
sudo reboot
```

Es necesario cerrar completamente la sesion o reiniciar para que la nueva
pertenencia a grupos tenga efecto.

## 6. Verificacion final

Tras el reinicio, ejecuta:

```bash
id
ls -l /dev/kfd /dev/dri/renderD*
rocminfo | grep -E 'Marketing Name|gfx1201'
rocm-smi --showproductname --showmeminfo vram
hipcc --version
test -f /opt/rocm/lib/cmake/hip-lang/hip-lang-config.cmake && \
  echo 'SDK ROCm preparado'
```

El estado correcto debe cumplir todo lo siguiente:

- `lspci -nnk` muestra `Kernel driver in use: amdgpu`.
- Existen `/dev/kfd` y al menos un dispositivo `/dev/dri/renderD*`.
- El usuario pertenece a `render` y `video`.
- `rocminfo` identifica `gfx1201`.
- `rocm-smi` muestra aproximadamente 16 GB de VRAM.
- `hipcc` responde y existe `hip-lang-config.cmake`.

Si `/dev/kfd` no existe, no continúes con llama.cpp: revisa primero que el
modulo se haya cargado, que el kernel coincida con sus cabeceras y que Secure
Boot no haya rechazado el modulo DKMS.

## 7. Continuar con LlamaLocal-9070XT

Con el sistema preparado, sigue la instalacion normal del repositorio:

```bash
git clone https://github.com/JoseTomasTocino/LlamaLocal-9070XT.git
cd LlamaLocal-9070XT
./install-linux.sh
```

Después coloca uno o más modelos GGUF en `models/` y abre el menu:

```bash
./ia-local
```

## Solucion de problemas rapida

### `hip-lang-config.cmake` no aparece

Falta el SDK de desarrollo:

```bash
sudo apt install amdrocm-core-dev10.0-gfx1201
```

### El usuario no tiene permiso para `/dev/kfd`

Comprueba grupos y permisos:

```bash
id
getent group render
getent group video
ls -l /dev/kfd /dev/dri/renderD*
```

Si acabas de ejecutar `usermod`, reinicia la sesion o el equipo.

### Hay paquetes AMD de versiones mezcladas

Comprueba sus candidatos antes de actualizar o reinstalar:

```bash
apt-cache policy amdgpu-install amdgpu-dkms amdrocm-core-dev10.0-gfx1201
dpkg-query -W 'amdgpu*' 'amdrocm*' 2>/dev/null
```

No fuerces una degradacion ni purgues el controlador desde una sesion grafica
sin consultar antes las instrucciones oficiales de desinstalacion y
recuperacion.

## Fuentes oficiales

- [Instalacion actual de ROCm en Linux](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/install-methods/package-manager/package-manager-ubuntu.html)
- [Paquete AMDGPU 31.40.1 para Ubuntu 26.04](https://repo.radeon.com/amdgpu-install/31.40.1/ubuntu/resolute/)
- [Repositorio AMDGPU 31.40.1](https://repo.radeon.com/amdgpu/31.40.1/ubuntu/)
- [Compatibilidad de Radeon con ROCm](https://rocm.docs.amd.com/projects/radeon/en/latest/docs/compatibility.html)

La guia fija los nombres de paquete y repositorio que se comprobaron en este
equipo. Consulta las fuentes antes de aplicar la receta a otra version de
Ubuntu, otro kernel o una GPU diferente.
