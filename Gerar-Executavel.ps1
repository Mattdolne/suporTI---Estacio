# ========================================================
# GERADOR DE EXECUTAVEL STANDALONE (suporTI-Estacio.exe)
# ========================================================
$ErrorActionPreference = "Stop"

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputExe = Join-Path $baseDir "suporTI-Estacio.exe"
$buildDir = Join-Path $baseDir "temp_build"

Write-Host "1. Lendo arquivos do projeto..." -ForegroundColor Cyan

$limpezaCode = Get-Content (Join-Path $baseDir "funcoes\limpeza.ps1") -Raw -Encoding UTF8
$auditoriaCode = Get-Content (Join-Path $baseDir "funcoes\auditoria.ps1") -Raw -Encoding UTF8
$manutencaoCode = Get-Content (Join-Path $baseDir "funcoes\manutencao.ps1") -Raw -Encoding UTF8
$menuCode = Get-Content (Join-Path $baseDir "menu.ps1") -Raw -Encoding UTF8

# Remover a secao de importacao dinamica de arquivos do menu.ps1 (ja que os codigos estarao concatenados em memoria)
$menuCodeClean = $menuCode -replace '(?s)# ================================\s*# IMPORTAR MODULOS.*?(?=# ================================\s*# VALIDACAO DE ADMIN)', ''

# Empacotar todos os modulos e o menu em um unico payload PowerShell
$bundledScript = @"
# ========================================================
# suporTI-Estacio (Pacote Unificado Standalone)
# ========================================================
$limpezaCode

$auditoriaCode

$manutencaoCode

$menuCodeClean
"@

Write-Host "2. Gerando codificacao Base64 do payload..." -ForegroundColor Cyan
$scriptBytes = [System.Text.Encoding]::Unicode.GetBytes($bundledScript)
$base64Payload = [System.Convert]::ToBase64String($scriptBytes)

Write-Host "3. Preparando codigo C# com Manifesto de Administrador..." -ForegroundColor Cyan

if (-not (Test-Path $buildDir)) {
    New-Item -Path $buildDir -ItemType Directory | Out-Null
}

$csPath = Join-Path $buildDir "Program.cs"
$manifestPath = Join-Path $buildDir "app.manifest"

# Manifesto UAC exigindo elevação de Administrador
$manifestContent = @"
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity version="1.3.0.0" name="suporTI-Estacio"/>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
        <requestedExecutionLevel level="requireAdministrator" uiAccess="false" />
      </requestedPrivileges>
    </security>
  </trustInfo>
</assembly>
"@

Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8

# Codigo C# Wrapper
$csContent = @"
using System;
using System.Diagnostics;
using System.Text;

namespace SuporTIEstacio
{
    class Program
    {
        static void Main(string[] args)
        {
            string payload = "$base64Payload";
            
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "powershell.exe";
            psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " + payload;
            psi.UseShellExecute = false;

            try
            {
                Process proc = Process.Start(psi);
                if (proc != null)
                {
                    proc.WaitForExit();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Erro ao iniciar a ferramenta de suporte: " + ex.Message);
                Console.ReadLine();
            }
        }
    }
}
"@

Set-Content -Path $csPath -Value $csContent -Encoding UTF8

Write-Host "4. Compilando o executavel com csc.exe..." -ForegroundColor Cyan

$cscCompiler = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $cscCompiler)) {
    $cscCompiler = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

$compileArgs = "/nologo /target:exe /out:`"$outputExe`" /win32manifest:`"$manifestPath`" `"$csPath`""

$process = Start-Process -FilePath $cscCompiler -ArgumentList $compileArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0 -and (Test-Path $outputExe)) {
    $sizeKB = [math]::Round((Get-Item $outputExe).Length / 1KB, 2)
    Write-Host "`n[SUCESSO] Executavel criado com sucesso!" -ForegroundColor Green
    Write-Host "Caminho: $outputExe ($sizeKB KB)" -ForegroundColor Green
    Write-Host "Tudo o que o programa precisa para rodar esta embutido neste unico arquivo .exe!" -ForegroundColor Yellow
} else {
    Write-Host "`n[ERRO] Falha ao compilar o executavel." -ForegroundColor Red
}

# Limpeza dos arquivos temporarios
Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
