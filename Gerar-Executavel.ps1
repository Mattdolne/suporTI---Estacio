# ========================================================
# GERADOR DE EXECUTAVEL STANDALONE (SuporTIvX.X.X.exe)
# ========================================================
$ErrorActionPreference = "Stop"

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $baseDir "temp_build"

Write-Host "1. Lendo arquivos do projeto..." -ForegroundColor Cyan

$limpezaCode = Get-Content (Join-Path $baseDir "funcoes\limpeza.ps1") -Raw -Encoding UTF8
$auditoriaCode = Get-Content (Join-Path $baseDir "funcoes\auditoria.ps1") -Raw -Encoding UTF8
$manutencaoCode = Get-Content (Join-Path $baseDir "funcoes\manutencao.ps1") -Raw -Encoding UTF8
$menuCode = Get-Content (Join-Path $baseDir "menu.ps1") -Raw -Encoding UTF8

# Extrair a versao dinamicamente do menu.ps1
$versaoMatch = [regex]::Match($menuCode, 'Versao:\s*([0-9\.]+)')
if ($versaoMatch.Success) {
    $versao = $versaoMatch.Groups[1].Value.Trim()
} else {
    $versao = "1.3"
}

$exeFileName = "SuporTIv$versao.exe"
$outputExe = Join-Path $baseDir $exeFileName

Write-Host "Versao detectada: v$versao -> Nome do executavel: $exeFileName" -ForegroundColor Yellow

# Remover a secao de importacao dinamica de arquivos do menu.ps1 (ja que os codigos estarao concatenados em memoria)
$menuCodeClean = $menuCode -replace '(?s)# ================================\s*# IMPORTAR MODULOS.*?(?=# ================================\s*# VALIDACAO DE ADMIN)', ''

# Empacotar todos os modulos e o menu em um unico payload PowerShell
$bundledScript = @"
# ========================================================
# suporTI-Estacio (Pacote Unificado Standalone v$versao)
# ========================================================
$limpezaCode

$auditoriaCode

$manutencaoCode

$menuCodeClean
"@

Write-Host "2. Gerando codificacao Base64 do payload..." -ForegroundColor Cyan
$scriptBytes = [System.Text.Encoding]::UTF8.GetBytes($bundledScript)
$base64Payload = [System.Convert]::ToBase64String($scriptBytes)

Write-Host "3. Preparando codigo C# com Manifesto de Administrador..." -ForegroundColor Cyan

if (-not (Test-Path $buildDir)) {
    New-Item -Path $buildDir -ItemType Directory | Out-Null
}

$csPath = Join-Path $buildDir "Program.cs"
$manifestPath = Join-Path $buildDir "app.manifest"

# Formatar versao para 4 digitos do manifesto assembly (ex: 1.3 -> 1.3.0.0)
$manifestVersion = "$versao.0.0"
if ($versao -match '^\d+\.\d+\.\d+$') { $manifestVersion = "$versao.0" }
if ($versao -match '^\d+\.\d+\.\d+\.\d+$') { $manifestVersion = $versao }

# Manifesto UAC exigindo elevação de Administrador
$manifestContent = @"
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity version="$manifestVersion" name="SuporTI"/>
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
using System.IO;
using System.Text;

namespace SuporTIEstacio
{
    class Program
    {
        static void Main(string[] args)
        {
            string base64Payload = "$base64Payload";
            string tempPs1Path = Path.Combine(Path.GetTempPath(), "suporTI_v$versao`_" + Guid.NewGuid().ToString("N") + ".ps1");

            try
            {
                byte[] scriptBytes = Convert.FromBase64String(base64Payload);
                string scriptContent = Encoding.UTF8.GetString(scriptBytes);
                File.WriteAllText(tempPs1Path, scriptContent, Encoding.UTF8);

                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + tempPs1Path + "\"";
                psi.UseShellExecute = false;

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
            finally
            {
                if (File.Exists(tempPs1Path))
                {
                    try { File.Delete(tempPs1Path); } catch {}
                }
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
    Write-Host "Arquivo: $exeFileName ($sizeKB KB)" -ForegroundColor Green
    Write-Host "Caminho completo: $outputExe" -ForegroundColor Green
} else {
    Write-Host "`n[ERRO] Falha ao compilar o executavel." -ForegroundColor Red
}

# Limpeza dos arquivos temporarios de build
Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
