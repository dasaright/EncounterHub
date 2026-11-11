#include-once

; #INCLUDES# ====================================================================================================================
; Note: All native AutoIt includes are covered by GwAu3/API/_GwAu3.au3 which should always be included in the main script.
;       The same applies to GwAu3 API-specific includes. Other includes containing script-specific files are covered 
;       by _EncounterRebuilt.au3.
;
; #include <Crypt.au3>
; #include <StringConstants.au3>
; #include <WinAPI.au3>
; ===============================================================================================================================

#Region WinAPI
; #GLOBALS - WINAPI# ============================================================================================================
; WaitForSingleObject return values
Global Const $GC_I_WAIT_OBJECT_0 = 0x00000000 ; Signaled: lock acquired
Global Const $GC_I_WAIT_ABANDONED = 0x00000080 ; Abandoned mutex acquired (previous owner exited)
; ===============================================================================================================================
#EndRegion WinAPI

#Region Encryption
; #GLOBALS - ENCRYPTION# ========================================================================================================
; Encryption markers & key material (used by Security_EncryptString / Security_DecryptString)
Global Const $GC_S_SEC_TAG = "{SEC}" ; Prefix tag placed before encrypted hex payload
Global Const $GC_S_SEC_TAG_LE = StringLen($GC_S_SEC_TAG) ; Cached tag length for quick prefix checks
Global Const $GC_S_SEC_KEY = @ScriptName ; Symmetric key/entropy seed (change to rotate keys)
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: Security_EncryptString
; Description....: Encrypts a UTF-8 string with AES-256 (AutoIt Crypt UDF) and returns a tagged hex blob for INI storage.
; Syntax.........: Security_EncryptString ( $a_s_Plain )
; Parameters.....: $a_s_Plain  - Plaintext. If already tagged with $GC_S_SEC_TAG, it is returned unchanged (idempotent).
; Return values..: Success     - $GC_S_SEC_TAG & <hex_without_0x>
;                  Failure     - "" with @error = 1 (bad input or encryption failure).
; Author.........: KleuTSchi
; Remarks........: Requires '_Crypt_Startup()' to have been called once by the app. Uses @ScriptName (see $GC_S_SEC_KEY) as key.
; Related........: Security_DecryptString, _Crypt_EncryptData, _Crypt_Startup
; ===============================================================================================================================
Func Security_EncryptString($a_s_Plain)
    If Not IsString($a_s_Plain) Then Return SetError(1, 0, "")
    If StringLeft($a_s_Plain, $GC_S_SEC_TAG_LE) = $GC_S_SEC_TAG Then Return $a_s_Plain
    If $a_s_Plain = "" Then Return ""

    Local $l_x_UTF8 = StringToBinary($a_s_Plain, $SB_UTF8)
    Local $l_s_Hex = _Crypt_EncryptData($l_x_UTF8, $GC_S_SEC_KEY, $CALG_AES_256)
    If @error Or $l_s_Hex = "" Then Return SetError(1, 0, "")

    Return $GC_S_SEC_TAG & StringTrimLeft($l_s_Hex, 2)
EndFunc 

; #FUNCTION# ====================================================================================================================
; Name...........: Security_DecryptString
; Description....: Decrypts a tagged hex blob produced by Security_EncryptString back to UTF-8 text.
; Syntax.........: Security_DecryptString ( $a_s_Crypt )
; Parameters.....: $a_s_Crypt  - Either plaintext (returned as-is) or $GC_S_SEC_TAG & <hex_without_0x>.
; Return values..: Success     - Decrypted plaintext.
;                  Failure     - Original input with @error = 2 (decryption failed).
; Author.........: KleuTSchi
; Remarks........: Graceful passthrough means existing plaintext INIs continue to work.
; Related........: Security_EncryptString, _Crypt_DecryptData
; ===============================================================================================================================
Func Security_DecryptString($a_s_Crypt)
    If Not IsString($a_s_Crypt) Then Return $a_s_Crypt
    If StringLeft($a_s_Crypt, $GC_S_SEC_TAG_LE) <> $GC_S_SEC_TAG Then Return $a_s_Crypt

    Local $l_s_Hex = "0x" & StringMid($a_s_Crypt, $GC_S_SEC_TAG_LE + 1)
    Local $l_x_Plain = _Crypt_DecryptData($l_s_Hex, $GC_S_SEC_KEY, $CALG_AES_256)
    If @error Or $l_x_Plain = "" Then Return SetError(2, 0, $a_s_Crypt)

    Return BinaryToString($l_x_Plain, $SB_UTF8)
EndFunc
#EndRegion Encryption

#Region FileLock
; #FUNCTION# ====================================================================================================================
; Name...........: Security_PathToMutexName
; Description....: Derives a safe mutex name from a file path by hashing the lowercase path with MD5.
; Syntax.........: Security_PathToMutexName ( $a_s_Path )
; Parameters.....: $a_s_Path   - Absolute or relative file path.
; Return values..: Success     - "AU3-Mutex-" & <32-hex MD5>.
; Author.........: KleuTSchi
; Remarks........: Namespace is local session by default. If cross-session locking is needed, prefix with "Global\".
; Related........: Security_AcquireFileMutex
; ===============================================================================================================================
Func Security_PathToMutexName($a_s_Path)
    Local $l_s_Hash = _Crypt_HashData(StringLower($a_s_Path), $CALG_MD5)
    Return "AU3-Mutex-" & StringTrimLeft($l_s_Hash, 2)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Security_AcquireFileMutex
; Description....: Creates/opens a named mutex derived from a path and waits up to timeout to acquire it.
; Syntax.........: Security_AcquireFileMutex ( $a_s_Path, $a_i_Timeout )
; Parameters.....: $a_s_Path    - File path the lock represents.
;                  $a_i_Timeout - Wait timeout in milliseconds.
; Return values..: Success      - Mutex handle (non-zero) that you MUST release via Security_CloseMutex().
;                  Failure      - -1 with:
;                                 @error = 1  -> CreateMutex failed.
;                                 @error = 2  -> Wait failed or timed out (neither WAIT_OBJECT_0 nor WAIT_ABANDONED).
; Author.........: KleuTSchi
; Remarks........: Treats WAIT_ABANDONED as success to recover from crashed owners. Use in a small critical section
;                  around IniRead/IniWrite to serialize file I/O across processes.
; Related........: Security_CloseMutex, _WinAPI_CreateMutex, _WinAPI_WaitForSingleObject
; ===============================================================================================================================
Func Security_AcquireFileMutex($a_s_Path, $a_i_Timeout)
    Local $l_s_Mutex = Security_PathToMutexName($a_s_Path)
    Local $l_av_Create = _WinAPI_CreateMutex($l_s_Mutex)
    If @error Or $l_av_Create = 0 Then
        Return SetError(1, 0, -1)
    EndIf
    Local $l_h_Mutex = $l_av_Create

    Local $l_av_Wait = _WinAPI_WaitForSingleObject($l_h_Mutex, $a_i_Timeout)
    If @error Or ($l_av_Wait <> $GC_I_WAIT_OBJECT_0 And $l_av_Wait <> $GC_I_WAIT_ABANDONED) Then
        _WinAPI_CloseHandle($l_h_Mutex)
        Return SetError(2, 0, -1)
    EndIf

    Return $l_h_Mutex
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Security_CloseMutex
; Description....: Releases and closes a mutex handle previously returned by Security_AcquireFileMutex.
; Syntax.........: Security_CloseMutex ( $a_h_Mutex )
; Parameters.....: $a_h_Mutex   - Mutex handle.
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Always call this in a finally/cleanup path to avoid starving other processes.
; Related........: Security_AcquireFileMutex, _WinAPI_CloseHandle, _WinAPI_ReleaseMutex
; ===============================================================================================================================
Func Security_CloseMutex(ByRef $a_h_Mutex)
    If $a_h_Mutex = 0 Then Return

    _WinAPI_ReleaseMutex($a_h_Mutex)
    _WinAPI_CloseHandle($a_h_Mutex)
    $a_h_Mutex = 0
EndFunc
#EndRegion FileLock