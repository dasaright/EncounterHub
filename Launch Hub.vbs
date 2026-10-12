' Launch the Python GUI without a console window.
Option Explicit
Dim shell, files, folder, launcher, candidates, candidate, program, args, code
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
folder = files.GetParentFolderName(WScript.ScriptFullName)
shell.CurrentDirectory = folder
launcher = folder & "\hub.py"
If Not files.FileExists(launcher) Then
    MsgBox "hub.py is missing. Extract the complete EncounterHub download first.", vbExclamation, "Encounter Hub"
    WScript.Quit 1
End If
' Prefer the windowless Python launcher; fall back to pythonw on PATH.
program = ""
candidates = Array(shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\Python\Launcher\pyw.exe", shell.ExpandEnvironmentStrings("%WINDIR%") & "\pyw.exe")
For Each candidate In candidates
    If files.FileExists(candidate) Then
        program = """" & candidate & """ -3"
        Exit For
    End If
Next
If program = "" Then program = "pyw.exe -3"
args = " """ & launcher & """"
On Error Resume Next
Err.Clear
code = shell.Run(program & args, 0, False)
If Err.Number <> 0 Then
    Err.Clear
    code = shell.Run("pythonw.exe" & args, 0, False)
    If Err.Number <> 0 Then
        MsgBox "Python could not be started. Install Python 3.10 or newer with the Python launcher, then try again.", vbExclamation, "Encounter Hub"
        WScript.Quit 1
    End If
End If
On Error GoTo 0
