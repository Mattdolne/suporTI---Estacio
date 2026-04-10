# ================================
# CONFIG LOG
# ================================
$Global:LogPath = "C:\registrolimpezapreventiva.txt"

function IniciarLog($tipo) {
    if (Test-Path $Global:LogPath) {
        Remove-Item $Global:LogPath -Force -ErrorAction SilentlyContinue
    }

    $inicio = Get-Date

    Add-Content $Global:LogPath "===== LIMPEZA $tipo ====="
    Add-Content $Global:LogPath "Inicio: $inicio"
    Add-Content $Global:LogPath "Usuario: $env:USERNAME"
    Add-Content $Global:LogPath "Maquina: $env:COMPUTERNAME"
    Add-Content $Global:LogPath ""
    Add-Content $Global:LogPath "--- RESUMO ---"

    return $inicio
}

function EscreverResumo($descricao, $quantidade, $mb) {
    Add-Content $Global:LogPath ("{0}: OK ({1} arquivos, {2} MB)" -f $descricao, $quantidade, $mb)
}

function FinalizarLog($inicio, $totalArquivos, $totalMB) {
    $fim = Get-Date

    Add-Content $Global:LogPath ""
    Add-Content $Global:LogPath "TOTAL ARQUIVOS: $totalArquivos"
    Add-Content $Global:LogPath "TOTAL MB: $totalMB"
    Add-Content $Global:LogPath "Fim: $fim"
}

# ================================
# FUNCAO AUXILIAR
# ================================
function MedirCaminho($caminho) {
    $itens = Get-ChildItem $caminho -Recurse -Force -ErrorAction SilentlyContinue

    $quantidade = $itens.Count
    $arquivos = $itens | Where-Object { -not $_.PSIsContainer } 
    $tamanho = ($arquivos | Measure-Object -Property Length -Sum).Sum

    if (-not $tamanho) { $tamanho = 0 }

    return @{
        Quantidade = $quantidade
        Bytes = $tamanho
        MB = [math]::Round($tamanho / 1MB, 2)
    }
}

# ================================
# LIMPEZA RAPIDA (BASE)
# ================================
function ExecutarLimpezaRapida {
    $totalArquivos = 0
    $totalBytes = 0

    # TEMP usuario
    $tempAtual = "$env:TEMP\*"
    if (Test-Path $tempAtual) {
        $med = MedirCaminho $tempAtual
        Remove-Item $tempAtual -Recurse -Force -ErrorAction SilentlyContinue

        $totalArquivos += $med.Quantidade
        $totalBytes += $med.Bytes

        Write-Host "OK - TEMP usuario ($($med.Quantidade), $($med.MB) MB)"
        EscreverResumo "TEMP usuario" $med.Quantidade $med.MB
    }

    # TEMP Windows
    $tempWin = "C:\Windows\Temp\*"
    if (Test-Path $tempWin) {
        $med = MedirCaminho $tempWin
        Remove-Item $tempWin -Recurse -Force -ErrorAction SilentlyContinue

        $totalArquivos += $med.Quantidade
        $totalBytes += $med.Bytes

        Write-Host "OK - TEMP Windows ($($med.Quantidade), $($med.MB) MB)"
        EscreverResumo "TEMP Windows" $med.Quantidade $med.MB
    }

    # TEMP usuarios
    $usuarios = Get-ChildItem "C:\Users" -Directory | Where-Object {
        $_.Name -notin @("Public", "Default", "Default User", "All Users")
    }

    $qtdUsuarios = 0
    $mbUsuarios = 0

    foreach ($user in $usuarios) {
        $tempUser = "$($user.FullName)\AppData\Local\Temp\*"

        if (Test-Path $tempUser) {
            $med = MedirCaminho $tempUser
            Remove-Item $tempUser -Recurse -Force -ErrorAction SilentlyContinue

            $qtdUsuarios += $med.Quantidade
            $mbUsuarios += $med.MB

            $totalArquivos += $med.Quantidade
            $totalBytes += $med.Bytes
        }
    }

    Write-Host "OK - TEMP usuarios ($qtdUsuarios, $mbUsuarios MB)"
    EscreverResumo "TEMP usuarios" $qtdUsuarios $mbUsuarios

    # ================================
    # LIMPEZA LIXEIRA 
    # ================================
    $recyclePath = 'C:\$Recycle.Bin'

    if (Test-Path $recyclePath) {
        $totalLixeira = 0
        $bytesLixeira = 0

        $itens = Get-ChildItem $recyclePath -Recurse -Force -ErrorAction SilentlyContinue

        foreach ($item in $itens) {
            if ($item.Name -eq "desktop.ini") {
                continue
            }

            try {
                if (-not $item.PSIsContainer) {
                    $bytesLixeira += $item.Length
                }

                Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                $totalLixeira++
            } catch {
                Start-Sleep -Milliseconds 200
                try {
                    Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                    $totalLixeira++
                } catch {
                    Write-Host "Falha: $($item.FullName)" -ForegroundColor Yellow
                }
            }
        }

        $mbLixeira = [math]::Round($bytesLixeira / 1MB, 2)

        Write-Host "OK - Lixeira limpa ($totalLixeira itens, $mbLixeira MB)"
        EscreverResumo "Lixeira" $totalLixeira $mbLixeira

        $totalArquivos += $totalLixeira
        $totalBytes += $bytesLixeira
    }

    return @{
        Arquivos = $totalArquivos
        Bytes = $totalBytes
    }
}

# ================================
# LIMPEZA RAPIDA (PUBLICA)
# ================================
function LimpezaRapida {
    $inicio =  "RAPI-DA"

    Write-Host "Iniciando limpeza rapida..." -ForegroundColor Cyan

    $res = ExecutarLimpezaRapida

    $totalMB = [math]::Round($res.Bytes / 1MB, 2)

    Write-Host ""
    Write-Host "Limpeza rapida concluida"
    Write-Host "Arquivos: $($res.Arquivos)"
    Write-Host "Espaco: $totalMB MB" -ForegroundColor Green

    FinalizarLog $inicio $res.Arquivos $totalMB
}

# ================================
# LIMPEZA COMPLETA
# ================================
function LimpezaCompleta {
    Clear-Host
    Write-Host "ATENCAO: LIMPEZA COMPLETA" -ForegroundColor Red
    Write-Host "Remove arquivos pessoais"
    Write-Host ""

    $confirmacao = Read-Host "Digite S para continuar ou N para cancelar"
    if ($confirmacao -ne "S") {
        Write-Host "Cancelado"
        return
    }

    $inicio =  "COMPLETA"

    Write-Host "Executando limpeza rapida..."
    $resRapida = ExecutarLimpezaRapida

    $totalArquivos = $resRapida.Arquivos
    $totalBytes = $resRapida.Bytes

    $usuarios = Get-ChildItem "C:\Users" -Directory | Where-Object {
        $_.Name -notin @("Public", "Default", "Default User", "All Users")
    }

    $pastas = @("Documents","Downloads","Pictures","Videos","Favorites","Links","Searches")

    foreach ($user in $usuarios) {
        foreach ($pasta in $pastas) {
            $caminho = "$($user.FullName)\$pasta\*"

            if (Test-Path $caminho) {
                $med = MedirCaminho $caminho
                Remove-Item $caminho -Recurse -Force -ErrorAction SilentlyContinue

                $totalArquivos += $med.Quantidade
                $totalBytes += $med.Bytes

                Write-Host "OK - $($user.Name)\$pasta ($($med.Quantidade))"
            }
        }

        # Desktop
        $desktop = "$($user.FullName)\Desktop"
        if (Test-Path $desktop) {
            $itensDesktop = Get-ChildItem $desktop -Force -ErrorAction SilentlyContinue
            $extensoesProtegidas = @(".lnk", ".url", ".website")

            foreach ($item in $itensDesktop) {
                if ($item.Extension.ToLower() -notin $extensoesProtegidas) {
                    try {
                        $tamanho = $item.Length
                        Remove-Item $item.FullName -Recurse -Force -ErrorAction Stop

                        $totalArquivos++
                        $totalBytes += $tamanho
                    } catch {
                        Write-Host "ERRO ao remover: $($user.Name)\$($item.Name)" -ForegroundColor Yellow
                    }
                }
            }
        }

        # Cache Chrome
        Remove-Item "$($user.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Cache Edge
        Remove-Item "$($user.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    $totalMB = [math]::Round($totalBytes / 1MB, 2)

    Write-Host ""
    Write-Host "Limpeza completa concluida"
    Write-Host "Arquivos totais: $totalArquivos"
    Write-Host "Espaco total: $totalMB MB" -ForegroundColor Green

    FinalizarLog $inicio $totalArquivos $totalMB
}

# ================================
# DESLIGAMENTO
# ================================
function DesligarMaquina {
    Write-Host "Desligando maquina..."
    shutdown /s /t 5
}

# ================================
# MENULIMPEZA
# ================================
function Limpeza {
    while ($true) {
        Clear-Host
        Write-Host "===== LIMPEZA ====="
        Write-Host "1 - Limpeza rapida"
        Write-Host "2 - Limpeza completa"
        Write-Host "3 - Limpeza rapida e desligar"
        Write-Host "4 - Limpeza completa e desligar"
        Write-Host "0 - Voltar"
        Write-Host ""

        $opcao = Read-Host "Escolha"

        switch ($opcao) {
            "1" { LimpezaRapida }
            "2" { LimpezaCompleta }
            "3" { LimpezaRapida; DesligarMaquina }
            "4" { LimpezaCompleta; DesligarMaquina }
            "0" { return }
            default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
        }

        Pause
    }
}