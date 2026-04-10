@echo off
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%~dp0menu.ps1"

echo.
echo Execucao finalizada. Pressione qualquer tecla para sair...
pause > nul