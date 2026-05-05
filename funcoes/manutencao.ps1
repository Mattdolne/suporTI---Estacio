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
            Write-Host "Reparo concluido com sucesso!" -ForegroundColor Green
        } else {
            Write-Error "O reparo falhou com codigo: $($LASTEXITCODE.ExitCode)"
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
# RESET DE SENHA DE USUARIO LOCAL
# ================================
function Resetar-SenhaUsuario {
    Clear-Host
    Write-Host "====== RESET DE SENHA LOCAL ======" -ForegroundColor Cyan
    Write-Host "Altera a senha de qualquer usuario sem precisar da senha atual.`n" -ForegroundColor Yellow

    # Lista os usuarios existentes para facilitar a escolha
    Write-Host "Usuarios locais disponiveis:" -ForegroundColor Gray
    Get-LocalUser | Select-Object Name, FullName, Enabled | Format-Table -AutoSize

    $nomeUsuario = Read-Host "Digite o nome exato do usuario (ou '0' para cancelar)"

    if ($nomeUsuario -eq "0" -or [string]::IsNullOrWhiteSpace($nomeUsuario)) {
        Write-Host "Operacao cancelada." -ForegroundColor Gray
        return
    }

    # O parametro -AsSecureString oculta a senha enquanto voce digita (mostra asteriscos)
    $novaSenha = Read-Host "Digite a NOVA senha para o usuario '$nomeUsuario'" -AsSecureString

    Write-Host "`nAplicando nova senha..." -ForegroundColor Yellow

    try {
        # O Set-LocalUser exige que a senha seja passada como SecureString, o que ja fizemos acima
        Set-LocalUser -Name $nomeUsuario -Password $novaSenha -ErrorAction Stop

        Write-Host "[OK] Senha alterada com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "[ERRO] Nao foi possivel alterar a senha." -ForegroundColor Red
        Write-Host "Motivo: $_" -ForegroundColor DarkGray
    }

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

    # 2. Lista os adaptadores com um indice numerico
    Write-Host "Selecione o adaptador para reiniciar:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $adaptadores.Count; $i++) {
        Write-Host "[$i] $($adaptadores[$i].Name) - $($adaptadores[$i].InterfaceDescription)"
    }
    Write-Host "[S] Sair" -ForegroundColor Gray

    # 3. Captura a escolha do usuario
    $escolha = Read-Host "`nDigite o numero da opcao"

    if ($escolha -eq "S") { return }

    # 4. Valida se o numero digitado e valido
    if ($escolha -ge 0 -and $escolha -lt $adaptadores.Count) {
        $adaptadorSelecionado = $adaptadores[$escolha]

        Write-Host "`nReiniciando $($adaptadorSelecionado.Name)..." -ForegroundColor Yellow

        # O processo de desligar e ligar a interface
        Disable-NetAdapter -Name $adaptadorSelecionado.Name -Confirm:$false
        Start-Sleep -Seconds 2 # Pequena pausa para garantir que o sistema processou o comando
        Enable-NetAdapter -Name $adaptadorSelecionado.Name -Confirm:$false

        Write-Host "Adaptador reiniciado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "Opcao invalida!" -ForegroundColor Red
    }
    Pause
}

# ================================
# VERIFICACAO DE ERROS NO DISCO
# ================================
function Verificar-Disco {
    while ($true) {
        Clear-Host
        Write-Host "===== VERIFICACAO DE DISCO (CHKDSK) =====" -ForegroundColor Cyan
        Write-Host "Identifica e corrige setores defeituosos e erros no sistema de arquivos."
        Write-Host ""
        Write-Host "1 - Verificacao rapida (Somente leitura, nao reinicia a maquina)"
        Write-Host "2 - Agendar correcao profunda (Exige reiniciar a maquina)"
        Write-Host "0 - Voltar"
        Write-Host ""

        $opcaoDisco = Read-Host "Escolha"

        switch ($opcaoDisco) {
            "1" {
                Write-Host "`nExecutando leitura do disco C:... (Isso pode levar alguns minutos)" -ForegroundColor Yellow
                chkdsk C:
                Write-Host "`nVerificacao rapida concluida!" -ForegroundColor Green
                Pause
            }
            "2" {
                Write-Host "`nAgendando correcao profunda para o disco C:..." -ForegroundColor Yellow
                Write-Host "O processo ira corrigir erros e recuperar setores defeituosos no proximo boot." -ForegroundColor Red
                Write-Host ""

                # O comando "echo y" responde "Sim" automaticamente quando o chkdsk pergunta se quer agendar
                cmd.exe /c "echo y | chkdsk C: /f /r"

                Write-Host "`nAgendamento concluido. Reinicie a maquina para iniciar o reparo." -ForegroundColor Green
                Pause
            }
            "0" { return }
            default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
        }
    }
}

# ================================
# FORCAR GPOs E TESTE DE DOMINIO
# ================================
function Atualizar-GPOs {
    Clear-Host
    Write-Host "====== ATUALIZAR E VERIFICAR POLITICAS DE GRUPO (GPO) ======" -ForegroundColor Cyan

    Write-Host "`n[1/2] Iniciando atualizacao de GPOs..." -ForegroundColor Yellow
    gpupdate /force

    Write-Host "`n[2/2] Testando relacao de confianca com o dominio..." -ForegroundColor Yellow

    try {
        # O -ErrorAction Stop forca qualquer aviso a cair no bloco catch abaixo
        $statusDominio = Test-ComputerSecureChannel -ErrorAction Stop

        if ($statusDominio) {
            Write-Host "Status: CONECTADO e CONFIAVEL (True)" -ForegroundColor Green
        } else {
            Write-Host "Status: FALHA NA CONFIANCA (False)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erro: Nao foi possivel testar o dominio (A maquina nao esta no dominio ou esta sem rede)." -ForegroundColor DarkGray
    }

    Write-Host "`nAtualizacoes e testes concluidos!" -ForegroundColor Green
    Pause
}

# ================================
# INSTALAR RSAT
# ================================
function Instalar-RSAT {
    Clear-Host
    Write-Host "====== INSTALACAO DE FERRAMENTAS RSAT ======" -ForegroundColor Cyan
    Write-Host "Verificando pre-requisitos do sistema...`n" -ForegroundColor Yellow

    $computador = Get-WmiObject -Class Win32_ComputerSystem

    if (-not $computador.PartOfDomain) {
        Write-Host "Esta maquina nao esta operando em dominio!`n" -ForegroundColor Red
        Write-Host "O RSAT so pode ser instalado em maquinas dentro do dominio - CORP ou ACAD`n" -ForegroundColor Red
        Pause
        return  
    }

    Write-Host "`nInstalando o RSAT..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -ErrorAction SilentlyContinue
    Write-Host "`nGerenciamento de GPO..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0" -ErrorAction SilentlyContinue

    Write-Host "`nInstalacao concluida! Verifique o Menu Iniciar em 'Ferramentas Administrativas'." -ForegroundColor Green
    Write-Host "`nSe nao encontrar o gerenciador de servidores, reinicie a maquina e procure novamente." -ForegroundColor Green
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
        Write-Host "5 - Alterar senha de contas de usuario local"
        Write-Host "6 - Reiniciar adaptador de rede"
        Write-Host "7 - Verificacao e correcao de erros de disco"
        Write-Host "8 - Atualizar politicas de grupo - GPOs"
        Write-Host "9 - Instalar RSAT"
        Write-Host "0 - Voltar"
        Write-Host ""

        $opcao = Read-Host "Escolha"

        try {
            switch ($opcao) {
                "1" { Teste-Rede }
                "2" { Sistema-Scan }
                "3" { Corrigir-WindowsUpdate }
                "4" { Limpar-WindowsUpdate }
                "5" { Resetar-SenhaUsuario }
                "6" { Reiniciar-AdaptadorRede }
                "7" { Verificar-Disco }
                "8" { Atualizar-GPOs }
                "9" { Instalar-RSAT }
                "0" { return }
                default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
            }
        } catch {
            Write-Host "`n[ERRO INESPERADO] A operacao foi interrompida devido a um erro." -ForegroundColor Red
            Write-Host "Detalhes: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.InvocationInfo) {
                Write-Host "Origem: $($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkGray
            }
        }
    }
}
