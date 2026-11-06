$expected = @(
    "$PSScriptRoot\runtime\llama-b11351\llama-server.exe",
    "$PSScriptRoot\runtime\llama-b12110\llama-server.exe",
    "$PSScriptRoot\runtime\llama-b12110-rocm101\llama-server.exe"
)
Get-Process llama-server -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -in $expected } | Stop-Process
