# ================================
# TESTE DE REDE
# ================================
function Teste-Rede {
    Clear-Host
    Write-Host "===== TESTE DE REDE =====" -ForegroundColor Cyan
    Write-Host "Aguarde, executando diagnostico..."
    Write-Host ""

    # Teste 1: Conectividade Externa (Ping Google DNS)
    Write-Host "1. Teste de Internet (Ping 8.8.8.8): " -NoNewline
    if (Test-Connection -ComputerName 8.8.8.8 -Count 4 -Quiet -ErrorAction SilentlyContinue) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "FALHOU" -ForegroundColor Red
    }

    # Teste 2: Resolucao de Nomes (DNS)
    Write-Host "2. Teste de DNS (google.com): " -NoNewline
    try {
        $null = Resolve-DnsName -Name google.com -ErrorAction Stop
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "FALHOU" -ForegroundColor Red
    }

    # Teste 3: Portais Institucionais
    Write-Host "`n3. Teste de Portais Institucionais:" -ForegroundColor Yellow
    
    $portais = @(
        @{ Nome = "SIA"; Url = "https://sia.estacio.br/" }
        @{ Nome = "SAVA"; Url = "https://estudante.estacio.br/" }
    )

    foreach ($portal in $portais) {
        Write-Host "   -> $($portal.Nome): " -NoNewline
        try {
            $req = Invoke-WebRequest -Uri $portal.Url -UseBasicParsing -Method Head -TimeoutSec 5 -ErrorAction Stop
            Write-Host "ONLINE ($($req.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "OFFLINE OU INACESSIVEL" -ForegroundColor Red
        }
    }

    # Teste 4: Status da Placa de Rede (IPv4)
    Write-Host "`n4. Informacoes da Interface Ativa:"
    Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -notmatch "Loopback" } | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize

    Write-Host ""
    Pause
}

# ================================
# CORRECAO DE ERROS DO SISTEMA
# ================================
function Sistema-Scan {
    Clear-Host
    Write-Host "===== CORRECAO DO SISTEMA (SFC / DISM) =====" -ForegroundColor Cyan
    Write-Host "ATENCAO: Este processo exige muita CPU/Disco e pode demorar (15-30 min)." -ForegroundColor Yellow
    Write-Host ""
    
    $confirmacao = Read-Host "Deseja iniciar a correcao? (S/N)"
    if ($confirmacao -ne "S") {
        Write-Host "Cancelado."
        return
    }

    Write-Host "`n[1/2] Executando SFC (System File Checker)..."
    sfc /scannow

    Write-Host "`n[2/2] Executando DISM (RestoreHealth)..."
    DISM /Online /Cleanup-Image /RestoreHealth

    Write-Host "`nManutencao de sistema finalizada." -ForegroundColor Green
    Pause
}

# ================================
# CORRECAO DO WINDOWS UPDATE (RESET)
# ================================
function Corrigir-WindowsUpdate {
    Clear-Host
    Write-Host "===== RESET DO WINDOWS UPDATE =====" -ForegroundColor Cyan
    Write-Host "Isso ira parar os servicos, limpar o cache corrompido e reiniciar."
    Write-Host ""

    $confirmacao = Read-Host "Deseja continuar? (S/N)"
    if ($confirmacao -ne "S") {
        Write-Host "Cancelado."
        return
    }

    Write-Host "`nParando servicos do Windows Update..."
    Stop-Service -Name wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue

    Write-Host "Limpando DataStore e Downloads..."
    if (Test-Path "C:\Windows\SoftwareDistribution") {
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\SoftwareDistribution\DataStore\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Iniciando servicos novamente..."
    Start-Service -Name wuauserv, bits, cryptsvc -ErrorAction SilentlyContinue

    Write-Host "`nWindows Update resetado com sucesso." -ForegroundColor Green
    Pause
}

# ================================
# LIMPEZA DE UPDATES ANTIGOS
# ================================
function Limpar-WindowsUpdate {
    Clear-Host
    Write-Host "===== LIMPEZA DE UPDATES =====" -ForegroundColor Cyan
    Write-Host "Remove instaladores antigos. Isso IMPEDIRA o rollback (desinstalacao) de atualizacoes recentes." -ForegroundColor Yellow
    Write-Host ""

    $confirmacao = Read-Host "Deseja continuar? (S/N)"
    if ($confirmacao -ne "S") {
        Write-Host "Cancelado."
        return
    }

    Write-Host "`nLimpando cache de Download..."
    $wuPath = "C:\Windows\SoftwareDistribution\Download\*"
    
    if (Test-Path "C:\Windows\SoftwareDistribution\Download") {
        $itens = Get-ChildItem $wuPath -Recurse -Force -ErrorAction SilentlyContinue
        
        $tamanhoBytes = ($itens | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
        if (-not $tamanhoBytes) { $tamanhoBytes = 0 }
        $tamanhoMB = [math]::Round($tamanhoBytes / 1MB, 2)

        Remove-Item $wuPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Limpeza concluida. Espaco liberado: $tamanhoMB MB" -ForegroundColor Green
    } else {
        Write-Host "Pasta de cache nao encontrada ou ja esta vazia." -ForegroundColor Yellow
    }

    Pause
}

# ================================
# MENU MANUTENCAO
# ================================
function Manutencao {
    while ($true) {
        Clear-Host
        Write-Host "===== MANUTENCAO ====="
        Write-Host "1 - Teste de rede (Ping, DNS, Portais)"
        Write-Host "2 - Correcao de erros do sistema (SFC e DISM)"
        Write-Host "3 - Correcao do Windows Update (Reset total)"
        Write-Host "4 - Limpeza de updates antigos (Libera espaco)"
        Write-Host "0 - Voltar"
        Write-Host ""

        $opcao = Read-Host "Escolha"

        switch ($opcao) {
            "1" { Teste-Rede }
            "2" { Sistema-Scan }
            "3" { Corrigir-WindowsUpdate }
            "4" { Limpar-WindowsUpdate }
            "0" { return }
            default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
        }
    }
}