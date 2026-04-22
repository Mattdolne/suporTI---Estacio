# ================================
# CONFIG
# ================================
$ErrorActionPreference = "Stop"

# ================================
# IMPORTAR MODULOS
# ================================
$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path

# LIMPEZA (obrigatorio)
. "$basePath\funcoes\limpeza.ps1"

# AUDITORIA (opcional)
$auditoriaPath = "$basePath\funcoes\auditoria.ps1"
if (Test-Path $auditoriaPath) {
    . $auditoriaPath
} else {
    Write-Host "Aviso: auditoria.ps1 nao encontrado" -ForegroundColor Yellow
}

# MANUTENCAO (opcional)
$manutencaoPath = "$basePath\funcoes\manutencao.ps1"
if (Test-Path $manutencaoPath) {
    . $manutencaoPath
} else {
    Write-Host "Aviso: manutencao.ps1 nao encontrado" -ForegroundColor Yellow
}

# ================================
# VALIDACAO DE ADMIN
# ================================
function Test-Admin {
    $usuario = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($usuario)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Execute como ADMINISTRADOR" -ForegroundColor Red
    Pause
    exit
}

# ================================
# VALIDAR MODULOS
# ================================
if (-not (Get-Command Limpeza -ErrorAction SilentlyContinue)) {
    Write-Host "Erro: modulo de limpeza nao carregado" -ForegroundColor Red
    Pause
    exit
}

if (-not (Get-Command Auditoria -ErrorAction SilentlyContinue)) {
    Write-Host "Erro: modulo de auditoria nao carregado" -ForegroundColor Red
    Pause
    exit
}

if (-not (Get-Command Manutencao -ErrorAction SilentlyContinue)) {
    Write-Host "Erro: modulo de manutencao nao carregado" -ForegroundColor Red
    Pause
    exit
}

# ================================
# MENU PRINCIPAL
# ================================
function Mostrar-Menu {
    Clear-Host
    Clear-Host
    Write-Host @"
     ____                        _____ ___ 
    / ___| _   _ _ __   ___  _ _|_   _|_ _|
    \___ \| | | | '_ \ / _ \| '__|| |  | | 
     ___) | |_| | |_) | (_) | |   | |  | | 
    |____/ \__,_| .__/ \___/|_|   |_| |___|
                |_|   
                   <Estacio Resende - 2026>
                                     
"@ -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "1 - Limpeza"
    Write-Host "2 - Auditoria"
    Write-Host "3 - Manutencao"
    Write-Host "4 - Sobre"
    Write-Host ""
}

# ================================
# TELA SOBRE
# ================================
function Sobre {
    Clear-Host
    Write-Host "========================================================"
    Write-Host "                         SOBRE                          "
    Write-Host "========================================================"
    Write-Host ""
    
    Write-Host "Desenvolvido por Mattheus Macedo               /\       " -ForegroundColor Cyan
    Write-Host "em Estacio de Sa - Resende                   / || \     " -ForegroundColor Cyan
    Write-Host "Versao: 1.2                                /___||___\   " -ForegroundColor Cyan
    Write-Host "Data da ultima atualizacao: 22/04/2026   /     ||     \ " -ForegroundColor Cyan
    Write-Host "                                        ================" -ForegroundColor Cyan
    Write-Host "                                         \     ||     / " -ForegroundColor Cyan
    Write-Host "                                           \___||___/   " -ForegroundColor Cyan
    Write-Host "Educar para Transformar!                     \ || /     " -ForegroundColor Cyan
    Write-Host "                                               \/       " -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "========================================================"
    Pause
}

# ================================
# LOOP PRINCIPAL
# ================================
$continuar = $true

while ($continuar) {
    Mostrar-Menu

    $opcao = Read-Host "Escolha"

    switch ($opcao) {
        "1" { 
            Limpeza 
        }
        "2" {
            if (Get-Command Auditoria -ErrorAction SilentlyContinue) {
                Auditoria
            } else {
                Write-Host "Auditoria ainda nao implementada" -ForegroundColor Yellow
                Pause
            }
        }
        "3" {
            if (Get-Command Manutencao -ErrorAction SilentlyContinue) {
                Manutencao
            } else {
                Write-Host "Manutencao ainda nao implementada" -ForegroundColor Yellow
                Pause
            }
        }
        "4" {
            Sobre
        
        }
        default { 
            Write-Host "Opcao invalida" -ForegroundColor Yellow
            Pause 
        }
    }
}