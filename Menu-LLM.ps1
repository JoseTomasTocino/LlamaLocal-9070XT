param([switch]$StatusOnly)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
. "$root\Model-Selection.ps1"
$exe = Join-Path $root 'runtime\llama-b11351\llama-server.exe'
$url = 'http://127.0.0.1:8080'
$shell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

function Get-LocalServer {
    @(Get-Process llama-server -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe })
}

function Test-Ready {
    try {
        $health = Invoke-RestMethod "$url/health" -TimeoutSec 2
        return ($health.status -eq 'ok')
    } catch { return $false }
}

function Get-State {
    if (@(Get-LocalServer).Count -eq 0) { return 'APAGADA' }
    if (Test-Ready) { return 'ENCENDIDA - lista para conversar' }
    return 'ARRANCANDO o no responde todavia'
}

function Start-LocalServer {
    if (@(Get-LocalServer).Count -gt 0) {
        Write-Host 'La IA ya esta encendida o arrancando. No se abrira otra copia.'
        return
    }
    $listener = @(Get-NetTCPConnection -State Listen -LocalPort 8080 -ErrorAction SilentlyContinue)
    if ($listener.Count -gt 0) {
        throw 'El puerto 8080 lo ocupa otro programa. No se ha detenido ese programa.'
    }
    New-Item -ItemType Directory -Force (Join-Path $root 'logs') | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outLog = Join-Path $root "logs\menu-$stamp.stdout.log"
    $errLog = Join-Path $root "logs\menu-$stamp.stderr.log"
    $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $root 'Start-LLM.ps1')
    $launcher = Start-Process -FilePath $shell -ArgumentList $arguments -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput $outLog -RedirectStandardError $errLog
    Write-Host 'Cargando el cerebro de la IA. Puede tardar un poco...'
    $deadline = (Get-Date).AddSeconds(120)
    while ((Get-Date) -lt $deadline) {
        if (@(Get-LocalServer).Count -gt 0 -and (Test-Ready)) {
            Write-Host 'IA ENCENDIDA. Abriendo el chat...' -ForegroundColor Green
            Start-Process $url
            return
        }
        $launcher.Refresh()
        if ($launcher.HasExited) {
            if (Test-Path $errLog) { Get-Content $errLog -Tail 12 | Out-Host }
            throw "El arranque fallo. Registro: $errLog"
        }
        Start-Sleep -Seconds 1
    }
    Write-Host 'Sigue cargando. Consulta el estado en unos instantes.' -ForegroundColor Yellow
    Write-Host "Registro: $errLog"
}

function Select-LocalModel {
    $models = @(Get-ChildItem -LiteralPath (Join-Path $root 'models') -Filter '*.gguf' -File |
        Where-Object { $_.Name -notmatch '^mmproj' } | Sort-Object Name)
    if ($models.Count -eq 0) { Write-Host 'No hay modelos GGUF descargados.'; return }
    Write-Host ''
    Write-Host '    MODELOS DISPONIBLES' -ForegroundColor Cyan
    for ($i = 0; $i -lt $models.Count; $i++) {
        Write-Host ('    [{0}] {1} ({2:N2} GiB)' -f ($i + 1), $models[$i].Name, ($models[$i].Length / 1GB))
    }
    Write-Host '    [0] Cancelar'
    $answer = Read-Host '    Elige un modelo'
    if ($answer -eq '0') { return }
    $index = 0
    if (![int]::TryParse($answer, [ref]$index) -or $index -lt 1 -or $index -gt $models.Count) {
        Write-Host 'Numero no valido. La seleccion anterior se mantiene.'
        return
    }
    $models[$index - 1].Name | Set-Content -LiteralPath (Join-Path $root 'selected-model.txt') -Encoding UTF8
    Write-Host ('Seleccion guardada: ' + $models[$index - 1].Name) -ForegroundColor Green
    if (@(Get-LocalServer).Count -gt 0) {
        Write-Host 'La IA actual sigue funcionando. Usa 3 para apagarla y luego 1 para cargar el elegido.' -ForegroundColor Yellow
    } else { Write-Host 'Usa 1 para encender la IA con este modelo.' }
}

if ($StatusOnly) { Write-Output (Get-State); exit 0 }

while ($true) {
    Clear-Host
    Write-Host ''
    Write-Host '  +====================================================+' -ForegroundColor Cyan
    Write-Host '  |           I A   L O C A L   -   Q W E N            |' -ForegroundColor Cyan
    Write-Host '  |                CENTRO DE MANDO                     |' -ForegroundColor Cyan
    Write-Host '  +====================================================+' -ForegroundColor Cyan
    Write-Host ''
    Write-Host ('    ESTADO: ' + (Get-State)) -ForegroundColor Yellow
    try {
        Write-Host ('    PROXIMO ARRANQUE: ' + [IO.Path]::GetFileName((Get-SelectedModelPath)))
        if (@(Get-LocalServer).Count -gt 0 -and (Test-Ready)) {
            $props = Invoke-RestMethod "$url/props" -TimeoutSec 2
            Write-Host ('    EN USO: ' + [IO.Path]::GetFileName($props.model_path))
        }
    } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
    Write-Host ''
    Write-Host '    [1] ENCENDER la IA y abrir el chat'
    Write-Host '    [2] ABRIR el chat en el navegador'
    Write-Host '    [3] APAGAR la IA y liberar memoria'
    Write-Host '    [4] ACTUALIZAR el estado'
    Write-Host '    [5] ABRIR la carpeta de archivos'
    Write-Host '    [6] ELEGIR MODELO para el proximo arranque'
    Write-Host '    [0] SALIR del menu (la IA sigue como este)'
    Write-Host ''
    Write-Host '    Para apagar la IA, usa 3 antes de salir.' -ForegroundColor DarkGray
    Write-Host ''
    $option = Read-Host '    Elige un numero y pulsa ENTER'
    try {
        switch ($option) {
            '1' { Start-LocalServer }
            '2' {
                if (@(Get-LocalServer).Count -gt 0 -and (Test-Ready)) {
                    Start-Process $url
                } else { Write-Host 'La IA no esta lista. Usa 1 para encenderla o espera si esta cargando.' }
            }
            '3' {
                if (@(Get-LocalServer).Count -eq 0) { Write-Host 'La IA ya esta apagada.' }
                else {
                    & (Join-Path $root 'Stop-LLM.ps1')
                    Write-Host 'IA apagada. La memoria se esta liberando.' -ForegroundColor Green
                }
            }
            '4' { continue }
            '5' { Start-Process explorer.exe -ArgumentList ('"{0}"' -f $root) }
            '6' { Select-LocalModel }
            '0' { return }
            default { Write-Host 'Elige una de las opciones del menu.' }
        }
    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
    Write-Host ''
    [void](Read-Host '    Pulsa ENTER para volver al menu')
}
