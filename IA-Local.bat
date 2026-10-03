@echo off
setlocal
title IA LOCAL - Centro de mando
cd /d "%~dp0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Menu-LLM.ps1"
if errorlevel 1 (
    echo.
    echo No se pudo abrir el menu. Copia el error que aparece arriba.
    pause
)
endlocal
