# ================================
# CONFIG LOG
# ================================
$Global:LogPath = "C:\registrolimpezapreventiva.txt"

function Iniciar-Log($tipo) {
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

function Escrever-Resumo($descricao, $quantidade, $mb) {
    Add-Content $Global:LogPath ("{0}: OK ({1} arquivos, {2} MB)" -f $descricao, $quantidade, $mb)
}

function Finalizar-Log($inicio, $totalArquivos, $totalMB) {
    $fim = Get-Date

    Add-Content $Global:LogPath ""
    Add-Content $Global:LogPath "TOTAL ARQUIVOS: $totalArquivos"
    Add-Content $Global:LogPath "TOTAL MB: $totalMB"
    Add-Content $Global:LogPath "Fim: $fim"
}

# ================================
# FUNCAO AUXILIAR
# ================================
function Medir-Caminho($caminho) {
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
function Executar-LimpezaRapida {
    $totalArquivos = 0
    $totalBytes = 0

    # TEMP usuario
    $tempAtual = "$env:TEMP\*"
    if (Test-Path $tempAtual) {
        $med = Medir-Caminho $tempAtual
        Remove-Item $tempAtual -Recurse -Force -ErrorAction SilentlyContinue

        $totalArquivos += $med.Quantidade
        $totalBytes += $med.Bytes

        Write-Host "OK - TEMP usuario ($($med.Quantidade), $($med.MB) MB)"
        Escrever-Resumo "TEMP usuario" $med.Quantidade $med.MB
    }

    # TEMP Windows
    $tempWin = "C:\Windows\Temp\*"
    if (Test-Path $tempWin) {
        $med = Medir-Caminho $tempWin
        Remove-Item $tempWin -Recurse -Force -ErrorAction SilentlyContinue

        $totalArquivos += $med.Quantidade
        $totalBytes += $med.Bytes

        Write-Host "OK - TEMP Windows ($($med.Quantidade), $($med.MB) MB)"
        Escrever-Resumo "TEMP Windows" $med.Quantidade $med.MB
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
            $med = Medir-Caminho $tempUser
            Remove-Item $tempUser -Recurse -Force -ErrorAction SilentlyContinue

            $qtdUsuarios += $med.Quantidade
            $mbUsuarios += $med.MB

            $totalArquivos += $med.Quantidade
            $totalBytes += $med.Bytes
        }
    }

    Write-Host "OK - TEMP usuarios ($qtdUsuarios, $mbUsuarios MB)"
    Escrever-Resumo "TEMP usuarios" $qtdUsuarios $mbUsuarios

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
        Escrever-Resumo "Lixeira" $totalLixeira $mbLixeira

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
function Limpeza-Rapida {
    $inicio = Iniciar-Log "RAPIDA"

    Write-Host "Iniciando limpeza rapida..." -ForegroundColor Cyan

    $res = Executar-LimpezaRapida

    $totalMB = [math]::Round($res.Bytes / 1MB, 2)

    Write-Host ""
    Write-Host "Limpeza rapida concluida"
    Write-Host "Arquivos: $($res.Arquivos)"
    Write-Host "Espaco: $totalMB MB" -ForegroundColor Green

    Finalizar-Log $inicio $res.Arquivos $totalMB
}

# ================================
# LIMPEZA COMPLETA
# ================================
function Limpeza-Completa {
    Clear-Host
    Write-Host "ATENCAO: LIMPEZA COMPLETA" -ForegroundColor Red
    Write-Host "Remove arquivos pessoais"
    Write-Host ""

    $confirmacao = Read-Host "Digite S para continuar ou N para cancelar"
    if ($confirmacao -ne "S") {
        Write-Host "Cancelado"
        return
    }

    $inicio = Iniciar-Log "COMPLETA"

    Write-Host "Executando limpeza rapida..."
    $resRapida = Executar-LimpezaRapida

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
                $med = Medir-Caminho $caminho
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

    Finalizar-Log $inicio $totalArquivos $totalMB
}

# ================================
# DESLIGAMENTO
# ================================
function Desligar-Maquina {
    Write-Host "Desligando maquina..."
    shutdown /s /t 5
}

# ================================
# MENU LIMPEZA
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
            "1" { Limpeza-Rapida }
            "2" { Limpeza-Completa }
            "3" { Limpeza-Rapida; Desligar-Maquina }
            "4" { Limpeza-Completa; Desligar-Maquina }
            "0" { return }
            default { Write-Host "Opcao invalida" -ForegroundColor Yellow; Pause }
        }

        Pause
    }
}