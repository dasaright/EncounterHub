#include-once

; #INCLUDES# ====================================================================================================================
; Note: All native AutoIt includes are covered by GwAu3/API/_GwAu3.au3 which should always be included in the main script.
;       The same applies to GwAu3 API-specific includes. Other includes containing script-specific files are covered 
;       by _EncounterRebuilt.au3.
;
; #include <MsgBoxConstants.au3>
; #include <String.au3>
; #include <WinAPIMem.au3>
; #include <WinAPIProc.au3>
;
; #include "AddOns.au3"
; #include "GUI.au3"
; #include "Security.au3"
; ===============================================================================================================================

#Region WinAPI
; #GLOBALS - WINAPI# ============================================================================================================
; WinAPI return/status codes (CreateMutex / WaitForSingleObject)
Global Const $GC_I_ERROR_ALREADY_EXISTS = 183 ; GetLastError: named object already existed
; WaitForSingleObject return values
Global Const $GC_I_WAIT_TIMEOUT = 0x00000102 ; Timeout elapsed: not acquired
Global Const $GC_I_WAIT_FAILED = 0xFFFFFFFF ; Wait failed: call _WinAPI_GetLastError()
; ===============================================================================================================================
#EndRegion WinAPI

#Region GWProcess
; #GLOBALS - GWPROCESS# =========================================================================================================
; Game identification & process access
Global Const $GC_S_GWPROCESS_GAME_CLASS = "ArenaNet_Dx_Window_Class" ; Native game window class (render window)
Global Const $GC_S_GWPROCESS_GAME_EXE = "Gw.exe" ; Expected playable executable name
Global Const $GC_I_GWPROCESS_PROC_ACCESS = BitOR($PROCESS_TERMINATE, $PROCESS_SET_QUOTA, $PROCESS_QUERY_LIMITED_INFORMATION) ; Access mask for OpenProcess
; Mutex
Global $g_h_GameMutex = 0
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_JobObjectEnumPIDs
; Description....: Enumerates all process IDs currently in a given Job Object.
; Syntax.........: Launch_JobObjectEnumPIDs ( $a_h_Job )
; Parameters.....: $a_h_Job  - Handle to a Job Object (from _WinAPI_CreateJobObject()).
; Return values..: Success   - 1D array of PIDs (may be size 0..N).
;                  Failure   - 0, sets @error = 1 if QueryInformationJobObject fails.
; Author.........: KleuTSchi
; Remarks........: Uses information class 3 (JOBOBJECT_BASIC_PROCESS_ID_LIST). A fixed buffer of 16 entries is allocated;
;                  if the job contains more PIDs, results are truncated to the first 16.
; Related........: Launch_WaitForPlayablePID, _WinAPI_AssignProcessToJobObject, _WinAPI_CreateJobObject
; ===============================================================================================================================
Func Launch_JobObjectEnumPIDs($a_h_Job)
    Local Const $LC_I_BUFFER = 16
    Local $l_d_ProcessListInfo = DllStructCreate($tagJOBOBJECT_BASIC_PROCESS_ID_LIST & ";ulong_ptr ProcessIdList[" & $LC_I_BUFFER & "]")
    Local $l_av_Result = DllCall("kernel32.dll", "bool", "QueryInformationJobObject", _
        "handle", $a_h_Job, _
        "int", 3, _
        "ptr", DllStructGetPtr($l_d_ProcessListInfo), _
        "dword", DllStructGetSize($l_d_ProcessListInfo), _
        "dword*", 0)
    If @error Or Not $l_av_Result[0] Then Return SetError(1, 0, 0)

    Local $l_i_Count = DllStructGetData($l_d_ProcessListInfo, "NumberOfProcessIdsInList")
    If $l_i_Count > $LC_I_BUFFER Then $l_i_Count = $LC_I_BUFFER

    Local $l_av_PIDs[$l_i_Count]
    For $l_i_Idx = 1 To $l_i_Count
        $l_av_PIDs[$l_i_Idx - 1] = DllStructGetData($l_d_ProcessListInfo, "ProcessIdList", $l_i_Idx)
    Next
    Return $l_av_PIDs
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_GetProccessCreationTime
; Description....: Retrieves the creation time (FILETIME) for a PID as a UInt64 (100-ns intervals since 1601-01-01 UTC).
; Syntax.........: Launch_GetProccessCreationTime ( $a_i_PID )
; Parameters.....: $a_i_PID   - Process ID to query.
; Return values..: Success    - UInt64 creation FILETIME.
;                  Failure    - 0, sets @error = 1 if OpenProcess fails, or 2 if GetProcessTimes fails.
; Author.........: KleuTSchi
; Remarks........: Opens the process with $GC_I_GWPROCESS_PROC_ACCESS, calls GetProcessTimes, closes the handle, and returns the creation
;                  timestamp.
; Related........: _WinAPI_CloseHandle, _WinAPI_OpenProcess, GetProcessTimes
; ===============================================================================================================================
Func Launch_GetProccessCreationTime($a_i_PID)
    Local $l_h_Proc = _WinAPI_OpenProcess($GC_I_GWPROCESS_PROC_ACCESS, False, $a_i_PID)
    If @error Or $l_h_Proc = 0 Then Return SetError(1, 0, 0)

    Local $l_av_Result = DllCall("kernel32.dll", "bool", "GetProcessTimes", _
        "handle", $l_h_Proc, _
        "uint64*", 0, _
        "uint64*", 0, _
        "uint64*", 0, _
        "uint64*", 0)
    _WinAPI_CloseHandle($l_h_Proc)
    If @error Or Not $l_av_Result[0] Then Return SetError(2, 0, 0)
    Return $l_av_Result[1]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_ProcessWindowOfClass
; Description....: Returns the HWND of the first top-level window of a given class owned by the specified PID.
; Syntax.........: Launch_ProcessWindowOfClass ( $a_i_PID, $a_s_Class )
; Parameters.....: $a_i_PID   - Process ID to match against window owner.
;                  $a_s_Class - Window class name (e.g. $GC_S_GWPROCESS_GAME_CLASS).
; Return values..: Success    - HWND of the matching window.
;                  Failure    - 0 if none found.
; Author.........: KleuTSchi
; Remarks........: Enumerates windows via WinList("[CLASS:...]") and matches ownership using WinGetProcess().
; Related........: Launch_WaitForPlayablePID, WinGetProcess, WinList
; ===============================================================================================================================
Func Launch_ProcessWindowOfClass($a_i_PID, $a_s_Class)
    Local $l_av_Windows = WinList("[CLASS:" & $a_s_Class & "]")
    If Not IsArray($l_av_Windows) Then Return 0
    For $l_i_Idx = 1 To $l_av_Windows[0][0]
        Local $l_h_Wnd = $l_av_Windows[$l_i_Idx][1]
        If WinGetProcess($l_h_Wnd) = $a_i_PID Then
            Return $l_h_Wnd
        EndIf
    Next
    Return 0
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_WaitForPlayablePID
; Description....: Waits until the game becomes playable by either:
;                  (A) the root PID creates a window of class $GC_S_GWPROCESS_GAME_CLASS within a grace period, or
;                  (B) a non-root child named $GC_S_GWPROCESS_GAME_EXE appears inside the Job Object and creates a window of class
;                      $GC_S_GWPROCESS_GAME_CLASS within its own grace period (the grace timer restarts when a new candidate is seen).
; Syntax.........: Launch_WaitForPlayablePID ( $a_i_RootPID, $a_h_Job, $a_i_WindowGraceMs, $a_i_OverallTimeoutMs )
; Parameters.....: $a_i_RootPID          - PID returned by CreateProcessW for the suspended root process.
;                  $a_h_Job              - Job Object handle containing the root and its children (0 disables job scanning).
;                  $a_i_WindowGraceMs    - Milliseconds to wait for the root (Path A) or the candidate child (Path B)
;                                          to show the expected window class.
;                  $a_i_OverallTimeoutMs - Absolute timeout in milliseconds for the entire wait sequence.
; Return values..: Success               - PID considered playable (root or child).
;                  Failure               - 0, sets @error = 1 on timeout / not found / candidate child exited before
;                                          showing the required window.
; Author.........: KleuTSchi
; Remarks........: - Path A: While the root process is alive and within the initial grace window, returns when the
;                    root’s window of class $GC_S_GWPROCESS_GAME_CLASS is detected (via Launch_ProcessWindowOfClass).
;                  - Path B: Enumerates the Job’s PIDs (Launch_JobObjectEnumPIDs), filters by file name = $GC_S_GWPROCESS_GAME_EXE
;                    using _WinAPI_GetProcessFileName and a simple RegExp. When a new Gw.exe candidate is found,
;                    the grace timer is restarted and the function waits up to $a_i_WindowGraceMs for that candidate’s
;                    $GC_S_GWPROCESS_GAME_CLASS window to appear. If the candidate exits first, the function fails early.
;                  - Uses short Sleep(150) yields in loops to keep the GUI responsive in OnEvent mode.
; Related........: Launch_JobObjectEnumPIDs, Launch_ProcessWindowOfClass, _WinAPI_GetProcessFileName, ProcessExists,
;                  StringRegExpReplace
; ===============================================================================================================================
Func Launch_WaitForPlayablePID($a_i_RootPID, $a_h_Job, $a_i_WindowGraceMs, $a_i_OverallTimeoutMs)
    Local $l_i_T0 = TimerInit()
    Local $l_i_TGrace = TimerInit()
    Local $l_s_Exe = StringLower($GC_S_GWPROCESS_GAME_EXE)

    While TimerDiff($l_i_T0) < $a_i_OverallTimeoutMs
        ; (Path A) RootPID shows the expected window within grace period
        If ProcessExists($a_i_RootPID) And TimerDiff($l_i_TGrace) <= $a_i_WindowGraceMs Then
            If Launch_ProcessWindowOfClass($a_i_RootPID, $GC_S_GWPROCESS_GAME_CLASS) Then
                Return $a_i_RootPID
            EndIf
        EndIf

        ; (Path B) Any non-root Gw.exe inside the job shows expected window
        Local $l_av_PIDs = Launch_JobObjectEnumPIDs($a_h_Job)
        If IsArray($l_av_PIDs) Then
            For $l_i_Idx = 0 To UBound($l_av_PIDs) - 1
                Local $l_i_PID = $l_av_PIDs[$l_i_Idx]
                If $l_i_PID = 0 Or $l_i_PID = $a_i_RootPID Then ContinueLoop
                If Not ProcessExists($l_i_PID) Then ContinueLoop

                Local $l_s_FileName = _WinAPI_GetProcessFileName($l_i_PID)
                If @error Or $l_s_FileName = "" Then ContinueLoop
                Local $l_s_Base = StringLower(StringRegExpReplace($l_s_FileName, "^.*\\", ""))
                If $l_s_Base <> $l_s_Exe Then ContinueLoop
                
                $l_i_TGrace = TimerInit()
                While TimerDiff($l_i_TGrace) < $a_i_WindowGraceMs
                    If Not ProcessExists($l_i_PID) Then Return SetError(1, 0, 0)
                    If Launch_ProcessWindowOfClass($l_i_PID, $GC_S_GWPROCESS_GAME_CLASS) Then
                        Return $l_i_PID
                    EndIf
                    Sleep(150)
                WEnd
            Next
        EndIf
        Sleep(150)
    WEnd

    Return SetError(1, 0, 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_LaunchAccountFromINI
; Description....: Launches Guild Wars suspended using INI settings, applies a multiclient patch, resumes, and determines the
;                  **playable** PID using a **Job Object for tracking the launcher** (window-first, job-fallback).
; Syntax.........: Launch_LaunchAccountFromINI ( $a_s_IniFile, $a_s_Character [, $a_b_Restart = False ] )
; Parameters.....: $a_s_IniFile   - Path to the INI file with account settings.
;                  $a_s_Character - INI section name providing Email, Pwd, FilePath.
;                  $a_b_Restart   - Boolean indicating if the launch is a restart.
; Return values..: Success        - PID (process created/resumed; playable PID identified via window or job chain).
;                  Failure        - 0 (errors are logged/shown; handles cleaned up).
; Author.........: KleuTSchi, Greg
; Remarks........: - **INI reads are serialized** via Security_AcquireFileMutex($a_s_IniFile, timeout) /
;                    Security_CloseMutex() from "Security.au3", to avoid torn/partial reads across processes.
;                  - Passwords are read then decrypted via Security_DecryptString() to support encrypted INI storage.
;                  - Prevents duplicate launches via a per-character named mutex; checks ERROR_ALREADY_EXISTS (183).
;                  - Creates the process with CREATE_SUSPENDED, applies Launch_ApplyMultiClientPatch(), then resumes.
;                  - Verifies liveness with WaitForSingleObject(hProcess, 0) expecting WAIT_TIMEOUT.
;                  - **Updater tracking:** Assigns the root process to a Job Object so children (updater/patcher) are captured.
;                    Waits for a “playable” PID via:
;                       * Path A: root PID shows window class $GC_S_GWPROCESS_GAME_CLASS within a grace period.
;                       * Path B: scan Job PIDs for a newer process whose basename is $GC_S_GWPROCESS_GAME_EXE (Launch_WaitForPlayablePID).
;                  - On success the per-character mutex is **intentionally left open** to prevent re-launch; it is closed on error paths.
; Related........: AddOns_Out, Launch_ApplyMultiClientPatch, Launch_QuoteArg, Launch_WaitForPlayablePID, Security_AcquireFileMutex,
;                  Security_CloseMutex, Security_DecryptString, _WinAPI_AssignProcessToJobObject, _WinAPI_CloseHandle,
;                  _WinAPI_CreateJobObject, _WinAPI_CreateMutex, _WinAPI_GetLastError, CreateProcessW, ResumeThread,
;                  WaitForSingleObject
; ===============================================================================================================================
Func Launch_LaunchAccountFromINI($a_s_IniFile, $a_s_Character, $a_b_Restart = False)
    Local $l_i_Timeout = 10000
    Local $l_h_IniMutex = Security_AcquireFileMutex($a_s_IniFile, $l_i_Timeout)
    If $l_h_IniMutex = 0 Then Return 0

    Local $l_s_Email = IniRead($a_s_IniFile, $a_s_Character, "Email", "")
    Local $l_s_Pwd = Security_DecryptString(IniRead($a_s_IniFile, $a_s_Character, "Pwd", ""))
    Local $l_s_FilePath = IniRead($a_s_IniFile, $a_s_Character, "FilePath", "")
    
    Security_CloseMutex($l_h_IniMutex)

    If Not FileExists($l_s_FilePath) Then
        AddOns_Out("[ERR] Could not find Guild Wars executable (Gw.exe): " & $l_s_FilePath)
        Return 0
    EndIf

    Local $l_s_GameMutex = "AU3-Mutex-Window-Guild Wars-" & $a_s_Character
    If $a_b_Restart Then Security_CloseMutex($g_h_GameMutex)

    $g_h_GameMutex = _WinAPI_CreateMutex($l_s_GameMutex)
    If $g_h_GameMutex = 0 Then
        AddOns_Out("[ERR] Failed to create/open mutex object: " & $l_s_GameMutex)
        Return 0
    EndIf

    Local $l_i_LastErr = _WinAPI_GetLastError()
    If $l_i_LastErr = $GC_I_ERROR_ALREADY_EXISTS Then
        AddOns_Out("[ERR] Mutex object already exists: " & $l_s_GameMutex)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    AddOns_Out("[INIT] Launching account")
    AddOns_Out("[INIT] E-Mail: " & $l_s_Email)
    AddOns_Out("[INIT] Character: " & $a_s_Character)

    Local $l_s_Args = ' -fps 30'
    $l_s_Args &= ' -character ' & Launch_QuoteArg($a_s_Character)
    $l_s_Args &= ' -email ' & Launch_QuoteArg($l_s_Email)  
    $l_s_Args &= ' -password ' & Launch_QuoteArg($l_s_Pwd)

    Local $l_s_Cmd = Launch_QuoteArg($l_s_FilePath) & $l_s_Args

    If Not StringInStr($l_s_FilePath, '\') Then
        AddOns_Out("[ERR] Invalid File Path: " & $l_s_FilePath)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf
    Local $l_s_WorkingDir = StringRegExpReplace($l_s_FilePath, "^(.*\\).*?$", "$1")

    Local $l_d_StartupInfo = DllStructCreate($tagSTARTUPINFO)
    Local $l_d_ProcessInfo = DllStructCreate($tagPROCESS_INFORMATION)
    DllStructSetData($l_d_StartupInfo, "Size", DllStructGetSize($l_d_StartupInfo))

    Local $l_av_Result = DllCall("kernel32.dll", "bool", "CreateProcessW", _
        "wstr", $l_s_FilePath, _
        "wstr", $l_s_Cmd, _
        "ptr", 0, _
        "ptr", 0, _
        "bool", False, _
        "dword", $CREATE_SUSPENDED, _
        "ptr", 0, _
        "wstr", $l_s_WorkingDir, _
        "struct*", $l_d_StartupInfo, _
        "struct*", $l_d_ProcessInfo)

    If @error Or Not $l_av_Result[0] Then
        AddOns_Out("[ERR] Failed to launch process")
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    Local $l_h_Process = DllStructGetData($l_d_ProcessInfo, "hProcess")
    Local $l_h_Thread = DllStructGetData($l_d_ProcessInfo, "hThread")
    Local $l_i_PID = DllStructGetData($l_d_ProcessInfo, "ProcessId")

    Local $l_h_Job = _WinAPI_CreateJobObject()
    If @error Or $l_h_Job = 0 Then
        AddOns_Out("[ERR] Failed to create job object, PID-chain of launcher cannot be tracked")
        _WinAPI_CloseHandle($l_h_Thread)
        _WinAPI_CloseHandle($l_h_Process)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    If Not _WinAPI_AssignProcessToJobObject($l_h_Job, $l_h_Process) Then
        AddOns_Out("[ERR] Failed to assign process to job object")
        _WinAPI_CloseHandle($l_h_Thread)
        _WinAPI_CloseHandle($l_h_Process)
        _WinAPI_CloseHandle($l_h_Job)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    If Not Launch_ApplyMultiClientPatch($l_h_Process) Then
        AddOns_Out("[ERR] Failed to apply MultiClient patch")
        _WinAPI_CloseHandle($l_h_Thread)
        _WinAPI_CloseHandle($l_h_Process)
        _WinAPI_CloseHandle($l_h_Job)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    Local $l_av_Resume = DllCall("kernel32.dll", "dword", "ResumeThread", "handle", $l_h_Thread)
    If @error Or $l_av_Resume[0] = -1 Then
        AddOns_Out("[ERR] Failed to resume thread")
        _WinAPI_CloseHandle($l_h_Thread)
        _WinAPI_CloseHandle($l_h_Process)
        _WinAPI_CloseHandle($l_h_Job)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    Local $l_av_Wait = DllCall("kernel32.dll", "dword", "WaitForSingleObject", "handle", $l_h_Process, "dword", 0)
    If @error Or $l_av_Wait[0] <> $GC_I_WAIT_TIMEOUT Then
        AddOns_Out("[ERR] Process not running after resume")
        _WinAPI_CloseHandle($l_h_Thread)
        _WinAPI_CloseHandle($l_h_Process)
        _WinAPI_CloseHandle($l_h_Job)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    _WinAPI_CloseHandle($l_h_Thread)
    _WinAPI_CloseHandle($l_h_Process)

    Local $l_i_WindowGracePeriod = 20000
    Local $l_i_OverallTimeout = 600000
    Local $l_i_UpdatedPID = Launch_WaitForPlayablePID($l_i_PID, $l_h_Job, $l_i_WindowGracePeriod, $l_i_OverallTimeout)
    If @error Or $l_i_UpdatedPID = 0 Then
        AddOns_Out("[ERR] Failed to find playable Gw.exe")
        _WinAPI_CloseHandle($l_h_Job)
        Security_CloseMutex($g_h_GameMutex)
        Return 0
    EndIf

    _WinAPI_CloseHandle($l_h_Job)

    AddOns_Out("[INIT] Successfully launched account")
    AddOns_Out("[INIT] PID: " & $l_i_UpdatedPID)

    Return $l_i_UpdatedPID
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_QuoteArg
; Description....: Quotes a single command-line argument per Windows CommandLineToArgvW rules (handles spaces, quotes, and backslashes).
; Syntax.........: Launch_QuoteArg ( $a_s_ArgumentString )
; Parameters.....: $a_s_ArgumentString - Raw argument string to be safely quoted.
; Return values..: Success             - Properly quoted string suitable for inclusion in a Windows command line.
;                  Fast Path           - Returns input unchanged if it contains no whitespace or double quotes.
; Author.........: KleuTSchi
; Remarks........: - Implements the backslash/quote rules: N backslashes before a quote become 2N+1; trailing backslashes are doubled.
;                  - Only double quotes affect Windows argument parsing; single quotes are treated as normal characters.
;                  - Use for any user-supplied value (email, password, character, paths) to avoid parsing issues.
; Related........: CommandLineToArgvW, CreateProcessW
; ===============================================================================================================================
Func Launch_QuoteArg($a_s_ArgumentString)
    If $a_s_ArgumentString = "" Then Return '""'

    If Not StringRegExp($a_s_ArgumentString, '[\s"]') Then Return $a_s_ArgumentString

    Local $l_s_ResultQuoted = '"'
    Local $l_i_Index = 1
    Local $l_i_StringLength = StringLen($a_s_ArgumentString)

    While $l_i_Index <= $l_i_StringLength
        Local $l_i_BackslashCount = 0
        While $l_i_Index <= $l_i_StringLength And StringMid($a_s_ArgumentString, $l_i_Index, 1) = '\'
            $l_i_BackslashCount += 1
            $l_i_Index += 1
        WEnd

        If $l_i_Index > $l_i_StringLength Then
            $l_s_ResultQuoted &= _StringRepeat('\', $l_i_BackslashCount * 2)
            ExitLoop
        EndIf

        Local $l_s_CurrentChar = StringMid($a_s_ArgumentString, $l_i_Index, 1)

        If $l_s_CurrentChar = '"' Then
            $l_s_ResultQuoted &= _StringRepeat('\', $l_i_BackslashCount * 2 + 1) & '"'
        Else
            $l_s_ResultQuoted &= _StringRepeat('\', $l_i_BackslashCount) & $l_s_CurrentChar
        EndIf

        $l_i_Index += 1
    WEnd

    $l_s_ResultQuoted &= '"'
    Return $l_s_ResultQuoted
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_ApplyMultiClientPatch
; Description....: Scans the target process memory for a byte pattern, computes the patch address, and writes a 4-byte payload to enable multiclient.
; Syntax.........: Launch_ApplyMultiClientPatch ( $a_h_Process )
; Parameters.....: $a_h_Process - Handle to the target process with PROCESS_VM_READ/WRITE/OPERATION and QUERY_INFORMATION rights.
; Return values..: Success  - True  (pattern found, memory protected, 4 bytes written, protection restored).
;                  Failure  - False (query/read failed repeatedly, pattern not found, validation read failed, or write/protect failed).
; Author.........: KleuTSchi, Greg
; Remarks........: - Iterates committed, readable/executable regions via VirtualQueryEx; reads in blocks; performs byte-for-byte match.
;                  - Validates the computed patch address with a 4-byte read, temporarily sets PAGE_EXECUTE_READWRITE, writes payload, restores protection.
;                  - Assumes a fixed pattern and offset relative to the match; fragile across game builds/updates.
;                  - Caller must provide a suspended process and ensure proper cleanup on failure.
; Related........: _WinAPI_ReadProcessMemory, _WinAPI_VirtualProtectEx, VirtualQueryEx, WriteProcessMemory
; ===============================================================================================================================
Func Launch_ApplyMultiClientPatch($a_h_Process)
    Local $l_ax_Pattern[19] = [0x56, 0x57, 0x68, 0x00, 0x01, 0x00, 0x00, 0x89, 0x85, _
                              0xF4, 0xFE, 0xFF, 0xFF, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00]
    Local $l_ax_Patch[4] = [0x31, 0xC0, 0x90, 0xC3]

    Local $l_b_Found = False
    Local $l_p_PatchAddr = 0
    Local $l_i_BlockSize = 0x10000

    Local $l_p_CurrAddr = 0x10000
    Local $l_p_MaxAddr = 0x7FFFFFFF
    Local $l_i_ConsecutiveFailures = 0

    While $l_p_CurrAddr < $l_p_MaxAddr
        Local $l_d_MemInfo = DllStructCreate("ptr BaseAddress;ptr AllocationBase;dword AllocationProtect;ptr RegionSize;dword State;dword Protect;dword Type")
        Local $l_amx_QueryResult = DllCall("kernel32.dll", "ulong_ptr", "VirtualQueryEx", _
            "handle", $a_h_Process, _
            "ptr", $l_p_CurrAddr, _
            "struct*", $l_d_MemInfo, _
            "ulong_ptr", DllStructGetSize($l_d_MemInfo))

        If @error Or $l_amx_QueryResult[0] = 0 Then
            $l_p_CurrAddr += 0x10000
            $l_i_ConsecutiveFailures += 1
            If $l_i_ConsecutiveFailures > 100 Then ExitLoop
            ContinueLoop
        EndIf

        $l_i_ConsecutiveFailures = 0

        Local $l_p_RegionBase = DllStructGetData($l_d_MemInfo, "BaseAddress")
        Local $l_i_RegionSize = DllStructGetData($l_d_MemInfo, "RegionSize")
        Local $l_i_State = DllStructGetData($l_d_MemInfo, "State")
        Local $l_i_Protect = DllStructGetData($l_d_MemInfo, "Protect")

        If $l_i_State = 0x1000 And BitAND($l_i_Protect, 0xEE) > 0 Then
            For $l_i_Offset = 0 To $l_i_RegionSize - 1 Step $l_i_BlockSize
                Local $l_i_ReadSize = $l_i_BlockSize
                If $l_i_Offset + $l_i_ReadSize > $l_i_RegionSize Then
                    $l_i_ReadSize = $l_i_RegionSize - $l_i_Offset
                EndIf

                Local $l_d_Buffer = DllStructCreate("byte[" & $l_i_ReadSize & "]")
                Local $l_i_PatternSize = UBound($l_ax_Pattern)
                Local $l_i_BytesRead = 0

                If _WinAPI_ReadProcessMemory($a_h_Process, $l_p_RegionBase + $l_i_Offset, $l_d_Buffer, $l_i_ReadSize, $l_i_BytesRead) And $l_i_BytesRead >= $l_i_PatternSize Then
                    For $l_i_Pos = 1 To ($l_i_BytesRead - $l_i_PatternSize)
                        Local $l_b_Match = True
                        For $l_i_Byte = 0 To $l_i_PatternSize - 1
                            If DllStructGetData($l_d_Buffer, 1, $l_i_Pos + $l_i_Byte) <> $l_ax_Pattern[$l_i_Byte] Then
                                $l_b_Match = False
                                ExitLoop
                            EndIf
                        Next

                        If $l_b_Match Then
                            $l_p_PatchAddr = $l_p_RegionBase + $l_i_Offset + ($l_i_Pos - 1) - 0x1A
                            ExitLoop 3
                        EndIf
                    Next
                EndIf
            Next
        EndIf
        $l_p_CurrAddr = $l_p_RegionBase + $l_i_RegionSize
    WEnd

    Local $l_d_TestRead = DllStructCreate("byte[4]")
    Local $l_i_TestReadBytes = 0
    If Not _WinAPI_ReadProcessMemory($a_h_Process, $l_p_PatchAddr, $l_d_TestRead, 4, $l_i_TestReadBytes) Or $l_i_TestReadBytes <> 4 Then
        Return False
    EndIf

    Local $l_i_OldProtect = 0
    _WinAPI_VirtualProtectEx($a_h_Process, $l_p_PatchAddr, 4, $PAGE_EXECUTE_READWRITE, $l_i_OldProtect)

    Local $l_d_Payload = DllStructCreate("byte[4]")
    For $l_i_Idx = 0 To 3
        DllStructSetData($l_d_Payload, 1, $l_ax_Patch[$l_i_Idx], $l_i_Idx + 1)
    Next

    Local $l_amx_WriteResult = DllCall("kernel32.dll", "bool", "WriteProcessMemory", _
        "handle", $a_h_Process, _
        "ptr", $l_p_PatchAddr, _
        "struct*", $l_d_Payload, _
        "ulong_ptr", 4, _
        "ulong_ptr*", 0)

    _WinAPI_VirtualProtectEx($a_h_Process, $l_p_PatchAddr, 4, $l_i_OldProtect, $l_i_OldProtect)

    If @error Or Not IsArray($l_amx_WriteResult) Or $l_amx_WriteResult[5] <> 4 Then
        Return False
    EndIf

    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _WinAPI_VirtualProtectEx
; Description....: Wrapper around VirtualProtectEx to change memory protection on a region in a remote process and return the previous protection.
; Syntax.........: _WinAPI_VirtualProtectEx ( $a_h_Process, $a_p_Address, $a_i_Size, $a_i_NewProtection, ByRef $a_i_OldProtection )
; Parameters.....: $a_h_Process      - Handle to target process.
;                  $a_p_Address      - Base address of region to change.
;                  $a_i_Size         - Size of region in bytes.
;                  $a_i_NewProtection- New protection flags (e.g., $PAGE_EXECUTE_READWRITE).
;                  $a_i_OldProtection- [ByRef] Receives previous protection value on success.
; Return values..: Success           - True  (previous protection returned via $a_i_OldProtection).
;                  Failure           - False (DllCall failed or API returned zero). @error/@extended propagated on DllCall failure.
; Author.........: KleuTSchi, Greg
; Remarks........: - Use to temporarily relax protections before WriteProcessMemory, then restore to $a_i_OldProtection afterwards.
;                  - Caller must ensure page-aligned parameters/sizes as required by VirtualProtectEx semantics.
; Related........: _WinAPI_ReadProcessMemory, VirtualProtectEx, WriteProcessMemory
; ===============================================================================================================================
Func _WinAPI_VirtualProtectEx($a_h_Process, $a_p_Address, $a_i_Size, $a_i_NewProtection, ByRef $a_i_OldProtection)
    Local $l_amx_Result = DllCall("kernel32.dll", "bool", "VirtualProtectEx", _
        "handle", $a_h_Process, _
        "ptr", $a_p_Address, _
        "ulong_ptr", $a_i_Size, _
        "dword", $a_i_NewProtection, _
        "dword*", 0)

    If @error Then
        Return SetError(@error, @extended, False)
    EndIf

    $a_i_OldProtection = $l_amx_Result[5]

    Return $l_amx_Result[0] <> 0
EndFunc
#EndRegion GWProcess

#Region DesktopGrid
; #CONSTANTS# ===================================================================================================================
; Grid configuration
; Note: Mutex acquisition is performed via Security_AcquireFileMutex($GC_S_GRID_INI, …) from Security.au3.
;       That helper derives a name from the INI path and (by default) uses the Local\ namespace. If you need
;       cross-session locking, adjust the Security.au3 implementation to use the Global\ namespace.
Global Const $GC_I_GRID_COLS = 3 ; Number of columns
Global Const $GC_I_GRID_ROWS = 2 ; Number of rows
Global Const $GC_S_GRID_INI = @ScriptDir & "\Config\grid.ini" ; Writable INI path
Global Const $GC_S_GRID_DELIMITER = "|" ; PID list separator
; ===============================================================================================================================

; #GLOBALS# =====================================================================================================================
Global $g_i_GridAllocatedSlot = -1 ; Last reserved slot; -1 = none
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_AllocateGridSlot
; Description....: Reserves the earliest (row-major) grid cell by selecting the slot with the smallest layer depth,
;                  prunes dead PIDs from all slots, appends the current PID to the chosen slot in the INI, and stores
;                  the reserved slot index in $g_i_GridAllocatedSlot.
; Syntax.........: Launch_AllocateGridSlot ( )
; Parameters.....: None
; Return values..: Success   - Slot index (integer 0..($GC_I_GRID_COLS * $GC_I_GRID_ROWS - 1)).
;                  Failure   - -1 and sets:
;                               @error = 1  -> Acquiring INI mutex via Security_AcquireFileMutex() failed (no handle).
;                               @error = 3  -> No slot could be chosen (unexpected).
;                               @error = 4  -> IniWrite failed when persisting the updated slot list.
; Author.........: KleuTSchi
; Remarks........: - INI access is synchronized via Security_AcquireFileMutex($GC_S_GRID_INI, timeout) /
;                    Security_CloseMutex() from "Security.au3".
;                  - Treats WAIT_OBJECT_0 and WAIT_ABANDONED as success inside Security.au3; stale entries are self-healed
;                    by pruning dead PIDs before selection.
;                  - Uses $g_i_GWProcessId as the PID to append; caller must set it beforehand.
;                  - INI layout: Section "Slots", keys "S0".."S{N-1}" under $GC_S_GRID_INI.
; Related........: Launch_GetGridSlotPosition, Launch_GridPIDListAppend, Launch_GridPIDListPrune, Launch_MoveWindowToGridSlot,
;                  Launch_ReleaseGridSlot, Security_AcquireFileMutex, Security_CloseMutex
; ===============================================================================================================================
Func Launch_AllocateGridSlot()
    Local $l_i_Timeout = 10000
    Local $l_h_Mutex = Security_AcquireFileMutex($GC_S_GRID_INI, $l_i_Timeout)
    If $l_h_Mutex = 0 Then Return SetError(1, 0, -1)

    Local $l_i_PID = $g_i_GWProcessId

    Local $l_i_Total = $GC_I_GRID_COLS * $GC_I_GRID_ROWS
    Local $l_ai_Depth[$l_i_Total]

    Local $i
    For $i = 0 To $l_i_Total - 1
        Local $l_s_Old = IniRead($GC_S_GRID_INI, "Slots", "S" & $i, "")
        Local $l_s_Pruned = Launch_GridPIDListPrune($l_s_Old)
        If $l_s_Pruned <> $l_s_Old Then
            If $l_s_Pruned = "" Then
                IniDelete($GC_S_GRID_INI, "Slots", "S" & $i)
            Else
                IniWrite($GC_S_GRID_INI, "Slots", "S" & $i, $l_s_Pruned)
            EndIf
        EndIf
        $l_ai_Depth[$i] = Launch_GridPIDListCount($l_s_Pruned)
    Next

    Local $l_i_MinDepth = 0x7FFFFFFF, $l_i_Slot = -1
    For $i = 0 To $l_i_Total - 1
        If $l_ai_Depth[$i] < $l_i_MinDepth Then
            $l_i_MinDepth = $l_ai_Depth[$i]
            $l_i_Slot = $i
        EndIf
    Next

    If $l_i_Slot = -1 Then
        Security_CloseMutex($l_h_Mutex)
        Return SetError(3, 0, -1)
    EndIf

    Local $l_s_List = IniRead($GC_S_GRID_INI, "Slots", "S" & $l_i_Slot, "")
    Local $l_s_NewList = Launch_GridPIDListAppend($l_s_List, $l_i_PID)
    Local $l_b_Write = IniWrite($GC_S_GRID_INI, "Slots", "S" & $l_i_Slot, $l_s_NewList)

    Security_CloseMutex($l_h_Mutex)

    If Not $l_b_Write Then
        Return SetError(4, 0, -1)
    EndIf

    $g_i_GridAllocatedSlot = $l_i_Slot
    Return $l_i_Slot
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_ReleaseGridSlot
; Description....: Removes the current PID from the specified grid slot's list in the INI, deleting the key if the list
;                  becomes empty. Intended to be called on clean shutdown to relinquish the reservation.
; Syntax.........: Launch_ReleaseGridSlot ( $a_i_Slot )
; Parameters.....: $a_i_Slot  - Slot index to release (integer 0..($GC_I_GRID_COLS * $GC_I_GRID_ROWS - 1)).
; Return values..: None       - (No explicit @error is set.)
; Author.........: KleuTSchi
; Remarks........: - Synchronizes INI updates via Security_AcquireFileMutex($GC_S_GRID_INI, timeout) /
;                    Security_CloseMutex() from "Security.au3".
;                  - If the mutex cannot be acquired (function returns 0), this implementation proceeds best-effort without
;                    locking (no early return) to avoid leaking allocations on shutdown.
;                  - Uses $g_i_GWProcessId as the PID to remove; must match what was appended on allocation.
;                  - If the slot list becomes empty, the "S{index}" key is deleted.
; Related........: Launch_AllocateGridSlot, Launch_RemoveGridPIDFromList, Launch_GridPIDListPrune, Security_AcquireFileMutex,
;                  Security_CloseMutex
; ===============================================================================================================================
Func Launch_ReleaseGridSlot($a_i_Slot)
    Local $l_i_Timeout = 5000
    Local $l_h_Mutex = Security_AcquireFileMutex($GC_S_GRID_INI, $l_i_Timeout)

    Local $l_i_PID = $g_i_GWProcessId

    Local $l_s_Key  = "S" & $a_i_Slot
    Local $l_s_List = IniRead($GC_S_GRID_INI, "Slots", $l_s_Key, "")

    If $l_s_List <> "" Then
        Local $l_s_NewList = Launch_RemoveGridPIDFromList($l_s_List, $l_i_PID)
        If $l_s_NewList = "" Then
            IniDelete($GC_S_GRID_INI, "Slots", $l_s_Key)
        Else
            IniWrite($GC_S_GRID_INI, "Slots", "S" & $a_i_Slot, $l_s_NewList)
        EndIf
    EndIf

    Security_CloseMutex($l_h_Mutex)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_MoveWindowToGridSlot
; Description....: Moves/resizes a window to exactly fill the target grid cell computed from the slot index.
; Syntax.........: Launch_MoveWindowToGridSlot ( $a_h_Wnd, $a_i_Slot )
; Parameters.....: $a_h_Wnd   - HWND/handle of the target window.
;                  $a_i_Slot  - Slot index (integer 0..($GC_I_GRID_COLS * $GC_I_GRID_ROWS - 1)).
; Return values..: None       - (WinMove's success/failure is not propagated.)
; Author.........: KleuTSchi
; Remarks........: - Uses the primary desktop work area (0,0 to @DesktopWidth x @DesktopHeight).
;                  - Slot rectangles are computed by Launch_GetGridSlotPosition (row-major; cols=$GC_I_GRID_COLS, rows=$GC_I_GRID_ROWS).
; Related........: Launch_GetGridSlotPosition
; ===============================================================================================================================
Func Launch_MoveWindowToGridSlot($a_h_Wnd, $a_i_Slot)
    Local $l_ai_Rect = Launch_GetGridSlotPosition($a_i_Slot)
    WinMove($a_h_Wnd, "", $l_ai_Rect[0], $l_ai_Rect[1], $l_ai_Rect[2], $l_ai_Rect[3], 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_GetGridSlotPosition
; Description....: Calculates the rectangle (x, y, width, height) of a grid cell for the given slot index on the primary
;                  desktop, splitting the screen into $GC_I_GRID_COLS by $GC_I_GRID_ROWS cells.
; Syntax.........: Launch_GetGridSlotPosition ( $a_i_Slot )
; Parameters.....: $a_i_Slot  - Slot index (integer 0..($GC_I_GRID_COLS * $GC_I_GRID_ROWS - 1)).
; Return values..: Success    - 1D array [x, y, width, height].
;                  Failure    - n/a (no @error set; caller must ensure the slot index is valid).
; Author.........: KleuTSchi
; Remarks........: - Layout is row-major: row = Floor(slot / $GC_I_GRID_COLS), col = Mod(slot, $GC_I_GRID_COLS).
; Related........: Launch_MoveWindowToGridSlot
; ===============================================================================================================================
Func Launch_GetGridSlotPosition($a_i_Slot)
    Local $l_i_Left = 0, $l_i_Top = 0
    Local $l_i_Width = @DesktopWidth, $l_i_Height = @DesktopHeight

    Local $l_i_CellWidth  = Floor($l_i_Width  / $GC_I_GRID_COLS)
    Local $l_i_CellHeight = Floor($l_i_Height / $GC_I_GRID_ROWS)

    Local $l_i_Row = Floor($a_i_Slot / $GC_I_GRID_COLS)
    Local $l_i_Col = Mod($a_i_Slot, $GC_I_GRID_COLS)

    Local $l_i_X = $l_i_Left + ($l_i_Col * $l_i_CellWidth)
    Local $l_i_Y = $l_i_Top  + ($l_i_Row * $l_i_CellHeight)

    Local $l_ai_SlotPos[4] = [$l_i_X, $l_i_Y, $l_i_CellWidth, $l_i_CellHeight]
    Return $l_ai_SlotPos
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_GridPIDListCount
; Description....: Returns the number of entries in a PID list string using $GC_S_GRID_DELIMITER as separator.
; Syntax.........: Launch_GridPIDListCount ( $a_s_List )
; Parameters.....: $a_s_List  - PID list string (e.g., "123|456|789") or empty string.
; Return values..: Success    - Integer count (0..N).
;                  Failure    - 0 (also returned for empty input; no @error set).
; Author.........: KleuTSchi
; Remarks........: - Intended for measuring the current layer depth of a slot.
; Related........: Launch_GridPIDListAppend, Launch_GridPIDListPrune
; ===============================================================================================================================
Func Launch_GridPIDListCount($a_s_List)
    If $a_s_List = "" Then Return 0
    Local $l_as_PIDs = StringSplit($a_s_List, $GC_S_GRID_DELIMITER)
    Return $l_as_PIDs[0]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_GridPIDListPrune
; Description....: Removes invalid or non-existent PIDs from a delimited PID list string and returns the compacted list.
; Syntax.........: Launch_GridPIDListPrune ( $a_s_List )
; Parameters.....: $a_s_List  - PID list string (e.g., "123|456|789") or empty string.
; Return values..: Success    - Pruned PID list string (may be empty).
;                  Failure    - "" (no @error set).
; Author.........: KleuTSchi
; Remarks........: - Filters out zero-valued PIDs and PIDs for which ProcessExists() returns False.
;                  - Preserves original order of surviving PIDs; delimiter is $GC_S_GRID_DELIMITER.
; Related........: Launch_GridPIDListCount, Launch_RemoveGridPIDFromList
; ===============================================================================================================================
Func Launch_GridPIDListPrune($a_s_List)
    If $a_s_List = "" Then Return ""

    Local $l_as_PIDs = StringSplit($a_s_List, $GC_S_GRID_DELIMITER)
    Local $l_s_NewList = ""
    Local $i
    For $i = 1 To $l_as_PIDs[0]
        Local $l_i_PID = Number($l_as_PIDs[$i])
        If $l_i_PID <> 0 And ProcessExists($l_i_PID) Then
            If $l_s_NewList = "" Then
                $l_s_NewList = $l_i_PID
            Else
                $l_s_NewList &= $GC_S_GRID_DELIMITER & $l_i_PID
            EndIf
        EndIf
    Next
    Return $l_s_NewList
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_RemoveGridPIDFromList
; Description....: Removes a specific PID from a delimited PID list string and returns the updated list.
; Syntax.........: Launch_RemoveGridPIDFromList ( $a_s_List, $a_i_PID )
; Parameters.....: $a_s_List  - PID list string (e.g., "123|456|789") or empty string.
;                  $a_i_PID   - PID to remove (integer).
; Return values..: Success    - Updated PID list string (may be empty if the last PID was removed).
;                  Failure    - "" (no @error set).
; Author.........: KleuTSchi
; Remarks........: - Comparison uses numeric equality; delimiter is $GC_S_GRID_DELIMITER.
; Related........: Launch_GridPIDListPrune, Launch_GridPIDListAppend
; ===============================================================================================================================
Func Launch_RemoveGridPIDFromList($a_s_List, $a_i_PID)
    If $a_s_List = "" Then Return ""

    Local $l_as_PIDs = StringSplit($a_s_List, $GC_S_GRID_DELIMITER)
    Local $l_s_NewList = ""
    Local $i
    For $i = 1 To $l_as_PIDs[0]
        If Number($l_as_PIDs[$i]) <> Number($a_i_PID) Then
            If $l_s_NewList = "" Then
                $l_s_NewList = $l_as_PIDs[$i]
            Else
                $l_s_NewList &= $GC_S_GRID_DELIMITER & $l_as_PIDs[$i]
            EndIf
        EndIf
    Next
    Return $l_s_NewList
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Launch_GridPIDListAppend
; Description....: Appends a single numeric value to a delimited list string using $GC_S_GRID_DELIMITER.
; Syntax.........: Launch_GridPIDListAppend ( $a_s_List, $a_i_Value )
; Parameters.....: $a_s_List  - Existing list string (may be empty).
;                  $a_i_Value - Value to append (typically a PID; integer).
; Return values..: Success    - New list string (either "$a_i_Value" if input was empty, or "old|value").
;                  Failure    - n/a (no @error set).
; Author.........: KleuTSchi
; Remarks........: - Does not validate $a_i_Value; caller is responsible for passing a meaningful number.
; Related........: Launch_GridPIDListCount, Launch_RemoveGridPIDFromList
; ===============================================================================================================================
Func Launch_GridPIDListAppend($a_s_List, $a_i_Value)
    If $a_s_List = "" Then
        Return $a_i_Value
    Else
        Return $a_s_List & $GC_S_GRID_DELIMITER & $a_i_Value
    EndIf
EndFunc
#EndRegion DesktopGrid