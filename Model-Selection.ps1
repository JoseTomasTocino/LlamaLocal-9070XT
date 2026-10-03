function Get-SelectedModelPath {
    $selectionFile = Join-Path $PSScriptRoot 'selected-model.txt'
    $name = 'Qwen3.8-27B-UD-Q3_K_XL.gguf'
    if (Test-Path -LiteralPath $selectionFile) {
        $name = (Get-Content -LiteralPath $selectionFile -Raw -Encoding UTF8).Trim()
    }
    if (!$name -or [IO.Path]::GetFileName($name) -ne $name -or $name -notlike '*.gguf') {
        throw 'La seleccion de modelo no es valida. Vuelve a elegirlo en el menu.'
    }
    Join-Path (Join-Path $PSScriptRoot 'models') $name
}
