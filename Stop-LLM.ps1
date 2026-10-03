$expected = "$PSScriptRoot\runtime\llama-b11351\llama-server.exe"
Get-Process llama-server -ErrorAction SilentlyContinue |
    Where-Object Path -EQ $expected | Stop-Process
