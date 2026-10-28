# Get-LocalRecon.ps1 - self-written light recon (no known-tool signatures), user context, read-only
# Output: ..\out\local-recon.txt
$ErrorActionPreference = 'Continue'
$outDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'out'
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$out = Join-Path $outDir 'local-recon.txt'
"[*] Get-LocalRecon $(Get-Date)" | Set-Content $out

function W($t, $b) { "" | Add-Content $out; "=== $t ===" | Add-Content $out; $b | Out-String | Add-Content $out }

W 'whoami' (whoami /all 2>&1)
W 'computer' ([Environment]::MachineName + ' / ' + [Environment]::UserDomainName + '\' + [Environment]::UserName)
W 'os' (Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime | Out-String)
W 'hotfixes' (Get-HotFix | Sort-Object InstalledOn | Out-String)
W 'local users' (Get-LocalUser | Select-Object Name,Enabled,LastLogon | Out-String)
W 'local groups w/ members' (
  (Get-LocalGroup | ForEach-Object {
    $g = $_; Get-LocalGroupMember -Group $g.Name -ErrorAction SilentlyContinue |
      Select-Object @{n='Group';e={$g.Name}},Name,ObjectClass
  }) | Out-String
)
W 'services (non-ms paths)' (
  Get-CimInstance Win32_Service | Where-Object { $_.PathName -and $_.PathName -notmatch '\\Windows\\' } |
    Select-Object Name,State,StartMode,StartName,PathName | Out-String
)
W 'unquoted service paths' (
  Get-CimInstance Win32_Service | Where-Object { $_.PathName -and $_.PathName -notmatch '^"' -and $_.PathName -match '\s' } |
    Select-Object Name,PathName | Out-String
)
W 'listening ports' (Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess | Sort-Object LocalPort | Out-String)
W 'firewall profiles' (Get-NetFirewallProfile | Select-Object Name,Enabled | Out-String)
W 'mapped drives' (Get-CimInstance Win32_NetworkConnection | Select-Object LocalName,RemoteName,UserName | Out-String)
W 'scheduled tasks (non-ms)' (
  Get-ScheduledTask | Where-Object { $_.TaskPath -notmatch '^\\Microsoft\\' } |
    Select-Object TaskName,TaskPath,State | Out-String
)
W 'autorun keys' (
  @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
  ) | ForEach-Object { if (Test-Path $_) { "[$_]"; (Get-ItemProperty $_ | Out-String) } }
)
W 'UAC / AlwaysInstallElevated' (
  @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer',
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer'
  ) | ForEach-Object { if (Test-Path $_) { "[$_]"; (Get-ItemProperty $_ | Select-Object * -ExcludeProperty PS* | Out-String) } }
)
W 'current user domain info' (
  try { Get-ADUser -Identity $env:USERNAME -Properties * -ErrorAction Stop | Select-Object samaccountname,memberof,admincount | Out-String }
  catch { "AD module not available or not domain-joined: $($_.Exception.Message)" }
)

"[+] done $(Get-Date)" | Add-Content $out
Write-Host "[+] saved $out"
