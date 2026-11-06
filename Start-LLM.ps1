param(
    [string]$Model = '',
    [int]$Context = 16384,
    [string]$GpuLayers = 'auto',
    [int]$VramReserveMiB = 2048,
    [int]$Port = 8080,
    [ValidatePattern('^b[0-9]+$')][string]$RuntimeVersion = 'b12110',
    [ValidateSet('10.0','10.1')][string]$RocmVersion = '10.1'
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Model-Selection.ps1"
if (!$Model) { $Model = Get-SelectedModelPath }
if (!(Test-Path -LiteralPath $Model -PathType Leaf)) {
    throw "No se encuentra el modelo: $Model. Elige otro en la opcion 6 del menu."
}
$venv = if ($RocmVersion -eq '10.1') { '.venv-rocm101' } else { '.venv' }
$suffix = if ($RocmVersion -eq '10.1') { '-rocm101' } else { '' }
$server = "$PSScriptRoot\runtime\llama-$RuntimeVersion$suffix\llama-server.exe"
if (!(Test-Path -LiteralPath $server)) { throw "Falta el runtime solicitado: $server" }
$env:PATH = "$PSScriptRoot\$venv\Lib\site-packages\_rocm_sdk_core\bin;$PSScriptRoot\$venv\Lib\site-packages\_rocm_sdk_libraries\bin;$env:PATH"
$env:HIP_VISIBLE_DEVICES = '0'
& $server `
    --model $Model --alias qwen3.8-27b --ctx-size $Context `
    --device ROCm0 --gpu-layers $GpuLayers --fit on --fit-target $VramReserveMiB `
    --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 `
    --batch-size 512 --ubatch-size 128 --parallel 1 `
    --host 127.0.0.1 --port $Port --verbosity 4 --agent
exit $LASTEXITCODE
