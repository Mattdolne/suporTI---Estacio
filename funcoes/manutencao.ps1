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
        @{ Nome = "ADP"; Url = "https://expert.cloud.brasil.adp.com/expert2/v5/" }
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

    Write-Host "`n[2/2] Executando reparos..."
    Repair-WindowsImage -Online -RestoreHealth

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Reparo concluído com sucesso!" -ForegroundColor Green
        } else {
            Write-Error "O reparo falhou com código: $($LASTEXITCODE.ExitCode)"
        } 

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
# LISTAR USUÁRIOS LOCAIS
# ================================
function ListarUsuarioLocal {
    Write-Host "Listando usuários locais cadastrados nesta estação: " -ForegroundColor Cyan
    
    Get-LocalUser | Select-Object Name, Enabled, LastLogon, Description | Format-Table -AutoSize

    Write-Host ""
    Pause
}

# ================================
# REINICIAR ADAPTADOR DE REDE
# ================================
function Reiniciar-AdaptadorRede {
    Clear-Host
    Write-Host "===== REINICIAR ADAPTADOR DE REDE =====" -ForegroundColor Cyan
    
    # 1. Busca todos os adaptadores ativos (Up)
    $adaptadores = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    if ($adaptadores.Count -eq 0) {
        Write-Host "Nenhum adaptador de rede ativo encontrado." -ForegroundColor Red
        Pause
        return
    }

    # 2. Lista os adaptadores com um índice numérico
    Write-Host "Selecione o adaptador para reiniciar:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $adaptadores.Count; $i++) {
        Write-Host "[$i] $($adaptadores[$i].Name) - $($adaptadores[$i].InterfaceDescription)"
    }
    Write-Host "[S] Sair" -ForegroundColor Gray

    # 3. Captura a escolha do usuário
    $escolha = Read-Host "`nDigite o número da opção"

    if ($escolha -eq "S") { return }

    # 4. Valida se o número digitado é válido
    if ($escolha -ge 0 -and $escolha -lt $adaptadores.Count) {
        $adaptadorSelecionado = $adaptadores[$escolha]
        
        Write-Host "`nReiniciando $($adaptadorSelecionado.Name)..." -ForegroundColor Yellow
        
        # O processo de desligar e ligar a interface
        Disable-NetAdapter -Name $adaptadorSelecionado.Name -Confirm:$false
        Start-Sleep -Seconds 2 # Pequena pausa para garantir que o sistema processou o comando
        Enable-NetAdapter -Name $adaptadorSelecionado.Name -Confirm:$false
        
        Write-Host "Adaptador reiniciado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "Opção inválida!" -ForegroundColor Red
    }
    Pause
}

# ================================
# ATIVAR WINDOWS
# ================================
# ================================
# ATIVAÇÃO DO WINDOWS
# ================================
function Ativar-Windows {
    Clear-Host
    Write-Host "===== ATIVAÇÃO DO WINDOWS =====" -ForegroundColor Cyan
    Write-Host "Este processo pode levar alguns segundos..." -ForegroundColor Yellow
    Write-Host ""

    $confirmacao = Read-Host "Deseja prosseguir com a troca da chave de ativacao? (S/N)"
    if ($confirmacao -ne "S") {
        Write-Host "Cancelado."
        return
    }

    # Caminho do slmgr
    $slmgr = "$env:windir\System32\slmgr.vbs"

    Write-Host "`n[1/3] Desinstalando a chave atual (/upk)..."
    cscript.exe //nologo $slmgr /upk | Out-Null

    Write-Host "[2/3] Instalando a nova chave (/ipk)..."
    cscript.exe //nologo $slmgr /ipk "9NK44-QF26M-G9WX2-VJJVH-7QWXM" | Out-Null

    Write-Host "[3/3] Solicitando ativacao nos servidores da Microsoft (/ato)..."
    # Aqui não usamos Out-Null para que você possa ver a resposta do servidor (se deu certo ou falhou)
    $resultado = cscript.exe //nologo $slmgr /ato
    Write-Host $resultado -ForegroundColor Green

    Write-Host "`nProcesso de ativacao finalizado." -ForegroundColor Cyan
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
        Write-Host "5 - Listar contas de usuário local"
        Write-Host "6 - Reiniciar adaptador de rede"
        Write-Host "7 - Ativar Windows"
        Write-Host "0 - Voltar"
        Write-Host ""

        $opcao = Read-Host "Escolha"

        switch ($opcao) {
            "1" { Teste-Rede }
            "2" { Sistema-Scan }
            "3" { Corrigir-WindowsUpdate }
            "4" { Limpar-WindowsUpdate }
            "5" { ListarUsuarioLocal }
            "6" { Reiniciar-AdaptadorRede }
            "7" { Ativar-Windows }
            "0" { return }
            default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
        }
    }
}