@echo off
cd /d "%~dp0"
echo ========================================================
echo    GERANDO EXECUTAVEL DE PRODUCAO suporTI-Estacio.exe   
echo ========================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File ".\Gerar-Executavel.ps1"
echo.
pause
