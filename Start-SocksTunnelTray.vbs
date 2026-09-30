Option Explicit

Dim fso, shell, folder, ps1, command

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

folder = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = folder & "\Start-SocksTunnelTray.ps1"

command = "powershell.exe -NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & ps1 & """"

shell.Run command, 0, False