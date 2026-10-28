' enum-system.vbs - WMI system enumeration via Windows Script Host
' Runs under wscript/cscript (signed interpreter). Output: %TEMP%\enum-system.txt
Option Explicit
Dim fso, out, wmi, o, line
Set fso = CreateObject("Scripting.FileSystemObject")
Set out = fso.CreateTextFile(Environ("TEMP") & "\enum-system-vbs.txt", True)
out.WriteLine "[*] enum-system.vbs " & Now

Sub Dump(title, wql)
  Dim res, item
  out.WriteLine ""
  out.WriteLine "=== " & title & " ==="
  On Error Resume Next
  Set res = wmi.ExecQuery(wql)
  For Each item In res
    line = ""
    Dim p
    For Each p In item.Properties_
      If Not IsNull(p.Value) Then line = line & p.Name & "=" & p.Value & " | "
    Next
    out.WriteLine line
  Next
  On Error GoTo 0
End Sub

Set wmi = GetObject("winmgmts:\\.\root\cimv2")

Dump "OperatingSystem", "SELECT * FROM Win32_OperatingSystem"
Dump "ComputerSystem", "SELECT * FROM Win32_ComputerSystem"
Dump "Processor", "SELECT * FROM Win32_Processor"
Dump "LogicalDisk", "SELECT * FROM Win32_LogicalDisk"
Dump "UserAccount(local)", "SELECT * FROM Win32_UserAccount WHERE LocalAccount=True"
Dump "Group(local)", "SELECT * FROM Win32_Group WHERE LocalAccount=True"
Dump "Service(auto)", "SELECT Name,State,StartMode,StartName,PathName FROM Win32_Service WHERE StartMode='Auto'"
Dump "Process", "SELECT Name,ProcessId,ParentProcessId,ExecutablePath FROM Win32_Process"
Dump "StartupCommand", "SELECT * FROM Win32_StartupCommand"
Dump "QFE", "SELECT HotFixID,InstalledOn FROM Win32_QuickFixEngineering"
Dump "Share", "SELECT Name,Path FROM Win32_Share"
Dump "NetConnection", "SELECT * FROM Win32_NetworkConnection"
Dump "Env", "SELECT Name,VariableValue FROM Win32_Environment"

out.WriteLine ""
out.WriteLine "[+] done " & Now
out.Close
WScript.Echo "[+] saved " & Environ("TEMP") & "\enum-system-vbs.txt"
