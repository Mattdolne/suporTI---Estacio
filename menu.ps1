# ================================
# CONFIG
# ================================
$ErrorActionPreference = "Stop"

# ================================
# IMPORTAR MODULOS
# ================================
$basePath = Split-Path -Parent $MyInvocation.MyCommand.Path

# LIMPEZA 
$limpezaPath = "$basePath\funcoes\limpeza.ps1"
if (Test-Path $limpezaPath) {
    . $limpezaPath
} else {
    Write-Host "Aviso: limpeza.ps1 nao encontrado" -ForegroundColor Yellow
}

# AUDITORIA 
$auditoriaPath = "$basePath\funcoes\auditoria.ps1"
if (Test-Path $auditoriaPath) {
    . $auditoriaPath
} else {
    Write-Host "Aviso: auditoria.ps1 nao encontrado" -ForegroundColor Yellow
}

# MANUTENCAO 
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

    $opcao = Read-Host "Selecionar modulo"

    try {
        switch ($opcao) {
            "1" { Limpeza }
            "2" { Auditoria }
            "3" { Manutencao }
            "4" { Sobre }
            
            default { 
                Write-Host "Opcao invalida" -ForegroundColor Yellow
                Pause 
            }
        }
    } catch {
        Write-Host "`n[ERRO INESPERADO] O programa principal encontrou um problema." -ForegroundColor Red
        Write-Host "Detalhes: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.InvocationInfo) {
            Write-Host "Origem: $($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkGray
        }
        Pause
    }
}