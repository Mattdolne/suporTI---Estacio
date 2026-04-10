# ================================
# FUNCAO CORE: COLETAR INVENTARIO
# ================================
function ColetarInventario {

    Write-Host "Coletando informacoes do sistema... Aguarde." -ForegroundColor Cyan

    # --- COLETA DE DADOS BASE ---
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $net = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=$true" | Select-Object -First 1

    # --- CALCULOS DE HARDWARE ---
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $diskTotal = [math]::Round($disk.Size / 1GB, 2)
    $diskLivre = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskUsado = $diskTotal - $diskLivre

    # --- MONTAGEM DO OBJETO ---
    $inventario = [ordered]@{
        # INFORMACOES DE SISTEMA
        "Data da Coleta"     = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
        "Hostname"           = $env:COMPUTERNAME
        "Dominio"            = $cs.Domain
        "Versao Windows"     = "$($os.Caption) (Build $($os.BuildNumber))"
        "Data Formatacao"    = $os.InstallDate.ToString("dd/MM/yyyy")
        
        # INFORMACOES DE HARDWARE
        "Serial Number"      = $bios.SerialNumber
        "Processador"        = $cpu.Name.Trim()
        "Memoria RAM"        = "$ramGB GB"
        "Disco C: Total"     = "$diskTotal GB"
        "Disco C: Usado"     = "$diskUsado GB"
        
        # INFORMACOES DE REDE
        "Endereco IP"        = $net.IPAddress[0]
        "MAC Address"        = $net.MACAddress
    }

    return [PSCustomObject]$inventario
}

# ================================
# RELATORIO: TERMINAL
# ================================
function AuditoriaTerminal {
    $dados = ColetarInventario
    Clear-Host

    Write-Host "========================================="
    Write-Host "         AUDITORIA DE SISTEMA"
    Write-Host " Data: $($dados.'Data da Coleta')"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "--- SISTEMA ---" -ForegroundColor Yellow
    Write-Host "Hostname.......: $($dados.Hostname)"
    Write-Host "Dominio........: $($dados.Dominio)"
    Write-Host "Windows........: $($dados.'Versao Windows')"
    Write-Host "Instalacao.....: $($dados.'Data Formatacao')"
    Write-Host ""
    Write-Host "--- HARDWARE ---" -ForegroundColor Yellow
    Write-Host "Serial.........: $($dados.'Serial Number')"
    Write-Host "Processador....: $($dados.Processador)"
    Write-Host "RAM............: $($dados.'Memoria RAM')"
    Write-Host "Disco Total....: $($dados.'Disco C: Total')"
    Write-Host "Disco Usado....: $($dados.'Disco C: Usado')"
    Write-Host ""
    Write-Host "--- REDE ---" -ForegroundColor Yellow
    Write-Host "IP.............: $($dados.'Endereco IP')"
    Write-Host "MAC............: $($dados.'MAC Address')"
    Write-Host "========================================="
    Write-Host ""
}

# ================================
# RELATORIO: CSV
# ================================
function AuditoriaCSV {
    $dados = ColetarInventario
    $caminho = "$([Environment]::GetFolderPath('Desktop'))\Auditoria_$($env:COMPUTERNAME).csv"

    try {
        $dados | Export-Csv -Path $caminho -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        Write-Host "Relatorio salvo com sucesso em:" -ForegroundColor Green
        Write-Host $caminho
    } catch {
        Write-Host "Erro ao salvar o relatorio CSV." -ForegroundColor Red
    }
}

# ================================
# RELATORIO: XML
# ================================
function AuditoriaXML {
    $dados = ColetarInventario
    $caminho = "$([Environment]::GetFolderPath('Desktop'))\Auditoria_$($env:COMPUTERNAME).xml"

    try {
        $dados | Export-Clixml -Path $caminho
        Write-Host "Relatorio salvo com sucesso em:" -ForegroundColor Green
        Write-Host $caminho
    } catch {
        Write-Host "Erro ao salvar o relatorio XML." -ForegroundColor Red
    }
}

# ================================
# RELATORIO: TXT
# ================================
function AuditoriaTXT {
    $dados = ColetarInventario
    $caminho = "$([Environment]::GetFolderPath('Desktop'))\Auditoria_$($env:COMPUTERNAME).txt"

    try {
        if (Test-Path $caminho) { Remove-Item $caminho -Force -ErrorAction SilentlyContinue }

        Add-Content $caminho "========================================="
        Add-Content $caminho "         AUDITORIA DE SISTEMA"
        Add-Content $caminho " Data: $($dados.'Data da Coleta')"
        Add-Content $caminho "========================================="
        Add-Content $caminho ""
        Add-Content $caminho "--- SISTEMA ---"
        Add-Content $caminho "Hostname.......: $($dados.Hostname)"
        Add-Content $caminho "Dominio........: $($dados.Dominio)"
        Add-Content $caminho "Windows........: $($dados.'Versao Windows')"
        Add-Content $caminho "Instalacao.....: $($dados.'Data Formatacao')"
        Add-Content $caminho ""
        Add-Content $caminho "--- HARDWARE ---"
        Add-Content $caminho "Serial.........: $($dados.'Serial Number')"
        Add-Content $caminho "Processador....: $($dados.Processador)"
        Add-Content $caminho "RAM............: $($dados.'Memoria RAM')"
        Add-Content $caminho "Disco Total....: $($dados.'Disco C: Total')"
        Add-Content $caminho "Disco Usado....: $($dados.'Disco C: Usado')"
        Add-Content $caminho ""
        Add-Content $caminho "--- REDE ---"
        Add-Content $caminho "IP.............: $($dados.'Endereco IP')"
        Add-Content $caminho "MAC............: $($dados.'MAC Address')"
        Add-Content $caminho "========================================="

        Write-Host "Relatorio salvo com sucesso em:" -ForegroundColor Green
        Write-Host $caminho
    } catch {
        Write-Host "Erro ao salvar o relatorio TXT." -ForegroundColor Red
    }
}

# ================================
# MENU AUDITORIA
# ================================
function Auditoria {
    Menu-Auditoria
}

function MenuAuditoria {
    while ($true) {
        Clear-Host
        Write-Host "===== AUDITORIA ====="
        Write-Host "1 - Relatorio no terminal"
        Write-Host "2 - Relatorio CSV (Salva no Desktop)"
        Write-Host "3 - Relatorio XML (Salva no Desktop)"
        Write-Host "4 - Relatorio TXT (Salva no Desktop)"
        Write-Host "0 - Voltar"
        Write-Host ""

        $opcao = Read-Host "Escolha"

        switch ($opcao) {
            "1" { AuditoriaTerminal }
            "2" { AuditoriaCSV }
            "3" { AuditoriaXML }
            "4" { AuditoriaTXT }
            "0" { return }
            default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
        }

        Pause
    }
}