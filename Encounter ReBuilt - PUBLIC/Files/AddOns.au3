#include-once

#Region DllStructs
; #GLOBALS - OFFSETS# ===========================================================================================================
;PartyInfo Offsets
Global Const $GC_I_STRIDE_PARTY_PLAYER_ARRAY = 0xC
Global Const $GC_I_STRIDE_PARTY_HERO_ARRAY = 0x18
Global Const $GC_I_STRIDE_PARTY_HENCHMAN_ARRAY = 0x34
;PlayerInfo Offsets
Global Const $GC_I_STRIDE_WORLD_PLAYER_ARRAY = 0x50
Global Const $GC_I_OFFSET_PLAYER_APPEARANCE_BITMAP = 0x10
Global Const $GC_I_OFFSET_PLAYER_FLAGS = 0x14
Global Const $GC_I_OFFSET_PLAYER_PRIMARY = 0x18
Global Const $GC_I_OFFSET_PLAYER_SECONDARY = 0x1C
Global Const $GC_I_OFFSET_PLAYER_NAME = 0x28
Global Const $GC_I_OFFSET_PLAYER_PARTY_LEADER_PLAYERNUMBER = 0x2C
Global Const $GC_I_OFFSET_PLAYER_ACTIVE_TITLE = 0x30
Global Const $GC_I_OFFSET_PLAYER_ACTIVE_CHALLENGE = 0x34
Global Const $GC_I_OFFSET_PLAYER_PLAYERNUMBER = 0x38
Global Const $GC_I_OFFSET_PLAYER_PARTY_SIZE = 0x3C 
; AgentInfo Offsets
Global Const $GC_I_OFFSET_AGENT_POS_X = 0x74
Global Const $GC_I_OFFSET_AGENT_POS_Y = 0x78
Global Const $GC_I_OFFSET_AGENT_TYPE = 0x9C
Global Const $GC_I_OFFSET_AGENT_MOVE_X = 0xA0
Global Const $GC_I_OFFSET_AGENT_MOVE_Y = 0xA4
Global Const $GC_I_OFFSET_AGENT_OWNER = 0xC4
Global Const $GC_I_OFFSET_AGENT_ITEM_ID = 0xC8
Global Const $GC_I_OFFSET_AGENT_PLAYERNUMBER = 0xF4
Global Const $GC_I_OFFSET_AGENT_ENERGY_PERCENT = 0x120
Global Const $GC_I_OFFSET_AGENT_ENERGY_MAX = 0x124
Global Const $GC_I_OFFSET_AGENT_HP_PERCENT = 0x134
Global Const $GC_I_OFFSET_AGENT_EFFECTS = 0x13C
Global Const $GC_I_OFFSET_AGENT_MODEL_STATE = 0x158
Global Const $GC_I_OFFSET_AGENT_ALLEGIANCE = 0x1B5
Global Const $GC_I_OFFSET_AGENT_WEAPON_TYPE = 0x1B6
Global Const $GC_I_OFFSET_AGENT_CAST = 0x1B8
; SkillbarInfo Offsets
Global Const $GC_I_STRIDE_SKILLBAR_ARRAY = 0xBC
Global Const $GC_I_OFFSET_SKILLBAR_CASTING = 0xB0
Global Const $GC_I_STRIDE_SKILLSLOTS = 0x14
Global Const $GC_I_OFFSET_SKILLSLOT_ADRENALINE = 0x4
Global Const $GC_I_OFFSET_SKILLSLOT_RECHARGE = 0xC
; Item Offsets
Global Const $GC_I_OFFSET_ITEM_EXTRA_ID = 0x22
Global Const $GC_I_OFFSET_ITEM_FLAGS = 0x28
Global Const $GC_I_OFFSET_ITEM_MODEL_ID = 0x2C
Global Const $GC_I_OFFSET_ITEM_RARITY = 0x38
Global Const $GC_I_OFFSET_ITEM_QUANTITY = 0x4C
Global Const $GC_I_OFFSET_ITEM_BAGPTR = 0xC
; ===============================================================================================================================

; #GLOBALS - DLLSTRUCTS# ========================================================================================================
; Agent - PlayerInfo
Global $g_d_PlayerStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_ENERGY_PERCENT  & "];float energyPercent;dword energyMax;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_EFFECTS - ($GC_I_OFFSET_AGENT_ENERGY_MAX + 4)) & "];dword effects;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_MODEL_STATE - ($GC_I_OFFSET_AGENT_EFFECTS + 4)) & "];dword modelState;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_CAST - ($GC_I_OFFSET_AGENT_MODEL_STATE + 4)) & "];short cast" _
)
Global $g_i_PlayerStructSize = DllStructGetSize($g_d_PlayerStruct)
; Agent - MoveXY
Global $g_d_MoveXYStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_MOVE_X & "];float moveX; float moveY" _
)
Global $g_i_MoveXYStructSize = DllStructGetSize($g_d_MoveXYStruct)
; Agent - PosXY
Global $g_d_PosXYStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_POS_X & "];float posX; float posY" _
)
Global $g_i_PosXYStructSize = DllStructGetSize($g_d_PosXYStruct)
; Agent - Casting
Global $g_d_CastStateStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_MODEL_STATE & "];dword modelState;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_CAST - ($GC_I_OFFSET_AGENT_MODEL_STATE + 4)) & "];short cast" _
)
Global $g_i_CastStateStructSize = DllStructGetSize($g_d_CastStateStruct)
; Agent - Moving
Global $g_d_MoveStateStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_MOVE_X & "];float moveX;float moveY" & _
    "byte[" & ($GC_I_OFFSET_AGENT_MODEL_STATE - ($GC_I_OFFSET_AGENT_MOVE_Y + 4)) & "];dword modelState" _
)
Global $g_i_MoveStateStructSize = DllStructGetSize($g_d_MoveStateStruct)
; Agent - Energy
Global $g_d_EnergyStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_ENERGY_PERCENT & "];float energyPercent;dword energyMax" _
)
Global $g_i_EnergyStructSize = DllStructGetSize($g_d_EnergyStruct)
; Agent - HP
Global $g_d_HealthStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_HP_PERCENT & "];float hpPercent;dword hpMax" _
)
Global $g_i_HealthStructSize = DllStructGetSize($g_d_HealthStruct)
; Agent - AgentInfo
Global $g_d_InfoStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_POS_X & "];" & "float posX;float posY;"	& _
    "byte[" & ($GC_I_OFFSET_AGENT_TYPE - ($GC_I_OFFSET_AGENT_POS_Y + 4)) & "];" & "long type;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_OWNER - ($GC_I_OFFSET_AGENT_TYPE + 4)) & "];" & "long owner;dword itemID;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_PLAYERNUMBER - ($GC_I_OFFSET_AGENT_ITEM_ID + 4)) & "];" & "short player;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_EFFECTS - ($GC_I_OFFSET_AGENT_PLAYERNUMBER + 2)) & "];" & "dword effects;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_ALLEGIANCE - ($GC_I_OFFSET_AGENT_EFFECTS + 4)) & "];" & "byte allegiance" _
)
Global $g_i_InfoStructSize = DllStructGetSize($g_d_InfoStruct)
; Agent - Effects
Global $g_d_EffectsStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_POS_X & "];float posX;float posY;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_EFFECTS - ($GC_I_OFFSET_AGENT_POS_Y + 4)) & "];dword effects" _
)
Global $g_i_EffectsStructSize = DllStructGetSize($g_d_EffectsStruct)
; Agent - AgentOwner
Global $g_d_OwnerStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_AGENT_POS_X & "];" & "float posX;float posY;" & _
    "byte[" & ($GC_I_OFFSET_AGENT_OWNER - ($GC_I_OFFSET_AGENT_POS_Y + 4)) & "];long owner" _
)
Global $g_i_OwnerStructSize = DllStructGetSize($g_d_OwnerStruct)
; Agent - HeroOwner
Global $g_d_HeroOwnerStruct = DllStructCreate( _
    "long agentID;long owner;long heroID" _
)
Global $g_i_HeroOwnerStructSize = DllStructGetSize($g_d_HeroOwnerStruct)
; Skillbar - SkillSlotInfo
Global $g_d_SkillSlotStruct = DllStructCreate( _
    "byte[" & $GC_I_OFFSET_SKILLSLOT_ADRENALINE & "];dword adrenaline;" & _
    "byte[" & ($GC_I_OFFSET_SKILLSLOT_RECHARGE - ($GC_I_OFFSET_SKILLSLOT_ADRENALINE + 4)) & "];dword recharge;dword skillID" _
)
Global $g_i_SkillSlotStructSize = DllStructGetSize($g_d_SkillSlotStruct)
; ===============================================================================================================================
#EndRegion DllStructs

#Region Logging
; #GLOBALS - LOGGING# ===========================================================================================================
; Logging output parameters
Global $g_h_OutputStream
Global $g_i_MaxLines = 1000
Global $g_s_LogFile, $g_h_Log = -1
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_SetOutput
; Description....: Sets the target edit control used for console-style output and scrolling.
; Syntax.........: AddOns_SetOutput ( $a_h_Edit )
; Parameters.....: $a_h_Edit - Handle : Edit control handle to receive log lines.
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Stores the handle in $g_h_OutputStream; must be set before AddOns_Out().
; Related........: AddOns_InitLog, AddOns_Out
; ===============================================================================================================================
Func AddOns_SetOutput($a_h_Edit)
    $g_h_OutputStream = $a_h_Edit
EndFunc   ;==>AddOns_SetOutput

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_Out
; Description....: Appends a timestamped line to the output control and optional log file,
;                  trims excess lines, and keeps the caret in view.
; Syntax.........: AddOns_Out ( $a_s_Msg )
; Parameters.....: $a_s_Msg - String : Message text (a CRLF is added automatically).
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Timestamp format: "[HH:MM] ". Trims from the top when line count exceeds
;                    $g_i_MaxLines. Uses caret scroll to follow new output.
;                  - Writes to $g_h_Log when valid (≥ 0). Requires AddOns_SetOutput() first.
; Related........: AddOns_CloseLog, AddOns_InitLog, AddOns_SetOutput, FileWrite, _
;                  _GUICtrlEdit_AppendText, _GUICtrlEdit_GetLineCount, _GUICtrlEdit_GetTextLen, _GUICtrlEdit_LineIndex,
;                  _GUICtrlEdit_LineScroll, _GUICtrlEdit_ReplaceSel, _GUICtrlEdit_Scroll, _GUICtrlEdit_SetSel, _GUICtrlEdit_SetText       
; ===============================================================================================================================
Func AddOns_Out($a_s_Msg)
    Local $l_h_Console = $g_h_OutputStream
    Local $l_s_Line = "[" & @HOUR & ":" & @MIN & "] " & $a_s_Msg & @CRLF

    _GUICtrlEdit_AppendText($l_h_Console, $l_s_Line)
    If $g_h_Log <> -1 Then FileWrite($g_h_Log, $l_s_Line)

    Local $l_i_Count = _GUICtrlEdit_GetLineCount($l_h_Console)
    If $l_i_Count > $g_i_MaxLines Then
        Local $l_i_Excess = $l_i_Count - $g_i_MaxLines
        Local $l_i_KeepIdx = _GUICtrlEdit_LineIndex($l_h_Console, $l_i_Excess)
        If $l_i_KeepIdx = -1 Then
            _GUICtrlEdit_SetText($l_h_Console, "")
        Else
            _GUICtrlEdit_SetSel($l_h_Console, 0, $l_i_KeepIdx)
            _GUICtrlEdit_ReplaceSel($l_h_Console, "")
            _GUICtrlEdit_LineScroll($l_h_Console, 0, -$l_i_Excess)
        EndIf
    EndIf

    Local $l_i_Len = _GUICtrlEdit_GetTextLen($l_h_Console)
    _GUICtrlEdit_SetSel($l_h_Console, $l_i_Len, $l_i_Len)
    _GUICtrlEdit_Scroll($l_h_Console, $SB_SCROLLCARET)
EndFunc   ;==>AddOns_Out

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_InitLog
; Description....: Opens (truncates) a log file for append output and lifts the GUI edit text
;                  limit to near-INT_MAX for long sessions.
; Syntax.........: AddOns_InitLog ( $a_s_LogFile )
; Parameters.....: $a_s_LogFile - String : Full path to the log file.
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Deletes existing file, then opens with $FO_APPEND. Stores handle in $g_h_Log.
;                  - Requires a valid $g_h_OutputStream to apply _GUICtrlEdit_SetLimitText().
; Related........: AddOns_CloseLog, AddOns_Out, AddOns_SetOutput, _GUICtrlEdit_SetLimitText, FileDelete, FileOpen
; ===============================================================================================================================
Func AddOns_InitLog($a_s_LogFile)
    $g_s_LogFile = $a_s_LogFile

    FileDelete($g_s_LogFile)
    $g_h_Log = FileOpen($g_s_LogFile, $FO_APPEND)

    _GUICtrlEdit_SetLimitText($g_h_OutputStream, 0x7FFFFFFE)
EndFunc   ;==>AddOns_InitLog

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_CloseLog
; Description....: Flushes and closes the active log file handle if open.
; Syntax.........: AddOns_CloseLog ( )
; Parameters.....: None
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Safely no-ops when $g_h_Log is already -1; resets it to -1 after close.
; Related........: AddOns_InitLog, AddOns_Out, FileClose
; ===============================================================================================================================
Func AddOns_CloseLog()
    If $g_h_Log <> -1 Then FileClose($g_h_Log)
    $g_h_Log = -1
EndFunc   ;==>AddOns_CloseLog
#EndRegion Logging

#Region Util
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_PurgeHook
; Description....: Performs a short “purge cycle” depending on the current render state.
;                  - If rendering is enabled: ensures the GW window is shown.
;                  - If rendering is disabled: hides the GW window if shown, briefly enables rendering,
;                    waits, disables rendering again, then trims/clears process working set via
;                    Memory_Clear().
; Syntax.........: AddOns_PurgeHook ( [ $a_i_Time = 5000 ] )
; Parameters.....: $a_i_Time - Int : Delay in milliseconds used as the wait time during the
;                               purge cycle (default: 5000).
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Memory_Clear() is executed only when rendering is currently disabled.
;                  - Window visibility is toggled to match the render state (show when rendered,
;                    hide when non-rendered).
; Related........: Ui_GetRenderEnabled, Ui_EnableRendering, Ui_DisableRendering, Memory_Clear
; ===============================================================================================================================
Func AddOns_PurgeHook($a_i_Time = 5000)
    If Ui_GetRenderEnabled() Then
        If Not BitAND(WinGetState($g_h_GWWindow), $WIN_STATE_VISIBLE) Then WinSetState($g_h_GWWindow, "", @SW_SHOW)
    Else
        If BitAND(WinGetState($g_h_GWWindow), $WIN_STATE_VISIBLE) Then WinSetState($g_h_GWWindow, "", @SW_HIDE)
        Ui_EnableRendering()
        Sleep($a_i_Time)
        Ui_DisableRendering()
        Memory_Clear()
    EndIf
EndFunc ;==> AddOns_PurgeHook

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ConvertFlatTo2DArray
; Description....: Converts a flat paired list [x1,y1,x2,y2,...] into an Nx2 array
;                  [[x,y],...].
; Syntax.........: AddOns_ConvertFlatTo2DArray ( $a_av_Flat )
; Parameters.....: $a_av_Flat - Array : Flat list of numbers whose length must be even.
; Return values..: Success - Nx2 array of coordinates.
;                  Failure - 0 with @error set to:
;                            1 -> Odd number of elements in $a_av_Flat
; Author.........: KleuTSchi
; Remarks........: - Output shape is [rows][2]; row count equals UBound($a_av_Flat) / 2.
; Related........: AddOns_CreateMapFromArray, Pathing_AddPreludeToRoute, Pathing_AddRouteToMap
; ===============================================================================================================================
Func AddOns_ConvertFlatTo2DArray($a_av_Flat)
    Local $l_i_Total = UBound($a_av_Flat)
    If Mod($l_i_Total, 2) <> 0 Then Return SetError(1, 0, 0)

    Local $l_i_Rows = $l_i_Total / 2
    Local $l_av2_Nx2[$l_i_Rows][2]

    Local $l_i_Idx = 0
    For $i = 0 To $l_i_Rows - 1
        $l_av2_Nx2[$i][0] = $a_av_Flat[$l_i_Idx]
        $l_av2_Nx2[$i][1] = $a_av_Flat[$l_i_Idx + 1]
        $l_i_Idx += 2
    Next
    Return $l_av2_Nx2
EndFunc   ;==>AddOns_ConvertFlatTo2DArray

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_CreateMapFromArray
; Description....: Builds a map (dictionary) from an Nx2 array where the first column is
;                  the key and the second column is the value.
; Syntax.........: AddOns_CreateMapFromArray ( $a_av2_Array )
; Parameters.....: $a_av2_Array - Nx2 Array : [[key,value], ...].
; Return values..: Map - AutoIt map with keys from column 0 and values from column 1.
; Author.........: KleuTSchi
; Remarks........: - On duplicate keys, later rows overwrite earlier entries.
; Related........: AddOns_ConvertFlatTo2DArray
; ===============================================================================================================================
Func AddOns_CreateMapFromArray($a_av2_Array)
    Local $l_m_Map[]
    For $i = 0 To UBound($a_av2_Array) - 1
        $l_m_Map[$a_av2_Array[$i][0]] = $a_av2_Array[$i][1]
    Next
    Return $l_m_Map
EndFunc   ;==>AddOns_CreateMapFromArray
#EndRegion Util

#Region MapIsLoaded
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_DialogLoad
; Description....: Sends a dialog and waits for the map-load to complete.
; Syntax.........: AddOns_DialogLoad ( $a_i_DialogID )
; Parameters.....: $a_i_DialogID - Integer : Dialog identifier passed to Ui_Dialog().
; Return values..: Success - True
;                  Failure - False (propagated from Map_WaitMapIsLoaded())
; Author.........: KleuTSchi
; Remarks........: - Convenience wrapper: initialize "map is loaded", fire dialog, then wait.
; Related........: Map_InitMapIsLoaded, Map_WaitMapIsLoaded, Ui_Dialog
; ===============================================================================================================================
Func AddOns_DialogLoad($a_i_DialogID)
    Map_InitMapIsLoaded()
    Ui_Dialog($a_i_DialogID)
    Return Map_WaitMapIsLoaded()
EndFunc   ;==>AddOns_DialogLoad
#EndRegion MapIsLoaded

#Region GameWindows
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_CloseAllPanels
; Description....: Closes all in-game UI panels.
; Syntax.........: AddOns_CloseAllPanels ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Calls Core_PerformAction with $GC_I_CONTROL_PANEL_CLOSE_ALL_PANELS and $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_CloseAllPanels()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_CLOSE_ALL_PANELS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_CloseAllPanels

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleHeroWindow
; Description....: Opens/closes the Hero window.
; Syntax.........: AddOns_ToggleHeroWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_HERO with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleHeroWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_HERO, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleHeroWindow

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleInventory
; Description....: Opens/closes the Inventory window.
; Syntax.........: AddOns_ToggleInventory ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_INVENTORY_OPEN_INVENTORY with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleInventory()
	Return Core_PerformAction($GC_I_CONTROL_INVENTORY_OPEN_INVENTORY, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleInventory

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleAllBags
; Description....: Shows/hides all bag panels in the Inventory.
; Syntax.........: AddOns_ToggleAllBags ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_INVENTORY_TOGGLE_ALL_BAGS with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleAllBags()
	Return Core_PerformAction($GC_I_CONTROL_INVENTORY_TOGGLE_ALL_BAGS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleAllBags

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleWorldMap
; Description....: Opens/closes the World Map panel.
; Syntax.........: AddOns_ToggleWorldMap ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_WORLD_MAP with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleWorldMap()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_WORLD_MAP, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleWorldMap

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleOptions
; Description....: Opens/closes the Options panel.
; Syntax.........: AddOns_ToggleOptions ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_OPTIONS with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleOptions()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_OPTIONS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleOptions

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleQuestWindow
; Description....: Opens/closes the Quest log panel.
; Syntax.........: AddOns_ToggleQuestWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_QUEST with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleQuestWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_QUEST, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleQuestWindow

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleSkillWindow
; Description....: Opens/closes the Skills & Attributes panel.
; Syntax.........: AddOns_ToggleSkillWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_SKILLS_AND_ATTRIBUTES with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleSkillWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_SKILLS_AND_ATTRIBUTES, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleSkillWindow

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleMissionMap
; Description....: Opens/closes the Mission Map panel.
; Syntax.........: AddOns_ToggleMissionMap ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_MISSION_MAP with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleMissionMap()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_MISSION_MAP, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleMissionMap

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleFriendList
; Description....: Opens/closes the Friends list panel.
; Syntax.........: AddOns_ToggleFriendList ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_FRIENDS with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleFriendList()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_FRIENDS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleFriendList

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleGuildWindow
; Description....: Opens/closes the Guild panel.
; Syntax.........: AddOns_ToggleGuildWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_GUILD with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleGuildWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_GUILD, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleGuildWindow

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_TogglePartyWindow
; Description....: Opens/closes the Party panel.
; Syntax.........: AddOns_TogglePartyWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_PARTY with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_TogglePartyWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_PARTY, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_TogglePartyWindow

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleScoreChart
; Description....: Opens/closes the Score Chart panel.
; Syntax.........: AddOns_ToggleScoreChart ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_SCORE_CHART with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleScoreChart()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_SCORE_CHART, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleScoreChart

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleLayoutWindow
; Description....: Opens/closes the UI Layout customization panel.
; Syntax.........: AddOns_ToggleLayoutWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_CUSTOMIZE_LAYOUT with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleLayoutWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_CUSTOMIZE_LAYOUT, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleLayoutWindow

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleMinionList
; Description....: Opens/closes the Minion List panel.
; Syntax.........: AddOns_ToggleMinionList ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_MINION_LIST with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleMinionList()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_MINION_LIST, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>AddOns_ToggleMinionList

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleHeroPanel
; Description....: Opens/closes the specified hero’s panel by index.
; Syntax.........: AddOns_ToggleHeroPanel ( $a_i_HeroNumber )
; Parameters.....: $a_i_HeroNumber - Hero index (1..7). 1..3 use IDs 0xDB..0xDE; 4..7 use IDs 0x126..0x129.
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Values >= 8 perform no action. Internally calls Core_PerformAction with the computed control ID
;                  and $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleHeroPanel($a_i_HeroNumber)
    If $a_i_HeroNumber < 1 Or $a_i_HeroNumber > 7 Then Return 0
	If $a_i_HeroNumber < 4 Then
		Return Core_PerformAction(0xDB + $a_i_HeroNumber, $GC_I_CONTROL_TYPE_ACTIVATE)
	Else
		Return Core_PerformAction(0x122 + $a_i_HeroNumber, $GC_I_CONTROL_TYPE_ACTIVATE)
	EndIf
EndFunc   ;==>AddOns_ToggleHeroPanel

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleHeroPetPanel
; Description....: Opens/closes the specified hero’s pet panel by index.
; Syntax.........: AddOns_ToggleHeroPetPanel ( $a_i_HeroNumber )
; Parameters.....: $a_i_HeroNumber - Hero index (1..7). 1..3 use IDs 0xDF..0xE2; 4..7 use IDs 0xFE..0x101.
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Values >= 8 perform no action. Internally calls Core_PerformAction with the computed control ID
;                  and $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleHeroPetPanel($a_i_HeroNumber)
    If $a_i_HeroNumber < 1 Or $a_i_HeroNumber > 7 Then Return 0
	If $a_i_HeroNumber < 4 Then
		Return Core_PerformAction(0xDF + $a_i_HeroNumber, $GC_I_CONTROL_TYPE_ACTIVATE)
	Else
		Return Core_PerformAction(0xFA + $a_i_HeroNumber, $GC_I_CONTROL_TYPE_ACTIVATE)
	EndIf
EndFunc   ;==>AddOns_ToggleHeroPetPanel

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_TogglePetPanel
; Description....: Opens/closes the Pet Commander panel for the player.
; Syntax.........: AddOns_TogglePetPanel ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_PET_COMMANDER with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_TogglePetPanel()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_PET_COMMANDER, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>TogglePetPanel

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ToggleHelpWindow
; Description....: Opens/closes the in-game Help panel.
; Syntax.........: AddOns_ToggleHelpWindow ( )
; Parameters.....: None
; Return values..: 0
; Author.........: KleuTSchi
; Remarks........: Uses $GC_I_CONTROL_PANEL_OPEN_HELP with $GC_I_CONTROL_TYPE_ACTIVATE.
; Related........: Core_PerformAction
; ===============================================================================================================================
Func AddOns_ToggleHelpWindow()
	Return Core_PerformAction($GC_I_CONTROL_PANEL_OPEN_HELP, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>ToggleHelpWindow
#EndRegion GameWindows

#Region Heroes
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetHeroNumber
; Description....: Returns the HeroNumber for a hero owned by the player, resolved by AgentID or HeroID.
; Syntax.........: AddOns_GetHeroNumber ( $a_b_ByAgentID = True, $a_i_AgentID = 0, $a_b_ByHeroID = False, $a_i_HeroID = 0 )
; Parameters.....: $a_b_ByAgentID - Bool    : Resolve by AgentID when True.
;                  $a_i_AgentID   - Integer : AgentID to match (when $a_b_ByAgentID = True).
;                  $a_b_ByHeroID  - Bool    : Resolve by HeroID when True.
;                  $a_i_HeroID    - Integer : HeroID to match (when $a_b_ByHeroID = True).
; Return values..: Success - Integer in [1..N] (HeroNumber)
;                  Failure - 0 with @error set to:
;                            1 -> Exactly one of $a_b_ByAgentID / $a_b_ByHeroID must be True
;                            2 -> Failed to get player number (Agent_GetPlayerInfo returned 0)
; Author.........: KleuTSchi
; Remarks........: - Iterates party hero entries owned by the player.
;                  - Uses ReadProcessMemory on a fixed-stride hero array; silently skips read failures per entry.
; Related........: Agent_GetPlayerInfo, Party_GetMyPartyInfo, DllCall, DllStructGetData
; ===============================================================================================================================
Func AddOns_GetHeroNumber($a_i_Hero, $a_i_Mode = 0)
    If $a_i_Hero = 0 Then Return SetError(1, 0, 0)

    Local $l_p_PartyHeroPtr = Party_GetMyPartyInfo("ArrayHeroPartyMember")
    Local $l_i_PartyHeroCnt = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
    Local $l_i_PlayerNumber = Agent_GetPlayerInfo(-2, "PlayerNumber")
    If $l_i_PlayerNumber = 0 Then Return SetError(2, 0, 0)

    Local Const $LC_I_STRIDE = 0x18
    Local $l_p_Hero, $l_i_AgentID, $l_i_Owner, $l_i_HeroID, $l_i_HeroNumber = 0
    For $i = 1 To $l_i_PartyHeroCnt
        $l_p_Hero = $l_p_PartyHeroPtr + (($i - 1) * $LC_I_STRIDE)
        If Not $l_p_Hero Then ContinueLoop

        Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_Hero, _
            "struct*", $g_d_HeroOwnerStruct, _
            "ulong_ptr", $g_i_HeroOwnerStructSize, _
            "ulong_ptr*", 0 _
        )
        If @error Or Not $l_av_Call[0] Then ContinueLoop

        $l_i_AgentID = DllStructGetData($g_d_HeroOwnerStruct, "agentID")
        $l_i_Owner = DllStructGetData($g_d_HeroOwnerStruct, "owner")
        $l_i_HeroID = DllStructGetData($g_d_HeroOwnerStruct, "heroID")

        If $l_i_Owner <> $l_i_PlayerNumber Then ContinueLoop

        $l_i_HeroNumber += 1

        Switch $a_i_Mode
            Case 0
                If $l_i_AgentID = $a_i_Hero Then Return $l_i_HeroNumber
            Case 1
                If $l_i_HeroID = $a_i_Hero Then Return $l_i_HeroNumber
        EndSwitch
    Next

    Return 0
EndFunc   ;==>AddOns_GetHeroNumber

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_SetHeroSkillState
; Description....: Enables or disables a specific hero skill slot, then sleeps for a caller-supplied delay (ms).
; Syntax.........: AddOns_SetHeroSkillState ( $a_b_Enable, $a_i_Hero, $a_i_Slot, $a_i_Delay )
; Parameters.....: $a_b_Enable - Bool    : True to enable, False to disable.
;                  $a_i_Hero   - Integer : HeroNumber (1..8).
;                  $a_i_Slot   - Integer : Skill slot (1..8).
;                  $a_i_Delay  - Integer : Sleep in milliseconds after the action.
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Thin wrapper over Ui_EnableHeroSkill/Ui_DisableHeroSkill with pacing.
; Related........: Ui_DisableHeroSkill, Ui_EnableHeroSkill
; ===============================================================================================================================
Func AddOns_SetHeroSkillState($a_b_Enable, $a_i_Hero, $a_i_Slot, $a_i_Delay)
    If $a_b_Enable Then
        Ui_EnableHeroSkill($a_i_Hero, $a_i_Slot)
    Else
        Ui_DisableHeroSkill($a_i_Hero, $a_i_Slot)
    EndIf
    Sleep($a_i_Delay)
EndFunc   ;==>AddOns_SetHeroSkillState

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_DisableHeroSkillbar
; Description....: Disables all 8 skills on a hero’s bar with ping-paced sleeps.
; Syntax.........: AddOns_DisableHeroSkillbar ( $a_i_HeroNumber )
; Parameters.....: $a_i_HeroNumber - Integer : HeroNumber (1..8).
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Uses Other_GetPing() between toggles to reduce failed commands.
; Related........: Other_GetPing, Ui_DisableHeroSkill
; ===============================================================================================================================
Func AddOns_DisableHeroSkillbar($a_i_HeroNumber)
  	Local $l_i_Ping = Other_GetPing()
   	For $i = 1 To 8
		Ui_DisableHeroSkill($a_i_HeroNumber, $i)
	   	Sleep($l_i_Ping)
   	Next
EndFunc   ;==>AddOns_DisableHeroSkillbar

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_EnableHeroSkillbar
; Description....: Enables all 8 skills on a hero’s bar with ping-paced sleeps.
; Syntax.........: AddOns_EnableHeroSkillbar ( $a_i_HeroNumber )
; Parameters.....: $a_i_HeroNumber - Integer : HeroNumber (1..8).
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Uses Other_GetPing() between toggles to reduce failed commands.
; Related........: Other_GetPing, Ui_EnableHeroSkill
; ===============================================================================================================================
Func AddOns_EnableHeroSkillbar($a_i_HeroNumber)
  	Local $l_i_Ping = Other_GetPing()
   	For $i = 1 To 8
		Ui_EnableHeroSkill($a_i_HeroNumber, $i)
	   	Sleep($l_i_Ping)
   	Next
EndFunc   ;==>AddOns_EnableHeroSkillbar

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_DisableAllHeroSkillbars
; Description....: Disables all skills for every hero from 1..$a_i_HeroCount.
; Syntax.........: AddOns_DisableAllHeroSkillbars ( $a_i_HeroCount )
; Parameters.....: $a_i_HeroCount - Integer : Number of heroes to process.
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Iterative wrapper around AddOns_DisableHeroSkillbar().
; Related........: AddOns_DisableHeroSkillbar
; ===============================================================================================================================
Func AddOns_DisableAllHeroSkillbars($a_i_HeroCount)
	For $i = 1 To $a_i_HeroCount
   		AddOns_DisableHeroSkillbar($i)
   	Next
EndFunc   ;==>AddOns_DisableAllHeroSkillbars

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_EnableAllHeroSkillbars
; Description....: Enables all skills for every hero from 1..$a_i_HeroCount.
; Syntax.........: AddOns_EnableAllHeroSkillbars ( $a_i_HeroCount )
; Parameters.....: $a_i_HeroCount - Integer : Number of heroes to process.
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Iterative wrapper around AddOns_EnableHeroSkillbar().
; Related........: AddOns_EnableHeroSkillbar
; ===============================================================================================================================
Func AddOns_EnableAllHeroSkillbars($a_i_HeroCount)
	For $i = 1 To $a_i_HeroCount
   		AddOns_EnableHeroSkillbar($i)
   	Next
EndFunc   ;==>AddOns_EnableAllHeroSkillbars

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_SetHeroBehaviors
; Description....: Applies behavior presets to all configured heroes.
; Syntax.........: AddOns_SetHeroBehaviors ( )
; Parameters.....: $a_ai_HeroBehaviors - Array of integers (0..2) : Fight, Guard, Avoid.
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - 0-indexed no count at index 0.
;                  - No validation or retries; caller handles errors.
; Related........: Ui_SetHeroBehavior, AddOns_AddHeroes
; ===============================================================================================================================
Func AddOns_SetHeroBehaviors($a_ai_HeroBehaviors)
	For $i = 0 To UBound($a_ai_HeroBehaviors) - 1
		Local $l_i_HeroNumber = $i + 1
		Ui_SetHeroBehavior($l_i_HeroNumber, $a_ai_HeroBehaviors[$i])
	Next
EndFunc   ;==>AddOns_SetHeroBehaviors

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_AddHeroes
; Description....: Adds all heroes from $a_ai_HeroIDs to the party.
; Syntax.........: AddOns_AddHeroes ( )
; Parameters.....: $a_ai_HeroIDs - Array of integers (HeroIDs).
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Requires a context where heroes can be added (e.g., outpost).
;                  - No retries; caller should ensure UI readiness.
; Related........: Ui_AddHero, AddOns_SetHeroBehaviors
; ===============================================================================================================================
Func AddOns_AddHeroes($a_ai_HeroIDs)
	For $i = 0 To UBound($a_ai_HeroIDs) - 1
		Ui_AddHero($a_ai_HeroIDs[$i])
	Next
EndFunc   ;==>AddOns_AddHeroes
#EndRegion Heroes

#Region Inventory
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEmptySlot
; Description....: Finds the first or last free slot in a bag, depending on scan direction.
; Syntax.........: AddOns_GetEmptySlot ( $a_v_Bag, $a_b_FrontToBack = True )
; Parameters.....: $a_v_Bag        - Bag ID or pointer : Bag handle/index or pointer.
;                  $a_b_FrontToBack - Bool             : True scans from slot 1→N, False from N→1.
; Return values..: Success - Integer slot index (1..N)
;                  Failure - 0 (no free slot or invalid bag)
; Author.........: KleuTSchi
; Remarks........: - Reads bag item array and slot count, then scans for first null pointer.
; Related........: AddOns_GetEmptyInventorySlot, AddOns_GetEmptyStorageSlot, Item_GetBagPtr, Memory_Read, IsPtr
; ===============================================================================================================================
Func AddOns_GetEmptySlot($a_v_Bag, $a_b_FrontToBack = True)
    If IsPtr($a_v_Bag) <> 0 Then $a_v_Bag = Item_GetBagPtr($a_v_Bag)

    Local $l_p_ItemArray = Memory_Read($a_v_Bag + 0x18, "ptr")
    Local $l_i_Slots = Memory_Read($a_v_Bag + 0x20, "long")
    If $l_p_ItemArray = 0 Or $l_i_Slots <= 0 Then Return 0

    Local $l_i_Start, $l_i_End, $l_i_Step
    If $a_b_FrontToBack Then
        $l_i_Start = 0
        $l_i_End = $l_i_Slots - 1
        $l_i_Step = 1
    Else
        $l_i_Start = $l_i_Slots - 1
        $l_i_End = 0
        $l_i_Step = -1
    EndIf

    For $i = $l_i_Start To $l_i_End Step $l_i_Step
        Local $l_p_Item = Memory_Read($l_p_ItemArray + ($i * 0x4), "ptr")
        If $l_p_Item = 0 Then Return $i + 1
    Next

    Return 0
EndFunc   ;==>AddOns_GetEmptySlot

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEmptyInventorySlot
; Description....: Returns the first or last free [bag, slot] pair across inventory bags, optionally including the equipment pack.
; Syntax.........: AddOns_GetEmptyInventorySlot ( $a_b_IncludeEquipmentPack = False, $a_b_FrontToBack = True )
; Parameters.....: $a_b_IncludeEquipmentPack - Bool : Include equipment pack when True.
;                  $a_b_FrontToBack          - Bool : True scans 1→N, False scans N→1 (per bag).
; Return values..: Success - 2-element array [BagID, Slot]
;                  Failure - [0, 0]
; Author.........: KleuTSchi
; Remarks........: - Bags scanned: Backpack, Belt Pouch, Bag1, Bag2 (+ Equipment Pack if chosen).
;                  - Uses AddOns_GetEmptySlot() per bag; first match wins by chosen direction.
; Related........: AddOns_GetEmptySlot, AddOns_GetEmptyInventorySlotCount, Item_GetBagPtr
; ===============================================================================================================================
Func AddOns_GetEmptyInventorySlot($a_b_IncludeEquipmentPack = False, $a_b_FrontToBack = True)
    Local $l_ai_BagSlot[] = [0, 0]
    Local $l_ai_BagList[] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
    Local $l_i_BagCount = UBound($l_ai_BagList)
    
    If $a_b_IncludeEquipmentPack Then
        $l_i_BagCount += 1
        ReDim $l_ai_BagList[$l_i_BagCount]
        $l_ai_BagList[$l_i_BagCount - 1] = $GC_I_INVENTORY_EQUIPMENT_PACK
    EndIf

    Local $l_i_Start, $l_i_End, $l_i_Step
    If $a_b_FrontToBack Then
        $l_i_Start = 0
        $l_i_End = $l_i_BagCount - 1
        $l_i_Step = 1
    Else
        $l_i_Start = $l_i_BagCount - 1
        $l_i_End = 0
        $l_i_Step = -1
    EndIf

    For $i = $l_i_Start To $l_i_End Step $l_i_Step
        Local $l_p_Bag = Item_GetBagPtr($l_ai_BagList[$i])
        If $l_p_Bag = 0 Then ContinueLoop

        Local $l_i_Slot = AddOns_GetEmptySlot($l_p_Bag, $a_b_FrontToBack)
        If $l_i_Slot <> 0 Then
            $l_ai_BagSlot[0] = $l_ai_BagList[$i]
            $l_ai_BagSlot[1] = $l_i_Slot
            Return $l_ai_BagSlot
        EndIf
    Next

    Return $l_ai_BagSlot
EndFunc   ;==>AddOns_GetEmptyInventorySlot

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEmptyStorageSlot
; Description....: Returns the first or last free [bag, slot] pair across storage panes.
; Syntax.........: AddOns_GetEmptyStorageSlot ( $a_b_FrontToBack = True )
; Parameters.....: $a_b_FrontToBack - Bool : True scans 1→N per pane, False scans N→1.
; Return values..: Success - 2-element array [StorageBagID, Slot]
;                  Failure - [0, 0]
; Author.........: KleuTSchi
; Remarks........: - Scans STORAGE1..STORAGE14.
;                  - Uses AddOns_GetEmptySlot() per pane; first match wins by chosen direction.
; Related........: AddOns_GetEmptySlot, AddOns_GetEmptyStorageSlotCount, Item_GetBagPtr
; ===============================================================================================================================
Func AddOns_GetEmptyStorageSlot($a_b_FrontToBack = True)
    Local $l_ai_StorageSlot[] = [0, 0]
    Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_STORAGE1, $GC_I_INVENTORY_STORAGE2, _
        $GC_I_INVENTORY_STORAGE3, $GC_I_INVENTORY_STORAGE4, _
        $GC_I_INVENTORY_STORAGE5, $GC_I_INVENTORY_STORAGE6, _
        $GC_I_INVENTORY_STORAGE7, $GC_I_INVENTORY_STORAGE8, _
        $GC_I_INVENTORY_STORAGE9, $GC_I_INVENTORY_STORAGE10, _
        $GC_I_INVENTORY_STORAGE11, $GC_I_INVENTORY_STORAGE12, _
        $GC_I_INVENTORY_STORAGE13, $GC_I_INVENTORY_STORAGE14 _
    ]

    Local $l_i_Start, $l_i_End, $l_i_Step
    If $a_b_FrontToBack Then
        $l_i_Start = 0
        $l_i_End = UBound($l_ai_BagList) - 1
        $l_i_Step = 1
    Else
        $l_i_Start = UBound($l_ai_BagList) - 1
        $l_i_End = 0
        $l_i_Step = -1
    EndIf

    For $i = $l_i_Start To $l_i_End Step $l_i_Step
        Local $l_p_Storage = Item_GetBagPtr($l_ai_BagList[$i])
        If $l_p_Storage = 0 Then ContinueLoop

        Local $l_i_Slot = AddOns_GetEmptySlot($l_p_Storage, $a_b_FrontToBack)
        If $l_i_Slot <> 0 Then
            $l_ai_StorageSlot[0] = $l_ai_BagList[$i]
            $l_ai_StorageSlot[1] = $l_i_Slot
            Return $l_ai_StorageSlot
        EndIf
    Next

    Return $l_ai_StorageSlot
EndFunc   ;==>AddOns_GetEmptyStorageSlot

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEmptyInventorySlotCount
; Description....: Counts free slots across inventory bags, optionally including the equipment pack.
; Syntax.........: AddOns_GetEmptyInventorySlotCount ( $a_b_IncludeEquipmentPack = False )
; Parameters.....: $a_b_IncludeEquipmentPack - Bool : Include equipment pack when True.
; Return values..: Integer - Number of free slots (≥ 0)
; Author.........: KleuTSchi
; Remarks........: - Free slots computed as (capacity @+0x20) − (occupied @+0x10) per bag.
; Related........: Item_GetBagPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetEmptyInventorySlotCount($a_b_IncludeEquipmentPack = False)
    Local $l_i_EmptySlots = 0
    Local $l_ai_BagList[] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
    Local $l_i_BagCount = UBound($l_ai_BagList)
    
    If $a_b_IncludeEquipmentPack Then
        $l_i_BagCount += 1
        ReDim $l_ai_BagList[$l_i_BagCount]
        $l_ai_BagList[$l_i_BagCount - 1] = $GC_I_INVENTORY_EQUIPMENT_PACK
    EndIf

    Local $l_p_Bag
    For $i = 0 To $l_i_BagCount - 1
        $l_p_Bag = Item_GetBagPtr($l_ai_BagList[$i])
        If $l_p_Bag <> 0 Then
            $l_i_EmptySlots += (Memory_Read($l_p_Bag + 0x20, "long") - Memory_Read($l_p_Bag + 0x10, "dword"))
        EndIf
    Next

    Return $l_i_EmptySlots
EndFunc   ;==>AddOns_GetEmptyInventorySlotCount

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEmptyStorageSlotCount
; Description....: Counts free slots across all storage panes.
; Syntax.........: AddOns_GetEmptyStorageSlotCount ( )
; Parameters.....: None
; Return values..: Integer - Number of free slots (≥ 0)
; Author.........: KleuTSchi
; Remarks........: - Free slots computed as (capacity @+0x20) − (occupied @+0x10) per pane.
; Related........: Item_GetBagPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetEmptyStorageSlotCount()
    Local $l_i_EmptySlots = 0
        Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_STORAGE1, $GC_I_INVENTORY_STORAGE2, _
        $GC_I_INVENTORY_STORAGE3, $GC_I_INVENTORY_STORAGE4, _
        $GC_I_INVENTORY_STORAGE5, $GC_I_INVENTORY_STORAGE6, _
        $GC_I_INVENTORY_STORAGE7, $GC_I_INVENTORY_STORAGE8, _
        $GC_I_INVENTORY_STORAGE9, $GC_I_INVENTORY_STORAGE10, _
        $GC_I_INVENTORY_STORAGE11, $GC_I_INVENTORY_STORAGE12, _
        $GC_I_INVENTORY_STORAGE13, $GC_I_INVENTORY_STORAGE14 _
    ]
    
    Local $l_p_Storage
    For $i = 0 To UBound($l_ai_BagList) - 1
        $l_p_Storage = Item_GetBagPtr($l_ai_BagList[$i])
        If $l_p_Storage <> 0 Then
            $l_i_EmptySlots += (Memory_Read($l_p_Storage + 0x20, "long") - Memory_Read($l_p_Storage + 0x10, "dword"))
        EndIf
    Next

    Return $l_i_EmptySlots
EndFunc   ;==>AddOns_GetEmptyInventorySlotCount

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetInventoryItemCountbyModelID
; Description....: Sums the quantity of a given ModelID across inventory bags, optionally including the equipment pack.
; Syntax.........: AddOns_GetInventoryItemCountbyModelID ( $a_i_ModelID, $a_b_IncludeEquipmentPack = False )
; Parameters.....: $a_i_ModelID              - Integer : Item model ID to count.
;                  $a_b_IncludeEquipmentPack - Bool    : Include equipment pack when True.
; Return values..: Integer - Total quantity found (≥ 0)
; Author.........: KleuTSchi
; Remarks........: - Iterates items via Item_GetBagItemArray(); reads modelID (@+0x2C) and
;                    quantity (@+0x4C) using ReadProcessMemory into a small struct.
; Related........: AddOns_GetStorageItemCountbyModelID, AddOns_GetTotalItemCountbyModelID, Item_GetBagItemArray, Item_GetBagPtr,
;                  Memory_Read, DllCall, DllStructGetData, DllStructGetSize
; ===============================================================================================================================
Func AddOns_GetInventoryItemCountbyModelID($a_i_ModelID, $a_b_IncludeEquipmentPack = False)
    Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, _
        $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2, _
        $GC_I_INVENTORY_EQUIPMENT_PACK _
	]

    Local $l_d_Struct_Item = DllStructCreate( _
        "byte[" & $GC_I_OFFSET_ITEM_MODEL_ID & "];" & _
        "dword modelID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_QUANTITY - ($GC_I_OFFSET_ITEM_MODEL_ID + 4)) & "];" & _
        "short quantity" _
    )
    Local $l_i_StructSize_Item = DllStructGetSize($l_d_Struct_Item)

    Local $l_i_Count = 0
    For $bag In $l_ai_BagList
        If Not $a_b_IncludeEquipmentPack And $bag = $GC_I_INVENTORY_EQUIPMENT_PACK Then ContinueLoop

		$l_p_Bag = Item_GetBagPtr($bag)
		If $l_p_Bag = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($bag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_Item = $l_ap_ItemArray[$item]
            If $l_p_Item = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_Item, _
                "struct*", $l_d_Struct_Item, _
                "ulong_ptr", $l_i_StructSize_Item, _
                "ulong_ptr*", 0 _
            )

            Local $l_i_CurrentModelID = DllStructGetData($l_d_Struct_Item, "modelID")
            If $l_i_CurrentModelID = $a_i_ModelID Then $l_i_Count += DllStructGetData($l_d_Struct_Item, "quantity")
        Next
    Next

	Return $l_i_Count
EndFunc   ;==>AddOns_GetInventoryItemCountbyModelID

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetStorageItemCountbyModelID
; Description....: Sums the quantity of a given ModelID across storage panes, optionally including material storage.
; Syntax.........: AddOns_GetStorageItemCountbyModelID ( $a_i_ModelID, $a_b_IncludeMaterialStorage = False )
; Parameters.....: $a_i_ModelID                 - Integer : Item model ID to count.
;                  $a_b_IncludeMaterialStorage  - Bool    : Include material storage when True.
; Return values..: Integer - Total quantity found (≥ 0)
; Author.........: KleuTSchi
; Remarks........: - Iterates items via Item_GetBagItemArray(); reads modelID (@+0x2C) and
;                    quantity (@+0x4C) using ReadProcessMemory into a small struct.
; Related........: AddOns_GetInventoryItemCountbyModelID, AddOns_GetTotalItemCountbyModelID, Item_GetBagItemArray, Item_GetBagPtr,
;                  Memory_Read, DllCall, DllStructGetData, DllStructGetSize
; ===============================================================================================================================
Func AddOns_GetStorageItemCountbyModelID($a_i_ModelID, $a_b_IncludeMaterialStorage = False)
    Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_MATERIAL_STORAGE, _
        $GC_I_INVENTORY_STORAGE1, $GC_I_INVENTORY_STORAGE2, _
        $GC_I_INVENTORY_STORAGE3, $GC_I_INVENTORY_STORAGE4, _
        $GC_I_INVENTORY_STORAGE5, $GC_I_INVENTORY_STORAGE6, _
        $GC_I_INVENTORY_STORAGE7, $GC_I_INVENTORY_STORAGE8, _
        $GC_I_INVENTORY_STORAGE9, $GC_I_INVENTORY_STORAGE10, _
        $GC_I_INVENTORY_STORAGE11, $GC_I_INVENTORY_STORAGE12, _
        $GC_I_INVENTORY_STORAGE13, $GC_I_INVENTORY_STORAGE14 _
	]

    Local $l_d_Struct_Item = DllStructCreate( _
        "byte[" & $GC_I_OFFSET_ITEM_MODEL_ID & "];" & _
        "dword modelID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_QUANTITY - ($GC_I_OFFSET_ITEM_MODEL_ID + 4)) & "];" & _
        "short quantity" _
    )
    Local $l_i_StructSize_Item = DllStructGetSize($l_d_Struct_Item)

    Local $l_i_Count = 0
    For $bag In $l_ai_BagList
        If Not $a_b_IncludeMaterialStorage And $bag = $GC_I_INVENTORY_MATERIAL_STORAGE Then ContinueLoop

		$l_p_Bag = Item_GetBagPtr($bag)
		If $l_p_Bag = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($bag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_Item = $l_ap_ItemArray[$item]
            If $l_p_Item = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_Item, _
                "struct*", $l_d_Struct_Item, _
                "ulong_ptr", $l_i_StructSize_Item, _
                "ulong_ptr*", 0 _
            )

            Local $l_i_CurrentModelID = DllStructGetData($l_d_Struct_Item, "modelID")
            If $l_i_CurrentModelID = $a_i_ModelID Then $l_i_Count += DllStructGetData($l_d_Struct_Item, "quantity")
        Next
    Next

	Return $l_i_Count
EndFunc   ;==>AddOns_GetInventoryItemCountbyModelID

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetTotalItemCountbyModelID
; Description....: Sums the quantity of a given ModelID across inventory and storage, with flags to include equipment pack
;                  and material storage.
; Syntax.........: AddOns_GetTotalItemCountbyModelID ( $a_i_ModelID, $a_b_IncludeEquipmentPack = False, $a_b_IncludeMaterialStorage = False )
; Parameters.....: $a_i_ModelID                 - Integer : Item model ID to count.
;                  $a_b_IncludeEquipmentPack    - Bool    : Include equipment pack when True.
;                  $a_b_IncludeMaterialStorage  - Bool    : Include material storage when True.
; Return values..: Integer - Total quantity found (≥ 0)
; Author.........: KleuTSchi
; Remarks........: - Iterates all selected bags/panes and accumulates quantities per item.
; Related........: AddOns_GetInventoryItemCountbyModelID, AddOns_GetStorageItemCountbyModelID, Item_GetBagItemArray, Item_GetBagPtr,
;                  Memory_Read, DllCall, DllStructGetData, DllStructGetSize
; ===============================================================================================================================
Func AddOns_GetTotalItemCountbyModelID($a_i_ModelID, $a_b_IncludeEquipmentPack = False, $a_b_IncludeMaterialStorage = False)
    Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, _
        $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2, _
        $GC_I_INVENTORY_EQUIPMENT_PACK, $GC_I_INVENTORY_MATERIAL_STORAGE, _
        $GC_I_INVENTORY_STORAGE1, $GC_I_INVENTORY_STORAGE2, _
        $GC_I_INVENTORY_STORAGE3, $GC_I_INVENTORY_STORAGE4, _
        $GC_I_INVENTORY_STORAGE5, $GC_I_INVENTORY_STORAGE6, _
        $GC_I_INVENTORY_STORAGE7, $GC_I_INVENTORY_STORAGE8, _
        $GC_I_INVENTORY_STORAGE9, $GC_I_INVENTORY_STORAGE10, _
        $GC_I_INVENTORY_STORAGE11, $GC_I_INVENTORY_STORAGE12, _
        $GC_I_INVENTORY_STORAGE13, $GC_I_INVENTORY_STORAGE14 _
	]

    Local $l_d_Struct_Item = DllStructCreate( _
        "byte[" & $GC_I_OFFSET_ITEM_MODEL_ID & "];" & _
        "dword modelID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_QUANTITY - ($GC_I_OFFSET_ITEM_MODEL_ID + 4)) & "];" & _
        "short quantity" _
    )
    Local $l_i_StructSize_Item = DllStructGetSize($l_d_Struct_Item)

    Local $l_i_Count = 0
    For $bag In $l_ai_BagList
        If Not $a_b_IncludeEquipmentPack And $bag = $GC_I_INVENTORY_EQUIPMENT_PACK Then ContinueLoop
		If Not $a_b_IncludeMaterialStorage And $bag = $GC_I_INVENTORY_MATERIAL_STORAGE Then ContinueLoop

		$l_p_Bag = Item_GetBagPtr($bag)
		If $l_p_Bag = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($bag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_Item = $l_ap_ItemArray[$item]
            If $l_p_Item = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_Item, _
                "struct*", $l_d_Struct_Item, _
                "ulong_ptr", $l_i_StructSize_Item, _
                "ulong_ptr*", 0 _
            )

            Local $l_i_CurrentModelID = DllStructGetData($l_d_Struct_Item, "modelID")
            If $l_i_CurrentModelID = $a_i_ModelID Then $l_i_Count += DllStructGetData($l_d_Struct_Item, "quantity")
        Next
    Next

	Return $l_i_Count
EndFunc   ;==>AddOns_GetTotalItemCountbyModelID

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_WithdrawItemsFromStorage
; Description....: Withdraws items matching ModelID (and optional ExtraID) from storage into
;                  inventory. Can merge into partial stacks and/or split source stacks until
;                  the requested count is satisfied.
; Syntax.........: AddOns_WithdrawItemsFromStorage ( $a_i_ModelID, $a_i_ExtraID = -1, _
;                  $a_i_Count = -1, $a_i_StackFilter = 0, $a_b_MergeStacks = True )
; Parameters.....: $a_i_ModelID     - Int  : ModelID to withdraw.
;                  $a_i_ExtraID     - Int  : ExtraID to match, -1 = any.
;                  $a_i_Count       - Int  : Total quantity to withdraw; -1 = one stack/item.
;                  $a_i_StackFilter - Int  : 0=any, 1=full stacks only, 2=non-full stacks only.
;                  $a_b_MergeStacks - Bool : True merges into existing partial stacks first.
; Return values..: Success - True
;                  Failure - False, with @error:
;                            | 1 = No free inventory slot
;                            | 2 = Move/split timeout
;                            | 3 = No matching items found / exhausted
; Author.........: KleuTSchi
; Remarks........: - Prefers topping up partial stacks in inventory (cap 250) before creating
;                    new stacks when merging is enabled.
;                  - When $a_i_Count = -1, withdraws a single stack/item then returns.
;                  - Respects $a_i_StackFilter both for source selection and merge targets.
; Related........: AddOns_GetEmptyInventorySlot, Item_GetBagItemArray, Item_GetBagPtr, Item_GetInventoryArray,
;                  Item_GetStorageArray, Item_MoveItem_, Memory_Read, Other_GetPing, BitAND, DllCall,
;                  DllStructGetData, DllStructGetSize, SetError, Sleep, TimerDiff, TimerInit
; ===============================================================================================================================
Func AddOns_WithdrawItemsFromStorage($a_i_ModelID, $a_i_ExtraID = -1, $a_i_Count = -1, $a_i_StackFilter = 0, $a_b_MergeStacks = True)
    Local Const $LC_I_STACK_LIMIT = 250
    Local Const $LC_I_ITEMFLAG_STACKABLE = 0x80000

    Local $l_i_Ping = Other_GetPing()
    Local $l_b_SingleStack = ($a_i_Count = -1)

    Local $l_av2_InvArray = Item_GetInventoryArray()
    Local $l_i_InvArraySize = UBound($l_av2_InvArray, $UBOUND_ROWS)

    Local $l_av2_Targets[0][3]
    Local $l_i_TargetCount = 0
    For $i = 0 To $l_i_InvArraySize - 1
        If $l_av2_InvArray[$i][$GC_I_INVENTORY_MODELID] <> $a_i_ModelID Then ContinueLoop
        If $a_i_ExtraID <> -1 And $l_av2_InvArray[$i][$GC_I_INVENTORY_EXTRAID] <> $a_i_ExtraID Then ContinueLoop
        If Not $l_av2_InvArray[$i][$GC_I_INVENTORY_ISSTACKABLE] Then ContinueLoop
        Local $l_i_TargetQtySeed = $l_av2_InvArray[$i][$GC_I_INVENTORY_QUANTITY]
        If $l_i_TargetQtySeed >= $LC_I_STACK_LIMIT Then ContinueLoop

        ReDim $l_av2_Targets[$l_i_TargetCount + 1][3]
        $l_av2_Targets[$l_i_TargetCount][0] = $l_av2_InvArray[$i][$GC_I_INVENTORY_BAG]
        $l_av2_Targets[$l_i_TargetCount][1] = $l_av2_InvArray[$i][$GC_I_INVENTORY_SLOT]
        $l_av2_Targets[$l_i_TargetCount][2] = $l_i_TargetQtySeed
        $l_i_TargetCount += 1
    Next

    Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_STORAGE1, $GC_I_INVENTORY_STORAGE2, _
        $GC_I_INVENTORY_STORAGE3, $GC_I_INVENTORY_STORAGE4, _
        $GC_I_INVENTORY_STORAGE5, $GC_I_INVENTORY_STORAGE6, _
        $GC_I_INVENTORY_STORAGE7, $GC_I_INVENTORY_STORAGE8, _
        $GC_I_INVENTORY_STORAGE9, $GC_I_INVENTORY_STORAGE10, _
        $GC_I_INVENTORY_STORAGE11, $GC_I_INVENTORY_STORAGE12, _
        $GC_I_INVENTORY_STORAGE13, $GC_I_INVENTORY_STORAGE14 _
    ]

    Local $l_d_Struct_Item = DllStructCreate( _
        "byte[" & $GC_I_OFFSET_ITEM_EXTRA_ID & "];" & _
        "byte extraID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_FLAGS - ($GC_I_OFFSET_ITEM_EXTRA_ID + 1)) & "];" & _
        "dword itemFlag;" & _
        "dword modelID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_QUANTITY - ($GC_I_OFFSET_ITEM_MODEL_ID + 4)) & "];" & _
        "short quantity" _
    )
    Local $l_i_StructSize_Item = DllStructGetSize($l_d_Struct_Item)

    Local $l_i_TargetIdx = 0

    For $bag In $l_ai_BagList
        Local $l_p_SourceBag = Item_GetBagPtr($bag)
        If $l_p_SourceBag = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($l_p_SourceBag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_Item = $l_ap_ItemArray[$item]
            If $l_p_Item = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_Item, _
                "struct*", $l_d_Struct_Item, _
                "ulong_ptr", $l_i_StructSize_Item, _
                "ulong_ptr*", 0 _
            )

            Local $l_i_CurrentModelID = DllStructGetData($l_d_Struct_Item, "modelID")
            If $l_i_CurrentModelID <> $a_i_ModelID Then ContinueLoop
            Local $l_i_CurrentExtraID = DllStructGetData($l_d_Struct_Item, "extraID")
            If $a_i_ExtraID <> -1 And $l_i_CurrentExtraID <> $a_i_ExtraID Then ContinueLoop

            Local $l_i_ItemFlag = DllStructGetData($l_d_Struct_Item, "itemFlag")
            Local $l_b_Stackable = BitAND($l_i_ItemFlag, $LC_I_ITEMFLAG_STACKABLE) > 0
            Local $l_i_SourceQty = DllStructGetData($l_d_Struct_Item, "quantity")

            If $a_i_StackFilter <> 0 Then
                If $a_i_StackFilter = 1 And $l_i_SourceQty < $LC_I_STACK_LIMIT Then ContinueLoop ; FULL only
                If $a_i_StackFilter = 2 And $l_i_SourceQty = $LC_I_STACK_LIMIT Then ContinueLoop ; NON-full only
            EndIf

            If Not $a_b_MergeStacks Or Not $l_b_Stackable Then
                Local $l_ai_TargetSlot = AddOns_GetEmptyInventorySlot()
                If $l_ai_TargetSlot[0] = 0 Then Return SetError(1, 0, False)

                Item_MoveItem_($l_p_Item, $l_ai_TargetSlot[0], $l_ai_TargetSlot[1])

                Local $l_b_DoneStackable = False
                Local $l_h_TimeoutStackable = TimerInit()
                Do
                    Sleep(10 + $l_i_Ping)
                    Local $l_p_BagAfterStackable = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_BAGPTR, "ptr")
                    If $l_p_BagAfterStackable <> $l_p_SourceBag Then
                        $l_b_DoneStackable = True
                        ExitLoop
                    EndIf
                Until TimerDiff($l_h_TimeoutStackable) > (1500 + $l_i_Ping)
                If Not $l_b_DoneStackable Then Return SetError(2, 0, False)

                If $l_b_SingleStack Then Return True
                $a_i_Count -= $l_i_SourceQty
                If $a_i_Count <= 0 Then Return True
                ContinueLoop
            EndIf

            Local $l_b_SplitStacks = ($a_i_StackFilter <> 1)
            Local $l_i_SourceQtyToMove
            If $l_b_SingleStack Or Not $l_b_SplitStacks Then
                $l_i_SourceQtyToMove = $l_i_SourceQty
            Else
                $l_i_SourceQtyToMove = ($a_i_Count > $l_i_SourceQty) ? $l_i_SourceQty : $a_i_Count
            EndIf
            If $l_i_SourceQtyToMove <= 0 Then ContinueLoop

            If $l_b_SplitStacks And $l_i_TargetIdx < $l_i_TargetCount Then
                While $l_i_SourceQtyToMove > 0 And $l_i_TargetIdx < $l_i_TargetCount
                    Local $l_i_TargetQty = $l_av2_Targets[$l_i_TargetIdx][2]
                    Local $l_i_Capacity = $LC_I_STACK_LIMIT - $l_i_TargetQty
                    If $l_i_Capacity <= 0 Then
                        $l_i_TargetIdx += 1
                        ContinueLoop
                    EndIf

                    Local $l_i_MoveQty = ($l_i_SourceQtyToMove > $l_i_Capacity) ? $l_i_Capacity : $l_i_SourceQtyToMove
                    If $l_i_MoveQty <= 0 Then ExitLoop
                    Local $l_b_MoveFullQty = ($l_i_MoveQty = $l_i_SourceQty)

                    Item_MoveItem_($l_p_Item, $l_av2_Targets[$l_i_TargetIdx][0], $l_av2_Targets[$l_i_TargetIdx][1], $l_i_MoveQty)

                    Local $l_b_DoneSplit = False
                    Local $l_h_TimeoutSplit = TimerInit()
                    Do
                        Sleep(10 + $l_i_Ping)
                        If $l_b_MoveFullQty Then
                            Local $l_p_BagAfterSplit = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_BAGPTR, "ptr")
                            If $l_p_BagAfterSplit <> $l_p_SourceBag Then
                                $l_i_SourceQty = 0
                                $l_b_DoneSplit = True
                                ExitLoop
                            EndIf
                        Else
                            Local $l_i_QtyAfterSplit = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_QUANTITY, "short")
                            If $l_i_QtyAfterSplit < $l_i_SourceQty Then
                                $l_b_DoneSplit = True
                                $l_i_SourceQty = $l_i_QtyAfterSplit
                                ExitLoop
                            EndIf
                        EndIf
                    Until TimerDiff($l_h_TimeoutSplit) > (1500 + $l_i_Ping)
                    If Not $l_b_DoneSplit Then Return SetError(2, 0, False)

                    $l_av2_Targets[$l_i_TargetIdx][2] += $l_i_MoveQty
                    If $l_av2_Targets[$l_i_TargetIdx][2] >= $LC_I_STACK_LIMIT Then
                        $l_i_TargetIdx += 1
                    EndIf

                    $l_i_SourceQtyToMove -= $l_i_MoveQty
                    If Not $l_b_SingleStack Then
                        $a_i_Count -= $l_i_MoveQty
                        If $a_i_Count <= 0 Then Return True
                    EndIf
                WEnd
            EndIf

            If $l_i_SourceQtyToMove > 0 Then
                Local $l_ai_TargetSlot = AddOns_GetEmptyInventorySlot()
                If $l_ai_TargetSlot[0] = 0 Then Return SetError(1, 0, False)

                Local $l_i_MoveQtyRem = ($l_i_SourceQtyToMove > $LC_I_STACK_LIMIT) ? $LC_I_STACK_LIMIT : $l_i_SourceQtyToMove
                Local $l_b_MoveFullQtyRem = ($l_i_MoveQtyRem = $l_i_SourceQty)

                Item_MoveItem_($l_p_Item, $l_ai_TargetSlot[0], $l_ai_TargetSlot[1], $l_i_MoveQtyRem)

                Local $l_b_DoneRemainder = False
                Local $l_h_TimeoutRemainder = TimerInit()
                Do
                    Sleep(10 + $l_i_Ping)
                    If $l_b_MoveFullQtyRem Then
                        Local $l_p_BagAfterRemainder = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_BAGPTR, "ptr")
                        If $l_p_BagAfterRemainder <> $l_p_SourceBag Then
                            $l_b_DoneRemainder = True
                            $l_i_SourceQty = 0
                            ExitLoop
                        EndIf
                    Else
                        Local $l_i_QtyAfterRemainder = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_QUANTITY, "short")
                        If $l_i_QtyAfterRemainder < $l_i_SourceQty Then
                            $l_b_DoneRemainder = True
                            $l_i_SourceQty = $l_i_QtyAfterRemainder
                            ExitLoop
                        EndIf
                    EndIf
                Until TimerDiff($l_h_TimeoutRemainder) > (1500 + $l_i_Ping)
                If Not $l_b_DoneRemainder Then Return SetError(2, 0, False)

                If $a_i_StackFilter <> 1 And $l_i_TargetIdx >= $l_i_TargetCount Then
                    ReDim $l_av2_Targets[$l_i_TargetCount + 1][3]
                    $l_av2_Targets[$l_i_TargetCount][0] = $l_ai_TargetSlot[0]
                    $l_av2_Targets[$l_i_TargetCount][1] = $l_ai_TargetSlot[1]
                    $l_av2_Targets[$l_i_TargetCount][2] = $l_i_MoveQtyRem
                    $l_i_TargetIdx = $l_i_TargetCount
                    $l_i_TargetCount += 1
                EndIf

                $l_i_SourceQtyToMove -= $l_i_MoveQtyRem
                If Not $l_b_SingleStack Then
                    $a_i_Count -= $l_i_MoveQtyRem
                    If $a_i_Count <= 0 Then Return True
                EndIf
            EndIf

            If $l_b_SingleStack Then Return True
        Next
    Next

    Return SetError(3, 0, False)
EndFunc   ;==>AddOns_GetTotalItemCountbyModelID

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_DepositItemsToStorage
; Description....: Deposits items matching ModelID (and optional ExtraID) from inventory into
;                  storage. Can merge into partial stacks and/or split source stacks.
; Syntax.........: AddOns_DepositItemsToStorage ( $a_i_ModelID, $a_i_ExtraID = -1, _
;                  $a_i_StackFilter = -1, $a_b_MergeStacks = True, _
;                  $l_b_IncludeMaterialStorage = False )
; Parameters.....: $a_i_ModelID                - Int  : ModelID to deposit.
;                  $a_i_ExtraID                - Int  : ExtraID to match, -1 = any.
;                  $a_i_StackFilter            - Int  : -1=any, 1=full only, 2=non-full only.
;                  $a_b_MergeStacks            - Bool : True merges into existing partial stacks.
;                  $l_b_IncludeMaterialStorage - Bool : Include material storage panes.
; Return values..: Success - True
;                  Failure - False, with @error:
;                            | 2 = No free storage slot
;                            | 3 = Move/split timeout
; Author.........: KleuTSchi
; Remarks........: - Targets existing partial stacks in storage (cap 250) before allocating
;                    new slots when merging is enabled.
;                  - $a_i_StackFilter restricts which inventory stacks are eligible to move.
; Related........: AddOns_GetEmptyStorageSlot, Item_GetBagItemArray, Item_GetBagPtr, Item_GetInventoryArray,
;                  Item_GetStorageArray, Item_MoveItem_, Memory_Read, Other_GetPing, BitAND, DllCall, DllStructGetData,
;                  DllStructGetSize, SetError, Sleep, TimerDiff, TimerInit
; ===============================================================================================================================
Func AddOns_DepositItemsToStorage($a_i_ModelID, $a_i_ExtraID = -1, $a_i_StackFilter = -1, $a_b_MergeStacks = True, $l_b_IncludeMaterialStorage = False)
    Local Const $LC_I_STACK_LIMIT = 250
    Local Const $LC_I_ITEMFLAG_STACKABLE = 0x80000

    Local $l_i_Ping = Other_GetPing()

    Local $l_av2_StgArray = Item_GetStorageArray($l_b_IncludeMaterialStorage)
    Local $l_i_StgArraySize = UBound($l_av2_StgArray, $UBOUND_ROWS)

    Local $l_av2_Targets[0][3]
    Local $l_i_TargetCount = 0
    For $i = 0 To $l_i_StgArraySize - 1
        If $l_av2_StgArray[$i][$GC_I_INVENTORY_MODELID] <> $a_i_ModelID Then ContinueLoop
        If $a_i_ExtraID <> -1 And $l_av2_StgArray[$i][$GC_I_INVENTORY_EXTRAID] <> $a_i_ExtraID Then ContinueLoop
        If Not $l_av2_StgArray[$i][$GC_I_INVENTORY_ISSTACKABLE] Then ExitLoop
        Local $l_i_TargetQtySeed = $l_av2_StgArray[$i][$GC_I_INVENTORY_QUANTITY]
        If $l_i_TargetQtySeed >= $LC_I_STACK_LIMIT Then ContinueLoop

        ReDim $l_av2_Targets[$l_i_TargetCount + 1][3]
        $l_av2_Targets[$l_i_TargetCount][0] = $l_av2_StgArray[$i][$GC_I_INVENTORY_BAG]
        $l_av2_Targets[$l_i_TargetCount][1] = $l_av2_StgArray[$i][$GC_I_INVENTORY_SLOT]
        $l_av2_Targets[$l_i_TargetCount][2] = $l_i_TargetQtySeed
        $l_i_TargetCount += 1
    Next

    Local $l_ai_BagList[] = [ _
        $GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, _
        $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2, _
        $GC_I_INVENTORY_EQUIPMENT_PACK _
    ]

    Local $l_d_Struct_Item = DllStructCreate( _
        "byte[" & $GC_I_OFFSET_ITEM_EXTRA_ID & "];" & _
        "byte extraID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_FLAGS - ($GC_I_OFFSET_ITEM_EXTRA_ID + 1)) & "];" & _
        "dword itemFlag;" & _
        "dword modelID;" & _
        "byte[" & ($GC_I_OFFSET_ITEM_QUANTITY - ($GC_I_OFFSET_ITEM_MODEL_ID + 4)) & "];" & _
        "short quantity" _
    )
    Local $l_i_StructSize_Item = DllStructGetSize($l_d_Struct_Item)

    Local $l_i_TargetIdx = 0

    For $bag In $l_ai_BagList
        Local $l_p_SourceBag = Item_GetBagPtr($bag)
        If $l_p_SourceBag = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($l_p_SourceBag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_Item = $l_ap_ItemArray[$item]
            If $l_p_Item = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_Item, _
                "struct*", $l_d_Struct_Item, _
                "ulong_ptr", $l_i_StructSize_Item, _
                "ulong_ptr*", 0 _
            )

            Local $l_i_CurrentModelID = DllStructGetData($l_d_Struct_Item, "modelID")
            If $l_i_CurrentModelID <> $a_i_ModelID Then ContinueLoop
            Local $l_i_CurrentExtraID = DllStructGetData($l_d_Struct_Item, "extraID")
            If $a_i_ExtraID <> -1 And $l_i_CurrentExtraID <> $a_i_ExtraID Then ContinueLoop

            Local $l_i_ItemFlag = DllStructGetData($l_d_Struct_Item, "itemFlag")
            Local $l_b_Stackable = BitAND($l_i_ItemFlag, $LC_I_ITEMFLAG_STACKABLE) > 0
            Local $l_i_SourceQty = DllStructGetData($l_d_Struct_Item, "quantity")

            If $a_i_StackFilter <> 0 Then
                If $a_i_StackFilter = 1 And $l_i_SourceQty < $LC_I_STACK_LIMIT Then ContinueLoop ; FULL only
                If $a_i_StackFilter = 2 And $l_i_SourceQty = $LC_I_STACK_LIMIT Then ContinueLoop ; NON-full only
            EndIf

            If Not $a_b_MergeStacks Or Not $l_b_Stackable Then
                Local $l_ai_TargetSlot = AddOns_GetEmptyStorageSlot()
                If $l_ai_TargetSlot[0] = 0 Then Return SetError(2, 0, False)

                Item_MoveItem_($l_p_Item, $l_ai_TargetSlot[0], $l_ai_TargetSlot[1])

                Local $l_b_DoneStackable = False
                Local $l_h_TimeoutStackable = TimerInit()
                Do
                    Sleep(10 + $l_i_Ping)
                    Local $l_p_BagAfterStackable = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_BAGPTR, "ptr")
                    If $l_p_BagAfterStackable <> $l_p_SourceBag Then
                        $l_b_DoneStackable = True
                        ExitLoop
                    EndIf
                Until TimerDiff($l_h_TimeoutStackable) > (1500 + $l_i_Ping)
                If Not $l_b_DoneStackable Then Return SetError(3, 0, False)

                ContinueLoop
            EndIf

            Local $l_b_SplitStacks = ($a_i_StackFilter <> 1)
            If $l_b_SplitStacks And $l_i_TargetIdx < $l_i_TargetCount Then
                While $l_i_SourceQty > 0 And $l_i_TargetIdx < $l_i_TargetCount
                    Local $l_i_TargetQty = $l_av2_Targets[$l_i_TargetIdx][2]
                    Local $l_i_Capacity = $LC_I_STACK_LIMIT - $l_i_TargetQty
                    If $l_i_Capacity <= 0 Then
                        $l_i_TargetIdx += 1
                        ContinueLoop
                    EndIf

                    Local $l_i_MoveQty = ($l_i_SourceQty > $l_i_Capacity) ? $l_i_Capacity : $l_i_SourceQty
                    If $l_i_MoveQty <= 0 Then ExitLoop
                    Local $l_b_MoveFullQty = ($l_i_MoveQty = $l_i_SourceQty)

                    Item_MoveItem_($l_p_Item, $l_av2_Targets[$l_i_TargetIdx][0], $l_av2_Targets[$l_i_TargetIdx][1], $l_i_MoveQty)

                    Local $l_b_DoneSplit = False
                    Local $l_h_TimeoutSplit = TimerInit()
                    Do
                        Sleep(10 + $l_i_Ping)
                        If $l_b_MoveFullQty Then
                            Local $l_p_BagAfterSplit = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_BAGPTR, "ptr")
                            If $l_p_BagAfterSplit <> $l_p_SourceBag Then
                                $l_i_SourceQty = 0
                                $l_b_DoneSplit = True
                                ExitLoop
                            EndIf
                        Else
                            Local $l_i_QtyAfterSplit = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_QUANTITY, "short")
                            If $l_i_QtyAfterSplit < $l_i_SourceQty Then
                                $l_b_DoneSplit = True
                                $l_i_SourceQty = $l_i_QtyAfterSplit
                                ExitLoop
                            EndIf
                        EndIf
                    Until TimerDiff($l_h_TimeoutSplit) > (1500 + $l_i_Ping)
                    If Not $l_b_DoneSplit Then Return SetError(3, 0, False)

                    $l_av2_Targets[$l_i_TargetIdx][2] += $l_i_MoveQty
                    If $l_av2_Targets[$l_i_TargetIdx][2] >= $LC_I_STACK_LIMIT Then
                        $l_i_TargetIdx += 1
                    EndIf
                WEnd
            EndIf

            If $l_i_SourceQty > 0 Then
                Local $l_i_NewStackQty = $l_i_SourceQty
                Local $l_ai_TargetSlot = AddOns_GetEmptyStorageSlot()
                If $l_ai_TargetSlot[0] = 0 Then Return SetError(2, 0, False)

                Item_MoveItem_($l_p_Item, $l_ai_TargetSlot[0], $l_ai_TargetSlot[1])

                Local $l_b_DoneRemainder = False
                Local $l_h_TimeoutRemainder = TimerInit()
                Do
                    Sleep(10 + $l_i_Ping)
                    Local $l_p_BagAfterRemainder = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_BAGPTR, "ptr")
                    If $l_p_BagAfterRemainder <> $l_p_SourceBag Then
                        $l_b_DoneRemainder = True
                        ExitLoop
                    EndIf
                Until TimerDiff($l_h_TimeoutRemainder) > (1500 + $l_i_Ping)
                If Not $l_b_DoneRemainder Then Return SetError(3, 0, False)

                If $a_i_StackFilter <> 1 And $l_i_TargetIdx >= $l_i_TargetCount Then
                    ReDim $l_av2_Targets[$l_i_TargetCount + 1][3]
                    $l_av2_Targets[$l_i_TargetCount][0] = $l_ai_TargetSlot[0]
                    $l_av2_Targets[$l_i_TargetCount][1] = $l_ai_TargetSlot[1]
                    $l_av2_Targets[$l_i_TargetCount][2] = $l_i_NewStackQty
                    $l_i_TargetIdx = $l_i_TargetCount
                    $l_i_TargetCount += 1
                EndIf
            EndIf
        Next
    Next

    Return True
EndFunc   ;==>AddOns_DepositItemsToStorage

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetUseBag
; Description....: Checks if a bag ID is allowed by the provided bag toggles (Bag1..Bag4).
; Syntax.........: AddOns_GetUseBag ( $a_i_Bag, $a_b_Bag1, $a_b_Bag2, $a_b_Bag3, $a_b_Bag4 )
; Parameters.....: $a_i_Bag   - Int  : One of $GC_I_INVENTORY_BACKPACK | _BELT_POUCH | _BAG1 | _BAG2.
;                  $a_b_Bag1  - Bool : Allow Backpack.
;                  $a_b_Bag2  - Bool : Allow Belt Pouch.
;                  $a_b_Bag3  - Bool : Allow Bag1.
;                  $a_b_Bag4  - Bool : Allow Bag2.
; Return values..: Success - Bool (True if the bag is allowed or not one of the 4 known bags).
;                  Failure - n/a
; Author.........: KleuTSchi
; Remarks........: Unknown/non-listed bag IDs default to True.
; Related........: (none)
; ===============================================================================================================================
Func AddOns_GetUseBag($a_i_Bag, $a_b_Bag1, $a_b_Bag2, $a_b_Bag3, $a_b_Bag4)
    Switch $a_i_Bag
        Case $GC_I_INVENTORY_BACKPACK
            Return $a_b_Bag1
        Case $GC_I_INVENTORY_BELT_POUCH
            Return $a_b_Bag2
        Case $GC_I_INVENTORY_BAG1
            Return $a_b_Bag3
        Case $GC_I_INVENTORY_BAG2
            Return $a_b_Bag4
        Case Else
            Return True
    EndSwitch
EndFunc   ;==>AddOns_GetUseBag

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_FindIDKit
; Description....: Scans an inventory array and returns a compact list of identification kits
;                  with their remaining uses.
; Syntax.........: AddOns_FindIDKit ( $a_av2_Inv )
; Parameters.....: $a_av2_Inv - NxM array as returned by Item_GetInventoryArray().
; Return values..: Success - Nx2 array [KitItemID, Uses] (can be 0×2 if none found).
;                  Failure - n/a
; Author.........: KleuTSchi
; Remarks........: Uses the item Value field to derive remaining uses:
;                  Normal kit → Int(Value/2); Superior kit → Int((4*Value+5)/10).
; Related........: Int, UBound
; ===============================================================================================================================
Func AddOns_FindIDKit($a_av2_Inv)
    Local $l_i_ItemCnt = UBound($a_av2_Inv)
    Local $l_a_Kits[$l_i_ItemCnt][2]
    Local $l_i_IDKitCnt = 0

    For $i = 0 To $l_i_ItemCnt - 1
        Local $l_i_ModelID = $a_av2_Inv[$i][$GC_I_INVENTORY_MODELID]
        If $l_i_ModelID <> $GC_I_MODELID_IDENTIFICATION_KIT And $l_i_ModelID <> $GC_I_MODELID_SUPERIOR_IDENTIFICATION_KIT Then ContinueLoop

        Local $l_p_ItemID = $a_av2_Inv[$i][$GC_I_INVENTORY_ITEMID]
        Local $l_i_Value   = $a_av2_Inv[$i][$GC_I_INVENTORY_VALUE]

        Local $l_i_Uses = ($l_i_ModelID = $GC_I_MODELID_IDENTIFICATION_KIT) ? Int($l_i_Value / 2) : Int((4 * $l_i_Value + 5) / 10)

        $l_a_Kits[$l_i_IDKitCnt][0] = $l_p_ItemID
        $l_a_Kits[$l_i_IDKitCnt][1] = $l_i_Uses
        $l_i_IDKitCnt += 1
    Next

    ReDim $l_a_Kits[$l_i_IDKitCnt][2]
    Return $l_a_Kits
EndFunc   ;==>AddOns_FindIDKit


; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_FreeSlotForIDKit
; Description....: Frees exactly one inventory slot by selling one lowest-priority eligible
;                  weapon at the Merchant to make room for an identification kit.
; Syntax.........: AddOns_FreeSlotForIDKit ( $a_av2_Inv, $a_b_Bag1 = True, $a_b_Bag2 = True, $a_b_Bag3 = True, $a_b_Bag4 = True )
; Parameters.....: $a_av2_Inv - NxM inventory array (Item_GetInventoryArray()).
;                  $a_b_Bag1..4 - Bools to restrict which bags are eligible to sell from.
; Return values..: Success - True (one item sold).
;                  Failure - False (no suitable item found).
; Author.........: KleuTSchi
; Remarks........: - Skips rare skins (ItemFilter_IsRareSkin).
;                  - Priority order is controlled by an internal map (bows highest priority to
;                    sell first). If a top-rank match is found, it is sold immediately.
;                  - Honors bag toggles via AddOns_GetUseBag.
; Related........: AddOns_GetUseBag, AddOns_Out, ItemFilter_IsRareSkin, MapExists, Merchant_SellItem, Other_GetPing, Sleep
; ===============================================================================================================================
Func AddOns_FreeSlotForIDKit($a_av2_Inv, $a_b_Bag1 = True, $a_b_Bag2 = True, $a_b_Bag3 = True, $a_b_Bag4 = True)
    ; PriorityRank (lower = sell sooner)
    Local $l_m_TypePriority[]
    $l_m_TypePriority[5] = 0    ; Bow
    $l_m_TypePriority[15] = 1   ; Hammer
	$l_m_TypePriority[2] = 2    ; Axe
    $l_m_TypePriority[35] = 3   ; Scythe
    $l_m_TypePriority[36] = 4   ; Spear
    $l_m_TypePriority[27] = 5   ; Sword
    $l_m_TypePriority[32] = 6   ; Daggers
    $l_m_TypePriority[26] = 7   ; Staff
    $l_m_TypePriority[12] = 8   ; Focus
    $l_m_TypePriority[22] = 9   ; Wand
    $l_m_TypePriority[24] = 10  ; Shield

    Local $l_i_BestIdx = -1
    Local $l_i_BestRank = 999
    Local $l_i_Ping = Other_GetPing()

    For $i = 0 To UBound($a_av2_Inv, 1) - 1
        Local $l_i_Bag = $a_av2_Inv[$i][$GC_I_INVENTORY_BAG]
        If Not AddOns_GetUseBag($l_i_Bag, $a_b_Bag1, $a_b_Bag2, $a_b_Bag3, $a_b_Bag4) Then ContinueLoop

        Local $l_i_ModelID = $a_av2_Inv[$i][$GC_I_INVENTORY_MODELID]
        If ItemFilter_IsRareSkin($l_i_ModelID) Then ContinueLoop

        Local $l_i_Type = $a_av2_Inv[$i][$GC_I_INVENTORY_ITEMTYPE]
        If Not MapExists($l_m_TypePriority, $l_i_Type) Then ContinueLoop

        Local $l_i_Rank = $l_m_TypePriority[$l_i_Type]

        If $l_i_Rank = 0 Then
            Merchant_SellItem($a_av2_Inv[$i][$GC_I_INVENTORY_PTR])
            Sleep(150 + $l_i_Ping)
            Return True
        EndIf

        If $l_i_Rank < $l_i_BestRank Then
            $l_i_BestRank = $l_i_Rank
            $l_i_BestIdx  = $i
        EndIf
    Next

    If $l_i_BestIdx <> -1 Then
        Merchant_SellItem($a_av2_Inv[$l_i_BestIdx][$GC_I_INVENTORY_PTR])
        Sleep(150 + $l_i_Ping)
        Return True
    EndIf

    AddOns_Out("[ERR] No suitable item found to sell to make space for an ID Kit")
    Return False
EndFunc   ;==>AddOns_FreeSlotForIDKit

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_EnsureActiveIDKit
; Description....: Ensures there is a usable identification kit; advances to the next kit
;                  when depleted, or buys a new kit (with optional storage gold withdraw) and
;                  refreshes the inventory snapshot and kit list.
; Syntax.........: AddOns_EnsureActiveIDKit ( ByRef $a_ai2_Kits, ByRef $a_i_ActiveKitIdx, _
;                  ByRef $a_i_ActiveKitID, ByRef $a_i_ActiveKitUses, ByRef $l_av2_Inv, _
;                  $a_i_KitToBuy, $a_i_KitCost, _
;                  $a_b_Bag1 = True, $a_b_Bag2 = True, $a_b_Bag3 = True, $a_b_Bag4 = True )
; Parameters.....: $a_ai2_Kits        - ByRef Nx2 array [KitItemID, Uses]; updated in-place.
;                  $a_i_ActiveKitIdx  - ByRef Int index into $a_ai2_Kits; advanced as needed.
;                  $a_i_ActiveKitID   - ByRef Int ItemID of the active kit (out).
;                  $a_i_ActiveKitUses - ByRef Int remaining uses of active kit (out).
;                  $l_av2_Inv         - ByRef inventory array; refreshed after purchase.
;                  $a_i_KitToBuy      - Int  ModelID of kit to buy.
;                  $a_i_KitCost       - Int  Price in gold.
;                  $a_b_Bag1..4       - Bool bag-eligibility flags for freeing space if needed.
; Return values..: Success - True
;                  Failure - False, with @error:
;                            | 11 = Could not free slot (AddOns_FreeSlotForIDKit failed)
;                            | 12 = Buy failed even after withdrawing gold
;                            | 13 = Insufficient storage gold
;                            | 14 = Inventory refresh returned empty
;                            | 15 = Kit not found after successful buy
; Author.........: KleuTSchi
; Remarks........: - Attempts a single-slot free via AddOns_FreeSlotForIDKit if inventory is full.
;                  - Withdraws gold from storage when the first Merchant_BuyItem fails and
;                    storage has enough funds.
;                  - Rebuilds the kit list after purchase using AddOns_FindIDKit.
; Related........: AddOns_FindIDKit, AddOns_FreeSlotForIDKit, AddOns_GetEmptyInventorySlotCount, Item_GetInventoryArray,
;                  Item_GetInventoryInfo, Item_WithdrawGold, Merchant_BuyItem, Other_GetPing, Sleep, UBound
; ===============================================================================================================================
Func AddOns_EnsureActiveIDKit( _
        ByRef $a_ai2_Kits, _
        ByRef $a_i_ActiveKitIdx, _
        ByRef $a_i_ActiveKitID, _
        ByRef $a_i_ActiveKitUses, _
        ByRef $a_av2_Inv, _
        $a_i_KitToBuy, $a_i_KitCost, _
        $a_b_Bag1 = True, $a_b_Bag2 = True, $a_b_Bag3 = True, $a_b_Bag4 = True _
    )

    ; Advance past exhausted kits
    Local $l_i_KitCnt = UBound($a_ai2_Kits)
    While $a_i_ActiveKitIdx < $l_i_KitCnt And $a_ai2_Kits[$a_i_ActiveKitIdx][1] <= 0
        $a_i_ActiveKitIdx += 1
    WEnd

    If $a_i_ActiveKitIdx < $l_i_KitCnt Then
        $a_i_ActiveKitID = $a_ai2_Kits[$a_i_ActiveKitIdx][0]
        $a_i_ActiveKitUses = $a_ai2_Kits[$a_i_ActiveKitIdx][1]
        Return True
    EndIf

    ; No kit left -> attempt to make room and buy one
    If AddOns_GetEmptyInventorySlotCount() = 0 Then
        If Not AddOns_FreeSlotForIDKit($a_av2_Inv, $a_b_Bag1, $a_b_Bag2, $a_b_Bag3, $a_b_Bag4) Then
            Return SetError(11, 0, False)
        EndIf
    EndIf

    Local $l_i_Ping = Other_GetPing()
    If Not Merchant_BuyItem($a_i_KitToBuy) Then
        If Item_GetInventoryInfo("GoldStorage") >= $a_i_KitCost Then
            Item_WithdrawGold(500)
            Sleep(500 + $l_i_Ping)
            If Not Merchant_BuyItem($a_i_KitToBuy) Then
                Return SetError(12, 0, False)
            EndIf
        Else
            Return SetError(13, 0, False)
        EndIf
    EndIf
    Sleep(150 + $l_i_Ping)

    ; Refresh full inventory
    $a_av2_Inv = Item_GetInventoryArray()
    If UBound($a_av2_Inv) = 0 Then Return SetError(14, 0, False)

    Local $l_ai2_NewKits = AddOns_FindIDKit($a_av2_Inv)
    If UBound($l_ai2_NewKits) = 0 Then Return SetError(15, 0, False)

    $a_ai2_Kits = $l_ai2_NewKits
    $a_i_ActiveKitIdx = 0
    $a_i_ActiveKitID = $a_ai2_Kits[0][0]
    $a_i_ActiveKitUses = $a_ai2_Kits[0][1]
    Return True
EndFunc   ;==>AddOns_EnsureActiveIDKit

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_IdentifyInventory
; Description....: Identifies items in the player inventory according to rarity filters, consuming 
;                  uses from available identification kits and buying new kits when needed.
; Syntax.........: AddOns_IdentifyInventory ( _
;                  $a_i_IncludeBag1 = True, $a_i_IncludeBag2 = True, _
;                  $a_i_IncludeBag3 = True, $a_i_IncludeBag4 = True, _
;                  $a_b_IDWhiteItems = False, $a_b_IDBlueItems = True, _
;                  $a_b_IDPurpleItems = True, $a_b_IDGoldItems = True, _
;                  $a_i_KitToBuy = $GC_I_MODELID_SUPERIOR_IDENTIFICATION_KIT )
; Parameters.....: $a_i_IncludeBag1..4 - Bool: bag eligibility (also used when freeing a slot).
;                  $a_b_IDWhiteItems   - Bool: identify white items.
;                  $a_b_IDBlueItems    - Bool: identify blue items.
;                  $a_b_IDPurpleItems  - Bool: identify purple items.
;                  $a_b_IDGoldItems    - Bool: identify gold items.
;                  $a_i_KitToBuy       - Int : ModelID of kit to auto-purchase if needed.
; Return values..: Success - Int count of items identified.
;                  Failure - 0 with @error:
;                            | 1 = Inventory array empty
;                            | 11..15 = bubbled from AddOns_EnsureActiveIDKit (see its header)
; Author.........: KleuTSchi
; Remarks........: - Never identifies green items.
;                  - Waits up to ~2.5s for the identify flag to update per item.
;                  - Shares the bag-eligibility flags with the free-slot path so selling
;                    respects the same constraints.
; Related........: AddOns_EnsureActiveIDKit, AddOns_FindIDKit, AddOns_Out, Core_SendPacket, Item_GetInventoryArray,
;                  Item_GetItemInfoByItemID, Other_GetPing, Sleep, TimerDiff, TimerInit, UBound
; ===============================================================================================================================
Func AddOns_IdentifyInventory( _
        $a_i_IncludeBag1 = True, _
        $a_i_IncludeBag2 = True, _
        $a_i_IncludeBag3 = True, _
        $a_i_IncludeBag4 = True, _
        $a_b_IDWhiteItems = False, _
        $a_b_IDBlueItems = True, _
        $a_b_IDPurpleItems = True, _
        $a_b_IDGoldItems = True, _
        $a_i_KitToBuy = $GC_I_MODELID_SUPERIOR_IDENTIFICATION_KIT _
    )

    Local $l_i_Identified = 0

    ; Initial snapshot
    Local $l_av2_Inv = Item_GetInventoryArray()
    Local $l_i_ItemCnt = UBound($l_av2_Inv, $UBOUND_ROWS)
    If $l_i_ItemCnt <= 0 Then Return SetError(1, 0, $l_i_Identified)

    Local $l_i_Ping = Other_GetPing()
    Local $l_i_KitCost = ($a_i_KitToBuy = $GC_I_MODELID_SUPERIOR_IDENTIFICATION_KIT) ? 500 : 100

    ; Build current kit list and ensure we have an active kit
    Local $l_ai2_Kits = AddOns_FindIDKit($l_av2_Inv)
    Local $l_i_KitIdx = 0, $l_i_KitItemID = 0, $l_i_KitUses = 0

    If Not AddOns_EnsureActiveIDKit( _
            $l_ai2_Kits, _
            $l_i_KitIdx, _
            $l_i_KitItemID, _
            $l_i_KitUses, _
            $l_av2_Inv, _
            $a_i_KitToBuy, _
            $l_i_KitCost, _
            $a_i_IncludeBag1, $a_i_IncludeBag2, $a_i_IncludeBag3, $a_i_IncludeBag4 _
        ) Then
        Return SetError(@error, 0, $l_i_Identified)
    EndIf

    Local $l_i_InvIdx = 0

    While True
        ; Refresh current inventory size each iteration
        $l_i_ItemCnt = UBound($l_av2_Inv, $UBOUND_ROWS)

        If $l_i_ItemCnt <= 0 Then ExitLoop
        If $l_i_InvIdx >= $l_i_ItemCnt Then ExitLoop

        If $l_av2_Inv[$l_i_InvIdx][$GC_I_INVENTORY_ISIDENTIFIED] Then
            $l_i_InvIdx += 1
            ContinueLoop
        EndIf

        Local $l_i_Rarity = $l_av2_Inv[$l_i_InvIdx][$GC_I_INVENTORY_RARITY]
        Switch $l_i_Rarity
            Case $GC_I_RARITY_WHITE
                If Not $a_b_IDWhiteItems Then
                    $l_i_InvIdx += 1
                    ContinueLoop
                EndIf
            Case $GC_I_RARITY_BLUE
                If Not $a_b_IDBlueItems Then
                    $l_i_InvIdx += 1
                    ContinueLoop
                EndIf
            Case $GC_I_RARITY_PURPLE
                If Not $a_b_IDPurpleItems Then
                    $l_i_InvIdx += 1
                    ContinueLoop
                EndIf
            Case $GC_I_RARITY_GOLD
                If Not $a_b_IDGoldItems Then
                    $l_i_InvIdx += 1
                    ContinueLoop
                EndIf
            Case $GC_I_RARITY_GREEN
                $l_i_InvIdx += 1
                ContinueLoop
        EndSwitch

        Local $l_i_ItemID = $l_av2_Inv[$l_i_InvIdx][$GC_I_INVENTORY_ITEMID]

        ; Ensure we have a kit with remaining uses (advance or buy/refresh as needed)
        If $l_i_KitUses <= 0 Then
            $l_i_KitIdx += 1
            If Not AddOns_EnsureActiveIDKit( _
                    $l_ai2_Kits, _
                    $l_i_KitIdx, _
                    $l_i_KitItemID, _
                    $l_i_KitUses, _
                    $l_av2_Inv, _
                    $a_i_KitToBuy, _
                    $l_i_KitCost, _
                    $a_i_IncludeBag1, $a_i_IncludeBag2, $a_i_IncludeBag3, $a_i_IncludeBag4 _
                ) Then
                Return SetError(@error, 0, $l_i_Identified)
            EndIf
        EndIf

        Core_SendPacket(0xC, $GC_I_HEADER_ITEM_IDENTIFY, $l_i_KitItemID, $l_i_ItemID)

        Local $l_i_Timeout = TimerInit()
        Do
            Sleep(10 + $l_i_Ping)
        Until Item_GetItemInfoByItemID($l_i_ItemID, "IsIdentified") Or TimerDiff($l_i_Timeout) > 2500

        $l_i_KitUses -= 1
        $l_ai2_Kits[$l_i_KitIdx][1] = $l_i_KitUses
        $l_i_Identified += 1

        $l_i_InvIdx += 1
    WEnd

    Return $l_i_Identified
EndFunc   ;==>AddOns_IdentifyInventory

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_SellInventory
; Description....: Sells merchant-eligible items from the selected inventory bags.
; Syntax.........: AddOns_SellInventory ( _
;                  $a_i_IncludeBag1 = True, $a_i_IncludeBag2 = True, _
;                  $a_i_IncludeBag3 = True, $a_i_IncludeBag4 = True )
; Parameters.....: $a_i_IncludeBag1..4 - Bool flags to select bags to process.
; Return values..: Success - Int count of items sold.
;                  Failure - 0 with @error:
;                            | 1 = Inventory array empty
; Author.........: KleuTSchi
; Remarks........: - Decides sellability via ItemFilter_CanSellToMerchant_OS.
;                  - Expects to be at a merchant.
; Related........: AddOns_GetEmptyStorageSlot, AddOns_Out, GUI_PerRunAvg, GUICtrlSetData, Item_GetInventoryArray,
;                  ItemFilter_CanSellToMerchant_OS, Merchant_SellItem, Other_GetPing, Sleep, UBound
; ===============================================================================================================================
Func AddOns_SellInventory($a_i_IncludeBag1 = True, $a_i_IncludeBag2 = True, $a_i_IncludeBag3 = True, $a_i_IncludeBag4 = True)
    Local $l_av2_Inv = Item_GetInventoryArray($a_i_IncludeBag1, $a_i_IncludeBag2, $a_i_IncludeBag3, $a_i_IncludeBag4)
    Local $l_i_ItemCnt = UBound($l_av2_Inv)

    If $l_i_ItemCnt = 0 Then
        AddOns_Out("[ERR] Inventory array is empty")
        Return SetError(1, 0, 0)
    EndIf

    Local $l_i_Ping = Other_GetPing()
    Local $l_i_Sold = 0

    For $i = 0 To $l_i_ItemCnt - 1
        Local $l_p_Item = $l_av2_Inv[$i][$GC_I_INVENTORY_PTR]
        Local $l_i_Type = $l_av2_Inv[$i][$GC_I_INVENTORY_ITEMTYPE]
        Local $l_i_Value = $l_av2_Inv[$i][$GC_I_INVENTORY_VALUE]
        Local $l_i_ModelID = $l_av2_Inv[$i][$GC_I_INVENTORY_MODELID]

        If Not ItemFilter_CanSellToMerchant_OS($l_p_Item, $l_i_Type, $l_i_ModelID, $l_i_Value) Then ContinueLoop

        Merchant_SellItem($l_p_Item)
        Sleep(50 + $l_i_Ping)
        $l_i_Sold += 1
    Next

    Return $l_i_Sold
EndFunc   ;==>AddOns_SellInventory
#EndRegion Inventory

#Region Travel
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_RndTravel
; Description....: Travels to a target outpost/zone using a randomized district (region + language) selection.
;                  If already in the target map (and not in an explorable instance), optionally hops to a different district.
; Syntax.........: AddOns_RndTravel ( $a_i_MapID [, $a_b_SwitchDistrict = True ] )
; Parameters.....: $a_i_MapID          - Int  : Target MapID.
;                  $a_b_SwitchDistrict - Bool : If True and already in the target outpost,
;                                               switch to a different district; otherwise a
;                                               deterministic default district is used.
;                  $a_i_Mode           - Int  : Mode to set preferred region.
; Return values..: Success - Bool True  (map load completed).
;                  Failure - Bool False (Map_WaitMapIsLoaded failed).
; Author.........: KleuTSchi
; Remarks........: - District pool is defined by two parallel arrays (LC_AI_REGIONS / LC_AI_LANGUAGES). Their lengths MUST match.
;                  - Region/Language order: eu-en, eu-fr, eu-ger, eu-it, eu-sp, eu-po, eu-ru, us-en, int, asia-kr, asia-ch, asia-jp
;                                           [2, 2, 2, 2, 2, 2, 2, 0, -2, 1, 3, 4]
;                                           [0, 2, 3, 4, 5, 9, 10, 0, 0, 0, 0, 0]
;                  - When not currently in the target map OR when in an explorable instance,
;                    a random district index in is chosen.
;                  - When already in the target outpost and $a_b_SwitchDistrict=True, a random
;                    index is chosen and then adjusted to differ from the current (region,
;                    language) pair (simple +1 wrap).
;                  - Uses Map_InitMapIsLoaded/Map_WaitMapIsLoaded as load gates around Ui_MoveMap.
; Related........: Map_GetCharacterInfo, Map_GetInstanceInfo, Map_InitMapIsLoaded, _
;                  Map_WaitMapIsLoaded, Ui_MoveMap, Mod, Random
; ===============================================================================================================================
Func AddOns_RndTravel($a_i_MapID, $a_b_SwitchDistrict = True, $a_i_Mode = 1) ; 0 = All, 1 = EU-only, 2 = US-only, 3 = Asia-only
    Local Const $LC_AI_REGIONS[] = [2, 2, 2, 2, 2, 2, 2, 0, -2, 1, 3, 4]
    Local Const $LC_AI_LANGUAGES[] = [0, 2, 3, 4, 5, 9, 10, 0, 0, 0, 0, 0]

    Local $l_i_DistrictMin = 0, $l_i_DistrictMax = 11
    Switch $a_i_Mode
        Case 1 ; EU-only (No EU-EN)
            $l_i_DistrictMin = 1
            $l_i_DistrictMax = 6
        Case 2 ; EU-only (ALL)
            $l_i_DistrictMax = 6
        Case 3 ; US-only
            $l_i_DistrictMin = 7
            $l_i_DistrictMax = 8
        Case 4 ; Asia-only
            $l_i_DistrictMin = 9
    EndSwitch

    Local $l_i_ValidDistricts = $l_i_DistrictMax - $l_i_DistrictMin + 1

    Local $l_i_CurrentMap = Map_GetCharacterInfo("MapID")
    Local $l_i_CurrentRegion = Map_GetCharacterInfo("Region")
    Local $l_i_CurrentLanguage = Map_GetCharacterInfo("Language")

    If $l_i_CurrentMap <> $a_i_MapID Or Map_GetInstanceInfo("IsExplorable") Then
        Local $l_i_Idx = Random($l_i_DistrictMin, $l_i_DistrictMax, 1)
    Else
        If $a_b_SwitchDistrict Then
            If $l_i_ValidDistricts = 1 Then Return True
            Local $l_i_Idx = Random($l_i_DistrictMin, $l_i_DistrictMax, 1)
            If $LC_AI_REGIONS[$l_i_Idx] = $l_i_CurrentRegion And $LC_AI_LANGUAGES[$l_i_Idx] = $l_i_CurrentLanguage Then
                $l_i_Idx = Mod(($l_i_Idx - $l_i_DistrictMin) + 1, $l_i_ValidDistricts) + $l_i_DistrictMin
            EndIf
        Else
            Return True
        EndIf
    EndIf

    Map_InitMapIsLoaded()
    Ui_MoveMap($a_i_MapID, $LC_AI_REGIONS[$l_i_Idx], $LC_AI_LANGUAGES[$l_i_Idx], 0)
    Return Map_WaitMapIsLoaded()
EndFunc   ;==>AddOns_RndTravel
#EndRegion Travel

#Region Skills
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsRecharged
; Description....: Returns whether a given skillslot is currently recharged (usable).
; Syntax.........: AddOns_GetIsRecharged ( $a_i_Skillslot [, $a_i_HeroNumber = 0 ] )
; Parameters.....: $a_i_Skillslot  - Int  : 1..8 skillslot index.
;                  $a_i_HeroNumber - Int  : 0=player, 1..N=hero bar index.
; Return values..: Success - Bool True/False from Skill_GetSkillbarInfo("IsRecharged").
;                  Failure - Bool False if underlying call fails.
; Remarks........: Thin wrapper over Skill_GetSkillbarInfo; no extra validation done here.
; Related........: AddOns_GetAdrenaline, AddOns_GetAdrenalineReq, AddOns_GetEnergyReq, Skill_GetSkillbarInfo
; ===============================================================================================================================
Func AddOns_GetIsRecharged($a_i_Skillslot = 0, $a_i_HeroNumber = 0)
	Return Skill_GetSkillbarInfo($a_i_Skillslot, "IsRecharged", $a_i_HeroNumber)
EndFunc   ;==>GetIsRecharged

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetAdrenaline
; Description....: Returns current adrenaline pips for a given skillslot.
; Syntax.........: AddOns_GetAdrenaline ( $a_i_Skillslot [, $a_i_HeroNumber = 0 ] )
; Parameters.....: $a_i_Skillslot  - Int  : 1..8 skillslot index.
;                  $a_i_HeroNumber - Int  : 0=player, 1..N=hero bar index.
; Return values..: Success - Int adrenaline value from Skill_GetSkillbarInfo("Adrenaline").
;                  Failure - 0 on failure.
; Remarks........: Adrenaline is tracked per skill; this reads the skillbar slot field.
; Related........: AddOns_GetAdrenalineReq, AddOns_GetEnergyReq, AddOns_GetIsRecharged, Skill_GetSkillbarInfo
; ===============================================================================================================================
Func AddOns_GetAdrenaline($a_i_Skillslot = 0, $a_i_HeroNumber = 0)
	Return Skill_GetSkillbarInfo($a_i_Skillslot, "Adrenaline", $a_i_HeroNumber)
EndFunc	;==>GetAdrenaline

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEnergyReq
; Description....: Returns the energy cost of a skill, accounting for Quickening Zephyr.
; Syntax.........: AddOns_GetEnergyReq ( $a_i_SkillID )
; Parameters.....: $a_i_SkillID - Int : SkillID row index into $GC_AMX2_SKILL_DATA.
; Return values..: Success - Int energy cost (normal or QZ-adjusted).
;                  Failure - 0 if index is out of bounds.
; Remarks........: If the player has Quickening Zephyr, the QZ-adjusted column is used,
;                  otherwise the normal energy column is returned.
; Related........: AddOns_GetAdrenalineReq, AddOns_GetIsRecharged, AddOns_UseSkillEx, Agent_GetAgentEffectInfo
; ===============================================================================================================================
Func AddOns_GetEnergyReq($a_i_SkillID)
	If $a_i_SkillID < 0 Or $a_i_SkillID > $GC_I_SKILL_DATA_ROWS - 1 Then Return 0
	If Not Agent_GetAgentEffectInfo(-2, $GC_I_SKILL_ID_QUICKENING_ZEPHYR, "HasEffect") Then 
		Return $GC_AMX2_SKILL_DATA[$a_i_SkillID][$GC_I_SKILL_ENERGY_REQ]
	Else
		Return $GC_AMX2_SKILL_DATA[$a_i_SkillID][$GC_F_SKILL_ENERGY_REQ_QZ]
	EndIf
EndFunc   ;==>AddOns_GetEnergyReq

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetAdrenalineReq
; Description....: Returns the adrenaline requirement of a skill.
; Syntax.........: AddOns_GetAdrenalineReq ( $a_i_SkillID )
; Parameters.....: $a_i_SkillID - Int : SkillID row index into $GC_AMX2_SKILL_DATA.
; Return values..: Success - Int adrenaline cost.
;                  Failure - 0 if index is invalid.
; Remarks........: Simple table lookup; no state is considered.
; Related........: AddOns_GetAdrenaline, AddOns_GetEnergyReq, AddOns_GetIsRecharged, AddOns_UseSkillEx
; ===============================================================================================================================
Func AddOns_GetAdrenalineReq($a_i_SkillID)
	Return $GC_AMX2_SKILL_DATA[$a_i_SkillID][$GC_I_SKILL_ADRENALINE_REQ]
EndFunc   ;==>AddOns_GetAdrenalineReq

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_UseSkillEx
; Description....: Skill cast helper. Resolves/changes target, validates recharge/resources, issues the cast, waits for cast/aftercast.
; Syntax.........: AddOns_UseSkillEx ( $a_i_Skillslot [, $a_i_TargetID = -2  [, $a_i_Timeout = 3000 ]] )
; Parameters.....: $a_i_Skillslot - Int  : 1..8 skillslot index on the player bar.
;                  $a_i_TargetID  - Int  : -2=self, -1=current, else AgentID/Ptr convertible.
;                  $a_i_Timeout   - Int  : Max ms to wait while casting before giving up.
; Return values..: Success - Bool True (cast issued; waited through cast/aftercast).
;                  Failure - Bool False on soft conditions (dead, not recharged, insufficient energy/adrenaline), or when timeout hit.
;                  @error  - 1: target resolution failed (ID 0)
;                            2: player agent pointer missing
;                            3: player/skillbar memory read failed
;                            4: player skillbar not found
;                            5: skillslot read failed
; Remarks........: - Reads player/skillslot via cached structs. If the player is dead or the
;                    slot isn’t ready, returns False without setting @error.
;                  - Energy/adrenaline costs are looked up via AddOns_GetEnergyReq /
;                    AddOns_GetAdrenalineReq, so global modifiers (e.g., QZ) are honored.
;                  - Applies small, type-aware sleeps for activation and aftercast to reduce
;                    clipping (spells/signets use a shorter pre-sleep).
;                  - If $a_i_TargetID <> -2, the function will actively switch target.
; Related........: AddOns_GetAdrenalineReq, AddOns_GetEnergyReq, AddOns_GetIsCasting, Agent_ChangeTarget, Agent_ConvertID,
;                  Agent_GetAgentPtr, Agent_GetMyID, BitAND, DllCall, IsPtr, Skill_GetSkillTimer, Skill_UseSkill,
;                  World_GetWorldInfo, Sleep, TimerDiff, TimerInit
; ===============================================================================================================================
Func AddOns_UseSkillEx($a_i_Skillslot, $a_i_TargetID = -2, $a_i_Timeout = 10000)
    ; Determine target ID
    Local $l_i_TargetID
    If $a_i_TargetID = -2 Then
        $l_i_TargetID = Agent_GetMyID()
    Else
        $l_i_TargetID = Agent_ConvertID($a_i_TargetID)
    EndIf
    If $l_i_TargetID = 0 Then Return SetError(1, 0, False)
	
    ; Read player info
    Local $l_i_PlayerID = Agent_GetMyID()
    Local $l_p_Player = Agent_GetAgentPtr($l_i_PlayerID)
    If $l_p_Player = 0 Then Return SetError(2, 0, False)

    Local $l_av_CallPlayer = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Player, _
        "struct*", $g_d_PlayerStruct, _
		"ulong_ptr", $g_i_PlayerStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_CallPlayer[0] Then Return SetError(3, 0, False)

    Local $l_f_EnergyPercent = DllStructGetData($g_d_PlayerStruct, "energyPercent")
    Local $l_i_EnergyMax = DllStructGetData($g_d_PlayerStruct, "energyMax")
    Local $l_i_Effects = DllStructGetData($g_d_PlayerStruct, "effects")

	; Check if player is dead
    If BitAND($l_i_Effects, 0x10) Then Return False

    ; Read skillslot info
    Local $l_p_SkillbarArray = World_GetWorldInfo("SkillbarArray")
    Local $l_i_SkillbarArraySize = World_GetWorldInfo("SkillbarArraySize")
    If Not IsPtr($l_p_SkillbarArray) Or $a_i_Skillslot < 1 Or $a_i_Skillslot > 8 Then Return SetError(4, 0, False)

    Local $l_p_Skillbar
    For $i = 0 To $l_i_SkillbarArraySize - 1
        $l_p_Skillbar = $l_p_SkillbarArray + ($GC_I_STRIDE_SKILLBAR_ARRAY * $i)
        $l_i_AgentID = Memory_Read($l_p_Skillbar, "long")
        If $l_p_Skillbar <> 0 And $l_i_AgentID = $l_i_PlayerID Then ExitLoop
    Next
    If $l_p_Skillbar = 0 Or $l_i_AgentID <> $l_i_PlayerID Then Return SetError(5, 0, False)

    Local $l_p_Skillslot = $l_p_Skillbar + ($a_i_Skillslot - 1) * $GC_I_STRIDE_SKILLSLOTS

    Local $l_av_CallSkillslot = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Skillslot, _
        "struct*", $g_d_SkillslotStruct, _
		"ulong_ptr", $g_i_SkillslotStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_CallSkillslot[0] Then Return SetError(5,0,0)

    Local $l_i_Adrenaline = DllStructGetData($g_d_SkillslotStruct, "adrenaline")
    Local $l_i_Recharge = DllStructGetData($g_d_SkillslotStruct, "recharge")
    Local $l_i_SkillID = DllStructGetData($g_d_SkillslotStruct, "skillID")

    If $l_i_Recharge <> 0 And ($l_i_Recharge - Skill_GetSkillTimer()) <> 0 Then Return False

    ; Check for resources
    Local $l_i_EnergyReq = $GC_AMX2_SKILL_DATA[$l_i_SkillID][$GC_I_SKILL_ENERGY_REQ]
    Local $l_i_AdrenalineReq = $GC_AMX2_SKILL_DATA[$l_i_SkillID][$GC_I_SKILL_ADRENALINE_REQ]
    Local $l_f_Energy = $l_f_EnergyPercent * $l_i_EnergyMax

    If $l_i_EnergyReq <> 0 Then
		;- check for not enough energy
        If $l_f_Energy < AddOns_GetEnergyReq($l_i_SkillID) Then Return False
    ElseIf $l_i_AdrenalineReq <> 0 Then
		;- check for not enough adrenaline
        If $l_i_Adrenaline < AddOns_GetAdrenalineReq($l_i_SkillID) Then Return False
    EndIf

    ; Switch target if required
    If $a_i_TargetID <> -2 Then 
        Agent_ChangeTarget($l_i_TargetID)
    EndIf

    ; Use skill and wait for cast to finish
    Local $l_i_SkillType = $GC_AMX2_SKILL_DATA[$l_i_SkillID][$GC_I_SKILL_TYPE]
    Local $l_i_ActivationTime = $GC_AMX2_SKILL_DATA[$l_i_SkillID][$GC_F_SKILL_ACTIVATION_TIME] * 1000
           
    Skill_UseSkill($a_i_Skillslot, $l_i_TargetID)
    
    Local $l_h_Timeout = TimerInit()
    Do
        Sleep(50)
        Local $l_b_IsCasting = (Memory_Read($l_p_Skillbar + $GC_I_OFFSET_SKILLBAR_CASTING) <> 0)
    Until Not $l_b_IsCasting Or TimerDiff($l_h_Timeout) >= $a_i_Timeout

    Return True
EndFunc   ;==>AddOns_UseSkillEx
#EndRegion Skills

#Region Movement
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_MoveTo
; Description....: Moves the player toward a target (X,Y) until within a small threshold or a map transition begins.
;                  Includes stuck detection (/stuck after N ticks), optional per-tick callback, and light randomization.
; Syntax.........: AddOns_MoveTo ( $a_f_X, $a_f_Y [, $a_fn_Callback = "" [, $a_i_RandomSeed = 0 ]] )
; Parameters.....: $a_f_X .......... Target X coordinate (float).
;                  $a_f_Y .......... Target Y coordinate (float).
;                  $a_fn_Callback .. Optional function name (string). If non-empty, called each loop tick via Call().
;                  $a_i_RandomSeed . Optional integer forwarded to Map_Move for path randomization.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Player agent pointer not available (Agent_GetAgentPtr failed).
;                            2 -> Position/movement read failed (AddOns_GetXY_ / AddOns_GetMoveXY_ error).
;                  Failure - False without @error when:
;                            - Player is dead (AddOns_GetIsDead).
;                            - Stuck detection trips hard limit (>=20 consecutive stationary checks).
; Author.........: KleuTSchi
; Remarks........: - Uses a squared-distance threshold of 25^2 to consider the destination reached.
;                  - Performs one initial Map_Move(), then reissues it whenever movement vectors are zero.
;                  - Stuck logic: increments a counter each 250 ms tick with zero move vectors. On the 10th tick it sends
;                    "/stuck" (Chat_SendChat("stuck","/")); on the 20th tick it aborts with False.
;                  - If Map_MapIsLoaded() becomes true mid-travel (e.g., zone change), the function exits early with True
;                    so callers can synchronize to the new map.
;                  - The optional callback (if provided) runs every loop iteration; keep it lightweight and side-effect safe.
;                  - Loop cadence: Sleep(250) between checks; ping adjustments are not applied here.
; Related........: AddOns_ComputePseudoDistance, AddOns_GetIsDead, AddOns_GetMoveXY_, AddOns_GetXY_,
;                  Agent_GetAgentPtr, Chat_SendChat, Map_InitMapIsLoaded, Map_MapIsLoaded, Map_Move, Call, Sleep
; ===============================================================================================================================
Func AddOns_MoveTo($a_f_X, $a_f_Y, $a_fn_Callback = "", $a_i_RandomSeed = 0)
    Local $l_p_Player = Agent_GetAgentPtr()
    If $l_p_Player = 0 Then Return SetError(1, 0, False)

    Map_InitMapIsLoaded()

    Local Const $LC_I_DISTANCE_THRESHOLD = $a_i_RandomSeed * $a_i_RandomSeed + 25 * 25

    Local $l_b_InitialMove = True
    Local $l_i_Count_Stuck = 0

    Do
        If AddOns_GetIsDead($l_p_Player) Then Return False
        If Map_MapIsLoaded() Then ExitLoop

        $l_af_Pos = AddOns_GetXY_($l_p_Player)
        If @error Then Return SetError(2, 0, False)

        Local $l_f_X = $l_af_Pos[0]
        Local $l_f_Y = $l_af_Pos[1]

        Local $l_i_DistanceSq = AddOns_ComputePseudoDistance($a_f_X, $a_f_Y, $l_f_X, $l_f_Y)
        If $l_i_DistanceSq < $LC_I_DISTANCE_THRESHOLD Then ExitLoop

        If $l_b_InitialMove Then 
            $l_b_InitialMove = False
            Map_Move($a_f_X, $a_f_Y, $a_i_RandomSeed)
        EndIf

        If $a_fn_Callback <> "" Then Call($a_fn_Callback)

        Local $l_af_MoveXY = AddOns_GetMoveXY_($l_p_Player)
        If @error Then Return SetError(2, 0, False)
            
        Local $l_f_MoveX = $l_af_MoveXY[0]
        Local $l_f_MoveY = $l_af_MoveXY[1]

        If $l_f_MoveX = 0 And $l_f_MoveY = 0 Then
            $l_i_Count_Stuck += 1
            If $l_i_Count_Stuck = 10 Then
                Chat_SendChat("stuck", "/")
            ElseIf $l_i_Count_Stuck >= 20 Then
                Return False
            EndIf
            Map_Move($a_f_X, $a_f_Y, $a_i_RandomSeed)
        Else
            $l_i_Count_Stuck = 0
        EndIf

        Sleep(100)
    Until False

    Return True
EndFunc   ;==>AddOns_MoveTo

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_MoveTo_
; Description....: Moves the player toward a target (X,Y) using progress-based anti-stuck logic. Continues until the
;                  squared distance to the goal is below 25^2 or a map transition begins. Sends "/stuck" after repeated
;                  lack of progress and aborts on hard-stuck or death. Invokes an optional per-tick callback.
; Syntax.........: AddOns_MoveTo_ ( $a_f_X, $a_f_Y [, $a_fn_Callback = "" [, $a_i_RandomSeed = 0 ]] )
; Parameters.....: $a_f_X .......... Target X coordinate (float).
;                  $a_f_Y .......... Target Y coordinate (float).
;                  $a_fn_Callback .. Optional function name (string). If non-empty, executed each loop tick via Call().
;                  $a_i_RandomSeed . Optional integer forwarded to Map_Move for path randomization.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Player agent pointer not available (Agent_GetAgentPtr failed).
;                            2 -> Position read failed (AddOns_GetXY_ error).
;                  Failure - False without @error when:
;                            - Player is dead (AddOns_GetIsDead).
;                            - Hard-stuck triggered (≥5 no-progress windows).
; Author.........: KleuTSchi
; Remarks........: - Progress is measured over rolling 1,000 ms windows; movement ≥ 50^2 (squared units) resets the
;                    stuck counter. On the 3rd consecutive no-progress window, "/stuck" is sent and Map_Move is reissued.
;                    On the 5th window, the function aborts with False.
;                  - The destination is considered reached when distance^2 < 25^2.
;                  - Map_InitMapIsLoaded is called upfront; if Map_MapIsLoaded() becomes true mid-travel (e.g., zoning),
;                    the function exits early with True so callers can handle the transition.
;                  - Map_Move($a_f_X, $a_f_Y, $a_i_RandomSeed) is issued every loop iteration to keep pathing active.
;                  - Loop cadence is Sleep(250) per tick; no ping-based delays are applied here.
;                  - The optional callback should be lightweight and side-effect safe; it runs once per loop tick.
; Related........: AddOns_ComputePseudoDistance, AddOns_GetIsDead, AddOns_GetXY_, Agent_GetAgentPtr, Chat_SendChat,
;                  Map_InitMapIsLoaded, Map_MapIsLoaded, Map_Move, Call, Sleep, TimerDiff, TimerInit
; ===============================================================================================================================
Func AddOns_MoveTo_($a_f_X, $a_f_Y, $a_fn_Callback = "", $a_i_RandomSeed = 0)
    Local $l_p_Player = Agent_GetAgentPtr()
    If $l_p_Player = 0 Then Return SetError(1, 0, False)

    Map_InitMapIsLoaded()

    Local Const $LC_I_DISTANCE_THRESHOLD = 25 * 25
    Local Const $LC_I_PROGRESS_SQ = 50 * 50
    Local Const $LC_I_PROGRESS_WINDOW_MS = 1000

    Local $l_f_LastX, $l_f_LastY

    Local $l_h_ProgressTimer = TimerInit()
    Local $l_i_Count_Stuck = 0
    Local $l_b_Seeded = False

    Do
        If AddOns_GetIsDead($l_p_Player) Then Return False
        If Map_MapIsLoaded() Then ExitLoop

        If $a_fn_Callback <> "" Then Call($a_fn_Callback)

        $l_af_Pos = AddOns_GetXY_($l_p_Player)
        If @error Then Return SetError(2, 0, False)

        Local $l_f_X = $l_af_Pos[0], $l_f_Y = $l_af_Pos[1]

        Local $l_i_DistanceSq = AddOns_ComputePseudoDistance($a_f_X, $a_f_Y, $l_f_X, $l_f_Y)
        If $l_i_DistanceSq < $LC_I_DISTANCE_THRESHOLD Then ExitLoop

        Local $l_i_StepSq = 0
        If $l_b_Seeded Then
            $l_i_StepSq = AddOns_ComputePseudoDistance($l_f_X, $l_f_Y, $l_f_LastX, $l_f_LastY)
        Else
            $l_b_Seeded = True
            $l_i_StepSq = $LC_I_PROGRESS_SQ
        EndIf

        If $l_i_StepSq >= $LC_I_PROGRESS_SQ Then
            $l_i_Count_Stuck = 0
            $l_h_ProgressTimer = TimerInit()
            $l_f_LastX = $l_f_X
            $l_f_LastY = $l_f_Y
        Else
            If TimerDiff($l_h_ProgressTimer) > $LC_I_PROGRESS_WINDOW_MS Then
                $l_i_Count_Stuck += 1
                $l_h_ProgressTimer = TimerInit()

                If $l_i_Count_Stuck = 3 Then
                    Chat_SendChat("stuck", "/")
                    Map_Move($a_f_X, $a_f_Y, $a_i_RandomSeed)
                ElseIf $l_i_Count_Stuck >= 5 Then
                    Return False
                EndIf
            EndIf
        EndIf

        Map_Move($a_f_X, $a_f_Y, $a_i_RandomSeed)

        Sleep(250)
    Until False

    Return True
EndFunc   ;==>AddOns_MoveTo_
#EndRegion Movement

#Region Distance Calculation & Coordinates
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetMoveX
; Description....: Returns the X movement vector of an agent.
; Syntax.........: AddOns_GetMoveX ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - Float X component.
;                  Failure - 0 on failure.
; Remarks........: Lightweight wrapper around Agent_GetAgentInfo("MoveX").
; Related........: AddOns_GetMoveXY, AddOns_GetMoveXY_, AddOns_GetMoveY, Agent_GetAgentInfo
; ===============================================================================================================================
Func AddOns_GetMoveX($a_i_AgentID = -2)
	Return Agent_GetAgentInfo($a_i_AgentID, "MoveX")
EndFunc	   ;==>AddOns_GetMoveX

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetMoveY
; Description....: Returns the Y movement vector of an agent.
; Syntax.........: AddOns_GetMoveY ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - Float Y component.
;                  Failure - 0 on failure.
; Remarks........: Lightweight wrapper around Agent_GetAgentInfo("MoveY").
; Related........: AddOns_GetMoveX, AddOns_GetMoveXY, AddOns_GetMoveXY_, Agent_GetAgentInfo
; ===============================================================================================================================
Func AddOns_GetMoveY($a_i_AgentID = -2)
	Return Agent_GetAgentInfo($a_i_AgentID, "MoveY")
EndFunc	   ;==>AddOns_GetMoveY

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetMoveXY
; Description....: Returns [X,Y] movement vector of an agent via direct memory reads.
; Syntax.........: AddOns_GetMoveXY ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - 1x2 array [moveX, moveY].
;                  Failure - Sets @error:
;                            1=null agent ptr.
; Remarks........: Reads offsets $GC_I_OFFSET_AGENT_POS_X/$GC_I_OFFSET_AGENT_POS_Y from the agent; prefer AddOns_GetMoveXY_ for fewer kernel calls in tight loops.
; Related........: AddOns_GetMoveXY_, AddOns_GetMoveX, AddOns_GetMoveY, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetMoveXY($a_i_AgentID = -2)
	Local $l_af_Vectors[2] = [0, 0]
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, $l_af_Vectors)
        
	$l_af_Vectors[0] = Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_POS_X, "float")
	$l_af_Vectors[1] = Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_POS_Y, "float")
	Return $l_af_Vectors
EndFunc	   ;==>AddOns_GetMoveXY

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetMoveXY_
; Description....: Returns [X,Y] movement vector using a cached ReadProcessMemory struct.
; Syntax.........: AddOns_GetMoveXY_ ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - 1x2 array [moveX, moveY].
;                  Failure - Sets @error:
;                            1=null agent ptr, 2=ReadProcessMemory failed.
; Remarks........: Faster than AddOns_GetMoveXY in hot paths; reuses $g_d_MoveXYStruct.
; Related........: AddOns_GetMoveXY, AddOns_GetXY_, Agent_GetAgentPtr, DllCall, DllStructGetData
; ===============================================================================================================================
Func AddOns_GetMoveXY_($a_i_AgentID = -2)
	Local $l_af_Vectors[2] = [0, 0]
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, $l_af_Vectors)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
        "handle", $g_h_GWProcess, _
        "ptr", $l_p_Agent, _
        "struct*", $g_d_MoveXYStruct, _
        "ulong_ptr", $g_i_MoveXYStructSize, _
        "ulong_ptr*", 0 _
    )
    If @error Or Not $l_av_Call[0] Then Return SetError(2,0,0)

    $l_af_Vectors[0] = DllStructGetData($g_d_MoveXYStruct, "moveX")
    $l_af_Vectors[1] = DllStructGetData($g_d_MoveXYStruct, "moveY")
	Return $l_af_Vectors
EndFunc	   ;==>AddOns_GetMoveXY_

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetX
; Description....: Returns the X coordinate of an agent.
; Syntax.........: AddOns_GetX ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - Float X coordinate.
;                  Failure - 0 on failure.
; Remarks........: Wrapper over Agent_GetAgentInfo("X").
; Related........: AddOns_GetXY, AddOns_GetXY_, AddOns_GetY, Agent_GetAgentInfo
; ===============================================================================================================================
Func AddOns_GetX($a_i_AgentID = -2)
	Return Agent_GetAgentInfo($a_i_AgentID, "X")
EndFunc	   ;==>AddOns_GetX

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetY
; Description....: Returns the Y coordinate of an agent.
; Syntax.........: AddOns_GetY ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - Float Y coordinate.
;                  Failure - 0 on failure.
; Remarks........: Wrapper over Agent_GetAgentInfo("Y").
; Related........: AddOns_GetX, AddOns_GetXY, AddOns_GetXY_, Agent_GetAgentInfo
; ===============================================================================================================================
Func AddOns_GetY($a_i_AgentID = -2)
	Return Agent_GetAgentInfo($a_i_AgentID, "Y")
EndFunc	   ;==>AddOns_GetY

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetXY
; Description....: Returns [X,Y] coordinates of an agent via direct memory reads.
; Syntax.........: AddOns_GetXY ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - 1x2 array [X, Y].
;                  Failure - Sets @error:
;                            1=null agent ptr.
; Remarks........: Reads offsets $GC_I_OFFSET_AGENT_POS_X/$GC_I_OFFSET_AGENT_POS_Y from the agent; prefer AddOns_GetXY_ for fewer kernel calls in tight loops.
; Related........: AddOns_GetXY_, AddOns_GetX, AddOns_GetY, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetXY($a_i_AgentID = -2)
	Local $l_af_Coordinates[2] = [0, 0]
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, $l_af_Coordinates)

	$l_af_Coordinates[0] = Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_POS_X, "float")
	$l_af_Coordinates[1] = Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_POS_Y, "float")
	Return $l_af_Coordinates
EndFunc	   ;==>AddOns_GetXY

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetXY_
; Description....: Returns [X,Y] coordinates using a cached ReadProcessMemory struct.
; Syntax.........: AddOns_GetXY_ ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - Int : -2=self, -1=current target, else AgentID/ptr convertible.
; Return values..: Success - 1x2 array [X, Y].
;                  Failure - Sets @error:
;                            1=null agent ptr, 2=ReadProcessMemory failed.
; Remarks........: Faster than AddOns_GetXY in hot paths; reuses $g_d_PosXYStruct.
; Related........: AddOns_GetXY, AddOns_GetDistance, AddOns_GetDistanceToXY, Agent_GetAgentPtr, DllCall, DllStructGetData
; ===============================================================================================================================
Func AddOns_GetXY_($a_i_AgentID = -2)
	Local $l_af_Coordinates[2] = [0, 0]
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, $l_af_Coordinates)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
        "handle", $g_h_GWProcess, _
        "ptr", $l_p_Agent, _
        "struct*", $g_d_PosXYStruct, _
        "ulong_ptr", $g_i_PosXYStructSize, _
        "ulong_ptr*", 0 _
    )
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, 0)

    $l_af_Coordinates[0] = DllStructGetData($g_d_PosXYStruct, "posX")
    $l_af_Coordinates[1] = DllStructGetData($g_d_PosXYStruct, "posY")
	Return $l_af_Coordinates
EndFunc	   ;==>AddOns_GetXY_

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ComputeDistance
; Description....: Euclidean distance between two (x,y) points.
; Syntax.........: AddOns_ComputeDistance ( $a_f_X1, $a_f_Y1, $a_f_X2, $a_f_Y2 )
; Parameters.....: $a_f_X1/$a_f_Y1 - Float : First point.
;                  $a_f_X2/$a_f_Y2 - Float : Second point.
; Return values..: Success - Float distance.
; Remarks........: Pure math; prefer AddOns_ComputePseudoDistance for cheaper comparisons.
; Related........: AddOns_ComputePseudoDistance, AddOns_GetDistance, AddOns_GetDistanceToXY, Sqrt
; ===============================================================================================================================
Func AddOns_ComputeDistance($a_f_X1, $a_f_Y1, $a_f_X2, $a_f_Y2)
    Local $l_f_DeltaX = $a_f_X1 - $a_f_X2
    Local $l_f_DeltaY = $a_f_Y1 - $a_f_Y2
    Return Sqrt($l_f_DeltaX * $l_f_DeltaX + $l_f_DeltaY * $l_f_DeltaY)
EndFunc   ;==>AddOns_ComputeDistance

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetDistance
; Description....: Distance between two agents (uses AddOns_GetXY_ + Euclidean distance).
; Syntax.........: AddOns_GetDistance ( [$a_i_AgentID1 = -1 [, $a_i_AgentID2 = -2]] )
; Parameters.....: $a_i_AgentID1 - Int : -1=current target, otherwise AgentID/ptr convertible.
;                  $a_i_AgentID2 - Int : -2=self, otherwise AgentID/ptr convertible.
; Return values..: Success - Float distance.
;                  Failure - -1 if either coordinate query fails.
;                            Sets @error:
;                            1=query for agent 1 failed, 2=query for agent 2 failed.
; Remarks........: Uses the struct-based coordinate reader for performance.
; Related........: AddOns_GetDistanceToXY, AddOns_GetXY_, AddOns_ComputeDistance
; ===============================================================================================================================
Func AddOns_GetDistance($a_i_AgentID1 = -1, $a_i_AgentID2 = -2)
    Local $l_af_Coordinates_AgentID1 = AddOns_GetXY_($a_i_AgentID1)
    If @error Then Return SetError(1, 0, -1)

    Local $l_af_Coordinates_AgentID2 = AddOns_GetXY_($a_i_AgentID2)
    If @error Then Return SetError(2, 0, -1)

	Return AddOns_ComputeDistance($l_af_Coordinates_AgentID1[0], $l_af_Coordinates_AgentID1[1], $l_af_Coordinates_AgentID2[0], $l_af_Coordinates_AgentID2[1])
EndFunc   ;==>AddOns_GetDistance

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetDistanceToXY
; Description....: Distance from an agent to a map coordinate.
; Syntax.........: AddOns_GetDistanceToXY ( $a_f_X, $a_f_Y [, $a_i_AgentID = -2] )
; Parameters.....: $a_f_X/$a_f_Y - Float : Target coordinate.
;                  $a_i_AgentID  - Int   : -2=self, else AgentID/ptr convertible.
; Return values..: Success - Float distance.
;                  Failure - -1 if agent coordinate query fails.
;                            Sets @error:
;                            1=query for agent 1 failed.
; Remarks........: Struct-based coordinate read; pairs with AddOns_GetDistance.
; Related........: AddOns_GetDistance, AddOns_GetXY_, AddOns_ComputeDistance
; ===============================================================================================================================
Func AddOns_GetDistanceToXY($a_f_X, $a_f_Y, $a_i_AgentID = -2)
    Local $l_af_Coordinates_AgentID = AddOns_GetXY_($a_i_AgentID)
    If @error Then Return SetError(1, 0, -1)

	Return AddOns_ComputeDistance($a_f_X, $a_f_Y, $l_af_Coordinates_AgentID[0], $l_af_Coordinates_AgentID[1])
EndFunc   ;==>AddOns_GetDistanceToXY

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ComputePseudoDistance
; Description....: Squared Euclidean distance (no sqrt) between two (x,y) points.
; Syntax.........: AddOns_ComputePseudoDistance ( $a_f_X1, $a_f_Y1, $a_f_X2, $a_f_Y2 )
; Parameters.....: $a_f_X1/$a_f_Y1 - Float : First point.
;                  $a_f_X2/$a_f_Y2 - Float : Second point.
; Return values..: Success - Float distance squared.
; Remarks........: Use for cheaper comparisons or threshold checks.
; Related........: AddOns_ComputeDistance, AddOns_GetPseudoDistance, AddOns_GetPseudoDistanceToXY
; ===============================================================================================================================
Func AddOns_ComputePseudoDistance($a_f_X1, $a_f_Y1, $a_f_X2, $a_f_Y2)
    Local $l_f_DeltaX = $a_f_X1 - $a_f_X2
    Local $l_f_DeltaY = $a_f_Y1 - $a_f_Y2
    Return $l_f_DeltaX * $l_f_DeltaX + $l_f_DeltaY * $l_f_DeltaY
EndFunc   ;==>AddOns_ComputePseudoDistance

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetPseudoDistance
; Description....: Squared distance between two agents (struct-based XY read).
; Syntax.........: AddOns_GetPseudoDistance ( [$a_i_AgentID1 = -1 [, $a_i_AgentID2 = -2]] )
; Parameters.....: $a_i_AgentID1 - Int : -1=current target, otherwise AgentID/ptr convertible.
;                  $a_i_AgentID2 - Int : -2=self, otherwise AgentID/ptr convertible.
; Return values..: Success - Float distance squared.
;                  Failure - -1 if either coordinate query fails.
;                  Sets @error:
;                  1=query for agent 1 failed, 2=query for agent 2 failed.
; Remarks........: Avoids sqrt for faster gating (range checks, ordering).
; Related........: AddOns_GetPseudoDistanceToXY, AddOns_GetXY_, AddOns_ComputePseudoDistance
; ===============================================================================================================================
Func AddOns_GetPseudoDistance($a_i_AgentID1 = -1, $a_i_AgentID2 = -2)
	Local $l_af_Coordinates_AgentID1 = AddOns_GetXY_($a_i_AgentID1)
    If @error Then Return SetError(1, 0, -1)

    Local $l_af_Coordinates_AgentID2 = AddOns_GetXY_($a_i_AgentID2)
    If @error Then Return SetError(2, 0, -1)

	Return AddOns_ComputePseudoDistance($l_af_Coordinates_AgentID1[0], $l_af_Coordinates_AgentID1[1], $l_af_Coordinates_AgentID2[0], $l_af_Coordinates_AgentID2[1])
EndFunc   ;==>AddOns_GetDistance

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetPseudoDistanceToXY
; Description....: Squared distance from an agent to a map coordinate.
; Syntax.........: AddOns_GetPseudoDistanceToXY ( $a_f_X, $a_f_Y [, $a_i_AgentID = -2] )
; Parameters.....: $a_f_X/$a_f_Y - Float : Target coordinate.
;                  $a_i_AgentID  - Int   : -2=self, else AgentID/ptr convertible.
; Return values..: Success - Float distance squared.
;                  Failure - -1 if agent coordinate query fails.
;                  Sets @error:
;                  1=query for agent 1 failed.
; Remarks........: Favor this for thresholding and nearest-point scans.
; Related........: AddOns_GetPseudoDistance, AddOns_GetXY_, AddOns_ComputePseudoDistance
; ===============================================================================================================================
Func AddOns_GetPseudoDistanceToXY($a_f_X, $a_f_Y, $a_i_AgentID = -2)
	Local $l_af_Coordinates = AddOns_GetXY_($a_i_AgentID)
    If @error Then Return SetError(1, 0, -1)

	Return AddOns_ComputePseudoDistance($a_f_X, $a_f_Y, $l_af_Coordinates[0], $l_af_Coordinates[1])
EndFunc   ;==>AddOns_GetDistanceToXY
#EndRegion Distance Calculation & Coordinates

#Region Agents
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_ConvertPlayerNumber
; Description....: Converts a PlayerNumber to a live AgentID.
; Syntax.........: AddOns_ConvertPlayerNumber ( $a_i_PlayerNumber )
; Parameters.....: $a_i_PlayerNumber - PlayerNumber/model ID to resolve.
; Return values..: Success - AgentID (dword)
;                  Failure - 0 (not found)
; Remarks........: Walks World->PlayerArray with stride 0x4C and compares PlayerNumber @+$GC_I_OFFSET_PLAYER_PLAYERNUMBER;
;                  returns the AgentID stored at base of that entry.
; Related........: AddOns_GetIsDead, AddOns_GetIsEnchanted, AddOns_GetHasWeaponSpell, Agent_GetAgentPtr, World_GetWorldInfo, Memory_Read
; ===============================================================================================================================
Func AddOns_ConvertPlayerNumber($a_i_PlayerNumber, $a_s_Info = "")
    Local $l_p_PlayerArray = World_GetWorldInfo("PlayerArray")
    Local $l_i_PlayerArraySize = World_GetWorldInfo("PlayerArraySize")

    For $i = 1 To $l_i_PlayerArraySize - 1
        Local $l_p_Agent = $l_p_PlayerArray + ($i * $GC_I_STRIDE_WORLD_PLAYER_ARRAY)
        If Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_PLAYERNUMBER, "dword") = $a_i_PlayerNumber Then 
            Switch $a_s_Info
                Case "AgentID"
                    Return Memory_Read($l_p_Agent, "dword")
                Case "AppearanceBitmap"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_APPEARANCE_BITMAP, "dword")
                Case "Flags"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_FLAGS, "dword")
                Case "Primary"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_PRIMARY, "dword")
                Case "Secondary"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_SECONDARY, "dword")
                Case "Name"
                    Local $l_p_Name = Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_NAME, "ptr")
                    Return Memory_Read($l_p_Name, "wchar[20]")
                Case "PartyLeaderPlayerNumber"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_PARTY_LEADER_PLAYERNUMBER, "dword")
                Case "ActiveTitle"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_ACTIVE_TITLE, "dword")
                Case "ActiveChallenge"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_ACTIVE_CHALLENGE, "dword")
                Case "PartySize"
                    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_PLAYER_PARTY_SIZE, "dword")
                Case Else
                    Return 0
            EndSwitch
        EndIf
    Next

    Return 0
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsDead
; Description....: Returns whether an agent is dead.
; Syntax.........: AddOns_GetIsDead ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - True : @error set (1=invalid agent ptr).
; Remarks........: Reads effects dword at +$GC_I_OFFSET_AGENT_EFFECTS and tests bit 0x10.
; Related........: AddOns_GetIsEnchanted, AddOns_GetHasWeaponSpell, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsDead($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, True)
	Return BitAND(Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_EFFECTS, "dword"), 0x10) <> 0
EndFunc   ;==>AddOns_GetIsDead

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsEnchanted
; Description....: Returns whether an agent is enchanted.
; Syntax.........: AddOns_GetIsEnchanted ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr).
; Remarks........: Reads effects dword at +$GC_I_OFFSET_AGENT_EFFECTS and tests bit 0x80.
; Related........: AddOns_GetHasEffect, AddOns_GetHasWeaponSpell, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsEnchanted($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)
	Return BitAND(Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_EFFECTS, "dword"), 0x80) <> 0
EndFunc   ;==>AddOns_GetIsEnchanted

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetHasWeaponSpell
; Description....: Checks whether an agent has a Weapon Spell effect.
; Syntax.........: AddOns_GetHasWeaponSpell ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr).
; Remarks........: Reads effects dword at +$GC_I_OFFSET_AGENT_EFFECTS; tests bit 0x8000.
; Related........: AddOns_GetIsEnchanted, AddOns_GetHasEffect, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetHasWeaponSpell($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)
	Return BitAND(Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_EFFECTS, "dword"), 0x8000) <> 0
EndFunc   ;==>AddOns_GetIsEnchanted

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsAttacking
; Description....: Returns whether an agent is in an attacking model state.
; Syntax.........: AddOns_GetIsAttacking ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr).
; Remarks........: Reads ModelState dword at +$GC_I_OFFSET_AGENT_MODEL_STATE.
; Related........: AddOns_GetIsCasting_, AddOns_GetIsMoving_, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsAttacking($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)
    Local $l_i_ModelState = Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_MODEL_STATE, "dword")
    
    Local $l_b_IsAttacking = ($l_i_ModelState = 0x60 Or $l_i_ModelState = 0x460 _
        Or $l_i_ModelState = 0x40 Or $l_i_ModelState = 0x440)
	Return $l_b_IsAttacking
EndFunc   ;==>AddOns_GetIsAttacking

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsCasting
; Description....: Returns whether an agent is casting, based on the cast state only.
; Syntax.........: AddOns_GetIsCasting ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr, 2=ReadProcessMemory failed).
; Remarks........: Reads a cached struct and tests the "cast" field != 0.
; Related........: AddOns_GetIsCasting_, AddOns_GetIsAttacking, Agent_GetAgentPtr, DllCall
; ===============================================================================================================================
Func AddOns_GetIsCasting($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Agent, _
        "struct*", $g_d_CastStateStruct, _
		"ulong_ptr", $g_i_CastStateStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, False)

    Local $l_i_Cast = DllStructGetData($g_d_CastStateStruct, "cast")

    Local $l_b_IsCasting = ($l_i_Cast <> 0)
    Return $l_b_IsCasting
EndFunc   ;==>AddOns_GetIsCasting

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsCasting_
; Description....: Returns whether an agent is casting, considering both cast and model states.
; Syntax.........: AddOns_GetIsCasting_ ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr, 2=ReadProcessMemory failed).
; Remarks........: True if Cast != 0 OR ModelState is 0x41 or 0x245 Or 0x40 or 0x440.
; Related........: AddOns_GetIsCasting, AddOns_GetIsAttacking, Agent_GetAgentPtr, DllCall
; ===============================================================================================================================
Func AddOns_GetIsCasting_($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Agent, _
        "struct*", $g_d_CastStateStruct, _
		"ulong_ptr", $g_i_CastStateStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, False)

    Local $l_i_ModelState = DllStructGetData($g_d_CastStateStruct, "modelState")
    Local $l_i_Cast = DllStructGetData($g_d_CastStateStruct, "cast")

    Local $l_b_IsCasting = (($l_i_Cast <> 0) _
        And ($l_i_ModelState = 0x41 Or $l_i_ModelState = 0x245 _ ; Non-Attack Skills
        Or $l_i_ModelState = 0x40 Or $l_i_ModelState = 0x440)) ; Attack Skills
    Return $l_b_IsCasting
EndFunc   ;==>AddOns_GetIsCasting_

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetSkillbarCasting
; Description....: Returns whether an agent is casting based on his skillbar state.
; Syntax.........: AddOns_GetSkillbarCasting ( [$a_v_Skillbar = 0] )
; Parameters.....: $a_v_Skillbar - SkillbarPtr or HeroNumber (0 = Player).
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid skillbar ptr).
; Remarks........: True if Casting value for respective skillbar != 0.
; Related........: AddOns_GetSkillbarPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetSkillbarCasting($a_v_Skillbar = 0)
    Local $l_p_Skillbar = $a_v_Skillbar
    If Not IsPtr($a_v_Skillbar) Then $l_p_Skillbar = AddOns_GetSkillbarPtr($a_v_Skillbar)
    If $l_p_Skillbar = 0 Then Return SetError(1, 0, 0)

    Local $l_b_IsCasting = (Memory_Read($l_p_Skillbar + $GC_I_OFFSET_SKILLBAR_CASTING) <> 0)
    Return $l_b_IsCasting
EndFunc   ;==>AddOns_GetSkillbarCasting

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsMoving
; Description....: Returns whether an agent is moving (vector check only).
; Syntax.........: AddOns_GetIsMoving ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr, 2=ReadProcessMemory failed).
; Remarks........: Reads moveX/moveY via a cached MoveState struct.
; Related........: AddOns_GetIsMoving_, AddOns_GetIsAttacking, Agent_GetAgentPtr, DllCall
; ===============================================================================================================================
Func AddOns_GetIsMoving($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Agent, _
        "struct*", $g_d_MoveStateStruct, _
		"ulong_ptr", $g_i_MoveStateStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, False)

    Local $l_f_MoveX = DllStructGetData($g_d_MoveStateStruct, "moveX")
    Local $l_f_MoveY = DllStructGetData($g_d_MoveStateStruct, "moveY")

    Local $l_b_IsMoving = ($l_f_MoveX <> 0 Or $l_f_MoveY <> 0)
    Return $l_b_IsMoving
EndFunc   ;==>AddOns_GetIsMoving

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsMoving_
; Description....: Returns whether an agent is moving (vector or specific model states).
; Syntax.........: AddOns_GetIsMoving_ ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - True/False
;                  Failure - False : @error set (1=invalid agent ptr, 2=ReadProcessMemory failed).
; Remarks........: Superset of AddOns_GetIsMoving; also checks movement-related ModelStates.
; Related........: AddOns_GetIsMoving, AddOns_GetIsAttacking, Agent_GetAgentPtr, DllCall
; ===============================================================================================================================
Func AddOns_GetIsMoving_($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, False)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Agent, _
        "struct*", $g_d_MoveStateStruct, _
		"ulong_ptr", $g_i_MoveStateStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, False)

    Local $l_f_MoveX = DllStructGetData($g_d_MoveStateStruct, "moveX")
    Local $l_f_MoveY = DllStructGetData($g_d_MoveStateStruct, "moveY")
    Local $l_i_ModelState = DllStructGetData($g_d_MoveStateStruct, "modelState")

    Local $l_b_IsMoving = ($l_f_MoveX <> 0 Or $l_f_MoveY <> 0 _
        Or $l_i_ModelState = 0xC Or $l_i_ModelState = 0x4C Or $l_i_ModelState = 0xCC)
    Return $l_b_IsMoving
EndFunc   ;==>AddOns_GetIsMoving_

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetWeaponType
; Description....: Returns an agent’s weapon type code.
; Syntax.........: AddOns_GetWeaponType ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - WeaponType (short)
;                  Failure - 0 with @error set (1=invalid agent ptr).
; Remarks........: Reads short at offset +$GC_I_OFFSET_AGENT_WEAPON_TYPE from the Agent struct. (<8 martial, >=8 caster)
; Related........: AddOns_GetMartialWeapon, AddOns_GetCasterWeapon, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetWeaponType($a_i_AgentID = -2)
    Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, 0)    
	Return Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_WEAPON_TYPE, "short")
EndFunc   ;==>AddOns_GetWeaponType

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetMartialWeapon
; Description....: Checks whether an agent wields a martial weapon.
; Syntax.........: AddOns_GetMartialWeapon ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect (defaults to the player).
; Return values..: Success - True  : WeaponType < 8
;                  Failure - False : WeaponType >= 8 or read failed (@error from AddOns_GetWeaponType).
; Remarks........: Wrapper over AddOns_GetWeaponType; @error bubbles from that helper.
; Related........: AddOns_GetCasterWeapon, AddOns_GetWeaponType, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetMartialWeapon($a_i_AgentID = -2)
	Return AddOns_GetWeaponType($a_i_AgentID) < 8
EndFunc   ;==>GetWieldsMartialWeapon

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetCasterWeapon
; Description....: Checks whether an agent wields a caster weapon.
; Syntax.........: AddOns_GetCasterWeapon ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect (defaults to the player).
; Return values..: Success - True  : WeaponType >= 8
;                  Failure - False : WeaponType < 8 or read failed (@error set by AddOns_GetWeaponType).
; Remarks........: Wrapper over AddOns_GetWeaponType; @error bubbles from that helper.
; Related........: AddOns_GetMartialWeapon, AddOns_GetWeaponType, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetCasterWeapon($a_i_AgentID = -2)
	Return AddOns_GetWeaponType($a_i_AgentID) >= 8
EndFunc   ;==>GetWieldsMartialWeapon

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsQueued
; Description....: Tests whether any of a hero’s skills is queued.
; Syntax.........: AddOns_GetIsQueued ( $a_i_HeroNumber )
; Parameters.....: $a_i_HeroNumber - 1..N hero index (0 invalid).
; Return values..: Success - True  : A skill is queued (API returns 0..7)
;                  Failure - False : No skill queued (API returns 8) or invalid input (@error=1).
; Remarks........: Calls Skill_GetSkillbarInfo(1, "Queued", hero). Returns <> 8 means queued.
; Related........: AddOns_GetQueuedSkill, Skill_GetSkillbarInfo
; ===============================================================================================================================
Func AddOns_GetIsQueued($a_i_HeroNumber)
    If $a_i_HeroNumber = 0 Then Return SetError(1, 0, False)
    Return Skill_GetSkillbarInfo(1, "Queued", $a_i_HeroNumber) <> 8
EndFunc   ;==>AddOns_GetIsQueued

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetQueuedSkill
; Description....: Returns the queued skill slot for a hero (1..8), or 0 if none.
; Syntax.........: AddOns_GetQueuedSkill ( $a_i_HeroNumber )
; Parameters.....: $a_i_HeroNumber - 1..N hero index (0 invalid).
; Return values..: Success - 1..8 : Slot index of the queued skill
;                  Failure - 0    : No skill queued or invalid input (@error=1).
; Remarks........: Maps the result (0..7 or 8 for “none”) to 1..8,0 via (result+1)*(result<>8).
; Related........: AddOns_GetIsQueued, Skill_GetSkillbarInfo
; ===============================================================================================================================
Func AddOns_GetQueuedSkill($a_i_HeroNumber)
    If $a_i_HeroNumber = 0 Then Return SetError(1, 0, 0)
    Local $l_i_Skill = Skill_GetSkillbarInfo(1, "Queued", $a_i_HeroNumber)
    Return ($l_i_Skill + 1) * ($l_i_Skill <> 8)
EndFunc   ;==>AddOns_GetQueuedSkill

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetEnergy
; Description....: Returns an agent’s current energy percentage.
; Syntax.........: AddOns_GetEnergy ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - Energy% (float 0..1)
;                  Failure - 0 with @error set (1=invalid agent ptr).
; Remarks........: Reads float at offset +$GC_I_OFFSET_AGENT_ENERGY_PERCENT from the Agent ptr.
; Related........: AddOns_GetCurrentEnergy, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetEnergy($a_i_AgentID = -2)
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, 0)     
    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_ENERGY_PERCENT, "float")
EndFunc	;==>AddOns_GetEnergy

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetCurrentEnergy
; Description....: Returns an agent’s current energy (absolute, not percent).
; Syntax.........: AddOns_GetCurrentEnergy ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - Current energy (float)
;                  Failure - 0 with @error set (1=invalid agent ptr, 2=ReadProcessMemory failed).
; Remarks........: Reads a cached struct containing energyPercent (float) and energyMax (int),
;                  then returns energyPercent * energyMax.
; Related........: AddOns_GetEnergy, Agent_GetAgentPtr, Memory_Read, DllCall
; ===============================================================================================================================
Func AddOns_GetCurrentEnergy($a_i_AgentID = -2)
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, 0)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Agent, _
        "struct*", $g_d_EnergyStruct, _
		"ulong_ptr", $g_i_EnergyStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, 0)

    Local $l_f_EnergyPercent = DllStructGetData($g_d_EnergyStruct, "energyPercent")
    Local $l_i_EnergyMax = DllStructGetData($g_d_EnergyStruct, "energyMax")
    
    Return $l_f_EnergyPercent * $l_i_EnergyMax
EndFunc	;==>AddOns_GetCurrentEnergy

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetHP
; Description....: Returns an agent’s current HP percentage.
; Syntax.........: AddOns_GetHP ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - HP% (float 0..1)
;                  Failure - 0 with @error set (1=invalid agent ptr).
; Remarks........: Reads float at offset +$GC_I_OFFSET_AGENT_HP_PERCENT from the Agent ptr.
; Related........: AddOns_GetCurrentHP, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetHP($a_i_AgentID = -2)
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, 0)     
    Return Memory_Read($l_p_Agent + $GC_I_OFFSET_AGENT_HP_PERCENT, "float")
EndFunc	;==>AddOns_GetHP

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetCurrentHP
; Description....: Returns an agent’s current HP (absolute, not percent).
; Syntax.........: AddOns_GetCurrentHP ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID - AgentID to inspect.
; Return values..: Success - Current HP (float)
;                  Failure - 0 with @error set (1=invalid agent ptr, 2=ReadProcessMemory failed).
; Remarks........: Reads a cached struct containing hpPercent (float) and hpMax (int),
;                  then returns hpPercent * hpMax.
; Related........: AddOns_GetHP, Agent_GetAgentPtr, Memory_Read, DllCall
; ===============================================================================================================================
Func AddOns_GetCurrentHP($a_i_AgentID = -2)
	Local $l_p_Agent = Agent_GetAgentPtr($a_i_AgentID)
    If $l_p_Agent = 0 Then Return SetError(1, 0, 0)

    Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $l_p_Agent, _
        "struct*", $g_d_HealthStruct, _
		"ulong_ptr", $g_i_HealthStructSize, _
		"ulong_ptr*", 0 _
	)
    If @error Or Not $l_av_Call[0] Then Return SetError(2, 0, 0)

    Local $l_f_HPPercent = DllStructGetData($g_d_HealthStruct, "hpPercent")
    Local $l_i_HPMax = DllStructGetData($g_d_HealthStruct, "hpMax")
    
    Return $l_f_HPPercent * $l_i_HPMax
EndFunc	;==>AddOns_GetCurrentHP

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetHasEffect
; Description....: Tests whether an agent currently has a specific effect (skill ID).
; Syntax.........: AddOns_GetHasEffect ( [$a_i_SkillID = 0] [, $a_i_AgentID = -2] )
; Parameters.....: $a_i_SkillID  - Skill/effect ID to check.
;                  $a_i_AgentID  - AgentID to inspect.
; Return values..: Success - True/False
; Remarks........: Thin wrapper over Agent_GetAgentEffectInfo(..., "HasEffect").
; Related........: AddOns_GetIsEnchanted, AddOns_GetHasWeaponSpell, Agent_GetAgentEffectInfo
; ===============================================================================================================================
Func AddOns_GetHasEffect($a_i_SkillID = 0, $a_i_AgentID = -2)
	Return Agent_GetAgentEffectInfo($a_i_AgentID, $a_i_SkillID, "HasEffect")
EndFunc   ;==>GetIsRecharged

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetAgentArrayEx
; Description....: Builds or filters a list of Agent pointers with specified criteria (type, allegiance, effects, model id,
;                  ownership, death state, range around a point/agent, etc.).
; Syntax.........: AddOns_GetAgentArrayEx ( _
;                  [$a_ap_PtrArray = -1[, _
;                  $a_i_Type = -1[, _
;                  $a_i_Range = -1[, _
;                  $a_i_AgentID = -2[, _
;                  $a_b_UseCoords = False[, _
;                  $a_f_X = 0[, _
;                  $a_f_Y = 0[, _
;                  $a_i_Allegiance = -1[, _
;                  $a_b_ExcludeAllegiance = False[, _
;                  $a_b_ExcludeDead = True[, _
;                  $a_i_PlayerNumber = -1[, _
;                  $a_i_Effect = -1[, _
;                  $a_b_ExcludeEffect = False[, _
;                  $a_b_ExcludeSpirits = True[, 
;                  $a_b_ExcludeMinions = True[, _
;                  $a_b_ExcludeUnowned = True] _
;                  ]]]]]]]]]]]]]]])
; Parameters.....: $a_ap_PtrArray         - Extern agent-pointer array to filter (same shape as return) or -1 to snapshot internally.
;                  $a_i_Type              - Agent type filter (-1=any).
;                  $a_i_Range             - Range gate radius in world units (-1=disabled).
;                  $a_i_AgentID           - Center agent for range test when not using coords (-2=self).
;                  $a_b_UseCoords         - True to center range test on ($a_f_X, $a_f_Y) instead of an agent.
;                  $a_f_X, $a_f_Y         - Explicit center coordinates when $a_b_UseCoords=True.
;                  $a_i_Allegiance        - Specific allegiance to include or exclude (-1=ignore).
;                  $a_b_ExcludeAllegiance - If True, *exclude* matching allegiance; else require it.
;                  $a_b_ExcludeDead       - If True, remove dead agents (effects bit 0x10).
;                  $a_i_PlayerNumber      - Require exact PlayerNumber/ModelID (-1=ignore).
;                  $a_i_Effect            - Effect/bitmask gate (-1=ignore). With $a_b_ExcludeEffect=False require, else exclude.
;                  $a_b_ExcludeEffect     - True to exclude agents having $a_i_Effect; False to require it.
;                  $a_b_ExcludeSpirits    - If True, exclude spirits (by PlayerNumber ranges).
;                  $a_b_ExcludeMinions    - If True, exclude minions (by PlayerNumber ranges).
;                  $a_b_ExcludeUnowned    - If True, skip entries owned by someone else (owner!=0 and owner!=me).
; Return values..: Success - 1D array A where:
;                              A[0]   = count N
;                              A[1..N]= ptrs to Agent structures that passed all filters
;                  Failure -  Array with A[0]=0 and @error set:
;                             @error=1  -> External array invalid/empty (UBound-1 <= 0)
;                             @error=2  -> Agent_GetMaxAgents() returned <= 0
;                             @error=3  -> Failed to snapshot base agent pointer list (ReadProcessMemory)
;                             @error=4  -> Could not resolve center XY (invalid agent / read failed)
; Remarks........: - If $a_ap_PtrArray=-1, the function snapshots the raw agent-pointer table:
;                    uses $g_p_AgentBase (ptr-to-array), Agent_GetMaxAgents(), and ReadProcessMemory into a temporary ptr buffer.
;                  - Fast path: if no filters are set (type, allegiance, effect, range, playerNumber all “off”), it simply
;                    compacts non-null pointers and returns.
;                  - Range test uses squared distance around either the provided coords or the resolved coords of $a_i_AgentID.
;                  - Type 0xDB: applies death, allegiance (include/exclude), PlayerNumber, effect include/exclude,
;                    and optional spirit/minion filters (via AddOns_GetIsSpirit_/AddOns_GetIsMinion_).
;                  - Type 0x400: when $a_b_ExcludeUnowned=True, keeps only entries with owner==0 or owner==me.
;                  - Unknown types are skipped unless explicitly requested via $a_i_Type.
;                  - Requires pre-initialized structures/globals: $g_d_InfoStruct / $g_i_InfoStructSize expecting fields
;                    "type","effects","allegiance","player","owner","posX","posY", plus $g_h_Kernel32, $g_h_GWProcess, $g_p_AgentBase.
; Related........: AddOns_GetXY_, AddOns_GetIsSpirit_, AddOns_GetIsMinion_, Agent_GetMyID, Agent_GetMaxAgents, Memory_Read,
;                  DllCall, DllStructCreate, DllStructGetData
; ===============================================================================================================================
Func AddOns_GetAgentArrayEx( _
        $a_ap_PtrArray          = -1, _
        $a_i_Type               = -1, _
        $a_i_Range              = -1, _
        $a_i_AgentID            = -2, _
        $a_b_UseCoords          = False, _
        $a_f_X                  = 0, _
        $a_f_Y                  = 0, _
        _ ; ===== only for type 0xDB =====
        $a_i_Allegiance         = -1, _
        $a_b_ExcludeAllegiance  = False, _
        $a_b_ExcludeDead        = True, _
        $a_i_PlayerNumber       = -1, _
        $a_i_Effect             = -1, _
        $a_b_ExcludeEffect      = False, _
        $a_b_ExcludeSpirits     = True, _
        $a_b_ExcludeMinions     = True, _
        _ ; ===== only for type 0x400 =====
        $a_b_ExcludeUnowned     = True _
    )

    Local $l_ap_Result[1] = [0]
    Local $l_b_UseArray = IsArray($a_ap_PtrArray)
    Local $l_i_MaxAgents = 0
    Local $l_d_PtrBuffer, $l_p_AgentBase

    ; Source list (build or filter)
    If $l_b_UseArray Then
        $l_i_MaxAgents = UBound($a_ap_PtrArray) - 1
        If $l_i_MaxAgents <= 0 Then Return SetError(1, 0, $l_ap_Result)
        ReDim $l_ap_Result[$l_i_MaxAgents + 1]
    Else
        $l_i_MaxAgents = Agent_GetMaxAgents()
        If $l_i_MaxAgents <= 0 Then Return SetError(2, 0, $l_ap_Result)
        ReDim $l_ap_Result[$l_i_MaxAgents + 1]

        $l_p_AgentBase = Memory_Read($g_p_AgentBase)
        $l_d_PtrBuffer = DllStructCreate("ptr[" & $l_i_MaxAgents & "]")
        Local $l_av_MaxAgentsCall = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_AgentBase, _
            "struct*", $l_d_PtrBuffer, _
            "ulong_ptr", 4 * $l_i_MaxAgents, _
            "ulong_ptr*", 0)
        If @error Or Not $l_av_MaxAgentsCall[0] Then Return SetError(3, 0, $l_ap_Result)
    EndIf

    ; Fast path (no filters)
    If $a_i_Type = -1 And $a_i_Allegiance = -1 And $a_i_Effect = -1 _
    And $a_i_Range < 0 And $a_i_PlayerNumber = -1 Then

        Local $l_i_Count = 0, $l_p_Agent
        If $l_b_UseArray Then
            For $i = 1 To $l_i_MaxAgents
                $l_p_Agent = $a_ap_PtrArray[$i]
                If $l_p_Agent <> 0 Then
                    $l_i_Count += 1
                    $l_ap_Result[$l_i_Count] = $l_p_Agent
                EndIf
            Next
        Else
            For $i = 1 To $l_i_MaxAgents
                $l_p_Agent = DllStructGetData($l_d_PtrBuffer, 1, $i)
                If $l_p_Agent <> 0 Then
                    $l_i_Count += 1
                    $l_ap_Result[$l_i_Count] = $l_p_Agent
                EndIf
            Next
        EndIf

        $l_ap_Result[0] = $l_i_Count
        ReDim $l_ap_Result[$l_i_Count + 1]
        Return $l_ap_Result
    EndIf

    ; Range/center resolve
    Local $l_b_UseRange = ($a_i_Range >= 0)
    Local $l_i_RangeSq = 0
    If $l_b_UseRange Then
        If Not $a_b_UseCoords Then
            Local $l_af_XY = AddOns_GetXY_($a_i_AgentID)
            If @error Then Return SetError(4, 0, $l_ap_Result)

            $a_f_X = $l_af_XY[0]
            $a_f_Y = $l_af_XY[1]
        EndIf
        $l_i_RangeSq = $a_i_Range * $a_i_Range
    EndIf

    ; Main filter loop
    Local $l_i_Count = 0, $l_p_Ptr = 0, $l_i_PlayerID = 0
    If $a_i_Type = 0x400 Then $l_i_PlayerID = Agent_GetMyID()

    For $i = 1 To $l_i_MaxAgents
        If $l_b_UseArray Then
            $l_p_Ptr = $a_ap_PtrArray[$i]
        Else
            $l_p_Ptr = DllStructGetData($l_d_PtrBuffer, 1, $i)
        EndIf
        If $l_p_Ptr = 0 Then ContinueLoop

        Local $l_av_AgentInfoCall = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_Ptr, _
            "struct*", $g_d_InfoStruct, _
            "ulong_ptr", $g_i_InfoStructSize, _
            "ulong_ptr*", 0)
        If @error Or Not $l_av_AgentInfoCall[0] Then ContinueLoop

        ; Type gate
        Local $l_i_Type = DllStructGetData($g_d_InfoStruct, "type")
        If $a_i_Type <> -1 And $l_i_Type <> $a_i_Type Then ContinueLoop

        ; Type-specific filters
        Switch $l_i_Type
            Case 0xDB
                Local $l_i_Effects = DllStructGetData($g_d_InfoStruct, "effects")
                ; Living/dead
                If $a_b_ExcludeDead And BitAND($l_i_Effects, 0x10) Then ContinueLoop

                ; Allegiance (+ exclude/require)
                If $a_i_Allegiance <> -1 Then
                    Local $l_i_Allegiance = DllStructGetData($g_d_InfoStruct, "allegiance")
                    If $a_b_ExcludeAllegiance Then
                        If $l_i_Allegiance = $a_i_Allegiance Then ContinueLoop
                    Else
                        If $l_i_Allegiance <> $a_i_Allegiance Then ContinueLoop
                    EndIf

                    ; Foe sub-filters: spirits/minions
                    If $l_i_Allegiance = 0x3 Then
                        Local $l_i_PlayerNumber = DllStructGetData($g_d_InfoStruct, "player")
                        If $a_b_ExcludeSpirits And AddOns_GetIsSpirit_($l_i_PlayerNumber) Then ContinueLoop
                        If $a_b_ExcludeMinions And AddOns_GetIsMinion_($l_i_PlayerNumber) Then ContinueLoop
                    EndIf
                EndIf

                ; Player number
                If $a_i_PlayerNumber <> -1 Then
                    If DllStructGetData($g_d_InfoStruct, "player") <> $a_i_PlayerNumber Then ContinueLoop
                EndIf

                ; Effect include/exclude
                If $a_i_Effect <> -1 Then
                    If $a_b_ExcludeEffect Then
                        If BitAND($l_i_Effects, $a_i_Effect) Then ContinueLoop
                    Else
                        If Not BitAND($l_i_Effects, $a_i_Effect) Then ContinueLoop
                    EndIf
                EndIf

            Case 0x200
                ; No extra rules

            Case 0x400
                If $a_i_PlayerNumber <> -1 Then
                    Local $l_i_ItemID = DllStructGetData($g_d_InfoStruct, "itemID")
                    $l_p_Item = Item_GetItemPtr($l_i_ItemID)
		            If $l_p_Item = 0 Then ContinueLoop

                    Local $l_i_ModelID = Memory_Read($l_p_Item + $GC_I_OFFSET_ITEM_MODEL_ID, "dword")    
                    If $l_i_ModelID <> $a_i_PlayerNumber Then ContinueLoop
                EndIf

                If $a_b_ExcludeUnowned Then
                    Local $l_i_Owner = DllStructGetData($g_d_InfoStruct, "owner")
                    If $l_i_Owner <> 0 And $l_i_Owner <> $l_i_PlayerID Then ContinueLoop
                EndIf

            Case Else
                ; Unknown type
                If $a_i_Type = -1 Then ContinueLoop
        EndSwitch

        ; Range gate (only if requested)
        If $l_b_UseRange Then
            Local $l_f_DistX = DllStructGetData($g_d_InfoStruct, "posX") - $a_f_X
            Local $l_f_DistY = DllStructGetData($g_d_InfoStruct, "posY") - $a_f_Y
            If ($l_f_DistX * $l_f_DistX + $l_f_DistY * $l_f_DistY) > $l_i_RangeSq Then ContinueLoop
        EndIf

        $l_i_Count += 1
        $l_ap_Result[$l_i_Count] = $l_p_Ptr
    Next

    ; Trim & return
    $l_ap_Result[0] = $l_i_Count
    ReDim $l_ap_Result[$l_i_Count + 1]
    Return $l_ap_Result
EndFunc   ;==>AddOns_GetAgentArrayEx

; ===============================================================================================================================
; Note: Various wrappers for AddOns_GetAgentArrayEx
Func AddOns_GetAgentArray_AnyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc   ;==>AddOns_GetAgentArray_AnyLiving

Func AddOns_GetAgentArray_AnyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
EndFunc   ;==>AddOns_GetAgentArray_AnyDead

Func AddOns_GetAgentArray_AllyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x1)
EndFunc   ;==>AddOns_GetAgentArray_AllyLiving

Func AddOns_GetAgentArray_AllyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
EndFunc   ;==>AddOns_GetAgentArray_AllyDead

Func AddOns_GetAgentArray_EnemyLiving_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3)
EndFunc   ;==>AddOns_GetAgentArray_EnemyLiving_NoSM

Func AddOns_GetAgentArray_EnemyLiving_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, True, -1, -1, False, False, False)
EndFunc   ;==>AddOns_GetAgentArray_EnemyLiving_WithSM

Func AddOns_GetAgentArray_EnemyDead_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10)
EndFunc   ;==>AddOns_GetAgentArray_EnemyDead_NoSM

Func AddOns_GetAgentArray_EnemyDead_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10, False, False, False)
EndFunc   ;==>AddOns_GetAgentArray_EnemyDead_WithSM

Func AddOns_GetAgentArray_SpiritLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x4, False, True, -1, -1, False, False)
EndFunc   ;==>AddOns_GetAgentArray_SpiritLiving

Func AddOns_GetAgentArray_MinionLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x5, False, True, -1, -1, False, True, False)
EndFunc   ;==>AddOns_GetAgentArray_MinionLiving

Func AddOns_GetAgentArray_NPCLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6)
EndFunc   ;==>AddOns_GetAgentArray_NPCLiving

Func AddOns_GetAgentArray_NPCDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB,  $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6, False, False, -1, 0x10)
EndFunc   ;==>AddOns_GetAgentArray_NPCDead

Func AddOns_GetAgentArray_Object($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0x200, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc   ;==>AddOns_GetAgentArray_Object

Func AddOns_GetAgentArray_ItemAny($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0, 0, 0, 0, 0, 0, 0, 0, False)
EndFunc   ;==>AddOns_GetAgentArray_ItemAny

Func AddOns_GetAgentArray_ItemOwned($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetAgentArrayEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc   ;==>AddOns_GetAgentArray_ItemOwned

Func AddOns_GetNumberOfAgent_AnyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_AnyLiving

Func AddOns_GetNumberOfAgent_AnyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_AnyDead

Func AddOns_GetNumberOfAgent_AllyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x1)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_AllyLiving

Func AddOns_GetNumberOfAgent_AllyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_AllyDead

Func AddOns_GetNumberOfAgent_EnemyLiving_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_EnemyLiving_NoSM

Func AddOns_GetNumberOfAgent_EnemyLiving_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, True, -1, -1, False, False, False)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_EnemyLiving_WithSM

Func AddOns_GetNumberOfAgent_EnemyDead_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_EnemyDead_NoSM

Func AddOns_GetNumberOfAgent_EnemyDead_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10, False, False, False)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_EnemyDead_WithSM

Func AddOns_GetNumberOfAgent_SpiritLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x4, False, True, -1, -1, False, False)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_SpiritLiving

Func AddOns_GetNumberOfAgent_MinionLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x5, False, True, -1, -1, False, True, False)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_MinionLiving

Func AddOns_GetNumberOfAgent_NPCLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_NPCLiving

Func AddOns_GetNumberOfAgent_NPCDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0xDB,  $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6, False, False, -1, 0x10)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_NPCDead

Func AddOns_GetNumberOfAgent_Object($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0x200, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_Object

Func AddOns_GetNumberOfAgent_ItemAny($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0, 0, 0, 0, 0, 0, 0, 0, False)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_ItemAny

Func AddOns_GetNumberOfAgent_ItemOwned($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Local $l_ap_AgentArray = AddOns_GetAgentArrayEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
	Return $l_ap_AgentArray[0]
EndFunc   ;==>AddOns_GetNumberOfAgent_ItemOwned
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetNearestAgentEx
; Description....: Returns the nearest agent pointer that matches the supplied filters. Supports optional center (agent or coords),
;                  type/allegiance/effect filters, and specialized rules for creatures and owned objects/items.
; Syntax.........: AddOns_GetNearestAgentEx( _
;                  [$a_ap_PtrArray = -1[, _
;                  $a_i_Type = -1[, _
;                  $a_i_Range = -1[, _
;                  $a_i_AgentID = -2[, _
;                  $a_b_UseCoords = False[, _
;                  $a_f_X = 0[, _
;                  $a_f_Y = 0[, _
;                  $a_i_Allegiance = -1[, _
;                  $a_b_ExcludeAllegiance = False[, _
;                  $a_b_ExcludeDead = True[, _
;                  $a_i_PlayerNumber = -1[, _
;                  $a_i_Effect = -1[, _
;                  $a_b_ExcludeEffect = False[, _
;                  $a_b_ExcludeSpirits = True[, 
;                  $a_b_ExcludeMinions = True[, _
;                  $a_b_ExcludeUnowned = True] _
;                  ]]]]]]]]]]]]]]])
; Parameters.....: $a_ap_PtrArray         - Existing agent pointer array to filter, or -1 to snapshot from memory.
;                  $a_i_Type              - Agent type filter (-1 any).
;                  $a_i_Range             - Search radius in world units (-1 disables range filtering).
;                  $a_i_AgentID           - Center agent for range (use -2 for self). Ignored if $a_b_UseCoords=True.
;                  $a_b_UseCoords         - If True, use ($a_f_X,$a_f_Y) as the range center instead of an agent.
;                  $a_f_X, $a_f_Y         - Center coordinates when $a_b_UseCoords=True.
;                  $a_i_Allegiance        - Allegiance to match (e.g., 0x1=ally, 0x3=enemy, project-specific values allowed). -1 disables.
;                  $a_b_ExcludeAllegiance - If True, excludes agents of $a_i_Allegiance (instead of requiring them).
;                  $a_b_ExcludeDead       - If True, skips dead agents (default True). Death effect bit is 0x10.
;                  $a_i_PlayerNumber      - Match specific PlayerNumber/ModelID (-1 disables).
;                  $a_i_Effect            - Effect bitmask to include/exclude (-1 disables).
;                  $a_b_ExcludeEffect     - If True, excludes agents that have $a_i_Effect; otherwise requires it.
;                  $a_b_ExcludeSpirits    - If True, excludes spirits (default True; project rules via AddOns_GetIsSpirit_()).
;                  $a_b_ExcludeMinions    - If True, excludes minions (default True; project rules via AddOns_GetIsMinion_()).
;                  $a_b_ExcludeUnowned    - If True (default), excludes items owned by others (keeps self/unowned).
; Return values..: Success  - Ptr to the nearest matching agent (non-zero).
;                  Failure  - 0 if no candidates found, center cannot be resolved, or reads fail for all candidates.
; Remarks........: - Uses squared distance via AddOns_ComputePseudoDistance for performance (no Sqrt).
;                  - When centered on an agent, that center agent is skipped from consideration.
;                  - This function does not set @error; it simply returns 0 if no suitable agent is found.
;                  - For repeated queries, pass a cached $a_ap_PtrArray to avoid re-snapshotting memory.
; Related........: AddOns_ComputePseudoDistance, AddOns_GetAgentArrayEx, AddOns_GetXY_, Agent_GetAgentPtr, Memory_Read, DllCall
; ===============================================================================================================================
Func AddOns_GetNearestAgentEx( _
        $a_ap_PtrArray          = -1, _
        $a_i_Type               = -1, _
        $a_i_Range              = -1, _
        $a_i_AgentID            = -2, _
        $a_b_UseCoords          = False, _
        $a_f_X                  = 0, _
        $a_f_Y                  = 0, _
        _ ; ===== only for type 0xDB =====
        $a_i_Allegiance         = -1, _
        $a_b_ExcludeAllegiance  = False, _
        $a_b_ExcludeDead        = True, _
        $a_i_PlayerNumber       = -1, _
        $a_i_Effect             = -1, _
        $a_b_ExcludeEffect      = False, _
        $a_b_ExcludeSpirits     = True, _
        $a_b_ExcludeMinions     = True, _
        _ ; ===== only for type 0x400 =====
        $a_b_ExcludeUnowned     = True _
    )

    Local $l_p_CenterAgent = 0, $l_f_CenterPosX = 0, $l_f_CenterPosY = 0

    If $a_b_UseCoords Then
        $l_f_CenterPosX = $a_f_X
        $l_f_CenterPosY = $a_f_Y
    Else
        $l_p_CenterAgent = Agent_GetAgentPtr($a_i_AgentID)
        If $l_p_CenterAgent = 0 Then Return 0

        Local $l_af_XY = AddOns_GetXY_($l_p_CenterAgent)
        If @error Then Return 0

        $l_f_CenterPosX = $l_af_XY[0]
        $l_f_CenterPosY = $l_af_XY[1]
    EndIf

    Local $l_ap_List = AddOns_GetAgentArrayEx($a_ap_PtrArray, _
            $a_i_Type, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, _
            $a_i_Allegiance, $a_b_ExcludeAllegiance, $a_b_ExcludeDead, _
            $a_i_PlayerNumber, $a_i_Effect, $a_b_ExcludeEffect, _
            $a_b_ExcludeSpirits, $a_b_ExcludeMinions, $a_b_ExcludeUnowned)
    If $l_ap_List[0] = 0 Then Return 0

    Local $l_p_Nearest = 0, $l_f_BestDist = 0x7FFFFFFF
    Local $l_p_Agent, $l_f_X, $l_f_Y, $l_f_Dist

    For $i = 1 To $l_ap_List[0]
        $l_p_Agent = $l_ap_List[$i]
        If $l_p_Agent = 0 Then ContinueLoop
        If $l_p_CenterAgent <> 0 And $l_p_Agent = $l_p_CenterAgent Then ContinueLoop

        Local $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_Agent, _
            "struct*", $g_d_EffectsStruct, _
            "ulong_ptr", $g_i_EffectsStructSize, _
            "ulong_ptr*", 0)
        If @error Or Not $l_av_Call[0] Then ContinueLoop

        $l_f_X = DllStructGetData($g_d_EffectsStruct, "posX")
        $l_f_Y = DllStructGetData($g_d_EffectsStruct, "posY")
        $l_f_Dist = AddOns_ComputePseudoDistance($l_f_X, $l_f_Y, $l_f_CenterPosX, $l_f_CenterPosY)

        If $l_f_Dist < $l_f_BestDist Then
            $l_f_BestDist = $l_f_Dist
            $l_p_Nearest = $l_p_Agent
        EndIf
    Next

    Return $l_p_Nearest
EndFunc

; ===============================================================================================================================
; Note: Various wrappers for AddOns_GetNearestAgentEx
Func AddOns_GetNearestAgent_AnyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc

Func AddOns_GetNearestAgent_AnyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
EndFunc

Func AddOns_GetNearestAgent_AllyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x1)
EndFunc

Func AddOns_GetNearestAgent_AllyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
EndFunc

Func AddOns_GetNearestAgent_EnemyLiving_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3)
EndFunc

Func AddOns_GetNearestAgent_EnemyLiving_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, True, -1, -1, False, False, False)
EndFunc

Func AddOns_GetNearestAgent_EnemyDead_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10)
EndFunc

Func AddOns_GetNearestAgent_EnemyDead_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10, False, False, False)
EndFunc

Func AddOns_GetNearestAgent_SpiritLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x4, False, True, -1, -1, False, False)
EndFunc

Func AddOns_GetNearestAgent_MinionLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x5, False, True, -1, -1, False, True, False)
EndFunc

Func AddOns_GetNearestAgent_NPCLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6)
EndFunc

Func AddOns_GetNearestAgent_NPCDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0xDB,  $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6, False, False, -1, 0x10)
EndFunc

Func AddOns_GetNearestAgent_Object($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0x200, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc

Func AddOns_GetNearestAgent_ItemAny($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0, 0, 0, 0, 0, 0, 0, 0, False)
EndFunc

Func AddOns_GetNearestAgent_ItemOwned($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetNearestAgentEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetInRangeEx
; Description....: Tests whether any agent that matches the given filters exists within the specified range, centered on either
;                  an agent or an arbitrary coordinate pair.
; Syntax.........: AddOns_GetInRangeEx( _
;                  [$a_ap_PtrArray = -1[, _
;                  $a_i_Type = -1[, _
;                  $a_i_Range = -1[, _
;                  $a_i_AgentID = -2[, _
;                  $a_b_UseCoords = False[, _
;                  $a_f_X = 0[, _
;                  $a_f_Y = 0[, _
;                  $a_i_Allegiance = -1[, _
;                  $a_b_ExcludeAllegiance = False[, _
;                  $a_b_ExcludeDead = True[, _
;                  $a_i_PlayerNumber = -1[, _
;                  $a_i_Effect = -1[, _
;                  $a_b_ExcludeEffect = False[, _
;                  $a_b_ExcludeSpirits = True[, 
;                  $a_b_ExcludeMinions = True[, _
;                  $a_b_ExcludeUnowned = True] _
;                  ]]]]]]]]]]]]]]])
; Parameters.....: $a_ap_PtrArray         - Existing agent pointer array to filter, or -1 to snapshot from memory.
;                  $a_i_Type              - Agent type filter (-1 any).
;                  $a_i_Range             - Search radius in world units. Use -1 to match anywhere (no radial gate).
;                  $a_i_AgentID           - Center agent for range (use -2 for self). Ignored when $a_b_UseCoords=True.
;                  $a_b_UseCoords         - If True, uses ($a_f_X,$a_f_Y) as the center instead of an agent.
;                  $a_f_X, $a_f_Y         - Center coordinates when $a_b_UseCoords=True.
;                  $a_i_Allegiance        - Allegiance to require/exclude (-1 disables).
;                  $a_b_ExcludeAllegiance - If True, excludes $a_i_Allegiance; otherwise requires it.
;                  $a_b_ExcludeDead       - If True, excludes dead agents (death bit 0x10). Default True.
;                  $a_i_PlayerNumber      - Match specific PlayerNumber/ModelID (-1 disables).
;                  $a_i_Effect            - Effect bitmask gate (-1 disables).
;                  $a_b_ExcludeEffect     - If True, excludes agents that HAVE $a_i_Effect; otherwise requires it.
;                  $a_b_ExcludeSpirits    - Exclude spirits (via AddOns_GetIsSpirit_()). Default True.
;                  $a_b_ExcludeMinions    - Exclude minions (via AddOns_GetIsMinion_()). Default True.
;                  $a_b_ExcludeUnowned    - If True (default), excludes items owned by others (keeps self/unowned).
; Return values..: Success  - True  (at least one matching agent is within range; if range=-1, True if any match exists).
;                  Failure  - False (no matching agent found under the given filters).
;                  Special  - When **no filters** are applied (type=-1, allegiance/effect/player=-1) **and** range<0, returns an
;                              array of agent pointers instead of a Boolean (fast-path snapshot): [$count, ptr1, ptr2, ...].
; Errors.........: On initialization failures, returns an **empty array** ([$count=0]) and sets:
;                  @error=1  invalid external array (too small) |
;                  @error=2  Agent_GetMaxAgents() <= 0 |
;                  @error=3  failed ReadProcessMemory() for base list |
;                  @error=4  failed to resolve center position (agent/coords).
; Remarks........: - Uses squared distances (no Sqrt) for speed. For $a_i_Type=0x400, $a_b_ExcludeUnowned filters by owner vs self.
;                  - If centered on an agent and range>=0, the function resolves that agent’s XY once and compares against it.
;                  - For repeated queries, pass a cached $a_ap_PtrArray to avoid re-snapshotting memory.
; Related........: AddOns_GetIsMinion_, AddOns_GetIsSpirit_, AddOns_GetXY_, Agent_GetMaxAgents, Agent_GetMyID, DllCall, DllStructCreate, DllStructGetData, Memory_Read
; ===============================================================================================================================
Func AddOns_GetInRangeEx( _
        $a_ap_PtrArray          = -1, _
        $a_i_Type               = -1, _
        $a_i_Range              = -1, _
        $a_i_AgentID            = -2, _
        $a_b_UseCoords          = False, _
        $a_f_X                  = 0, _
        $a_f_Y                  = 0, _
        _ ; ===== only for type 0xDB =====
        $a_i_Allegiance         = -1, _
        $a_b_ExcludeAllegiance  = False, _
        $a_b_ExcludeDead        = True, _
        $a_v_PlayerNumber       = -1, _
        $a_v_Effect             = -1, _
        $a_b_ExcludeEffect      = False, _
        $a_b_ExcludeSpirits     = True, _
        $a_b_ExcludeMinions     = True, _
        _ ; ===== only for type 0x400 =====
        $a_b_ExcludeUnowned     = True _
    )

    Local $l_ap_Result[1] = [0]
    Local $l_b_UseArray = IsArray($a_ap_PtrArray)
    Local $l_i_MaxAgents = 0
    Local $l_d_PtrBuffer, $l_p_AgentBase

    ; Source list (build or filter)
    If $l_b_UseArray Then
        $l_i_MaxAgents = UBound($a_ap_PtrArray) - 1
        If $l_i_MaxAgents <= 0 Then Return SetError(1, 0, $l_ap_Result)
        ReDim $l_ap_Result[$l_i_MaxAgents + 1]
    Else
        $l_i_MaxAgents = Agent_GetMaxAgents()
        If $l_i_MaxAgents <= 0 Then Return SetError(2, 0, $l_ap_Result)
        ReDim $l_ap_Result[$l_i_MaxAgents + 1]

        $l_p_AgentBase = Memory_Read($g_p_AgentBase)
        $l_d_PtrBuffer = DllStructCreate("ptr[" & $l_i_MaxAgents & "]")
        Local $l_av_MaxAgentsCall = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_AgentBase, _
            "struct*", $l_d_PtrBuffer, _
            "ulong_ptr", 4 * $l_i_MaxAgents, _
            "ulong_ptr*", 0)
        If @error Or Not $l_av_MaxAgentsCall[0] Then Return SetError(3, 0, $l_ap_Result)
    EndIf

    ; Fast path (no filters)
    If $a_i_Type = -1 And $a_i_Allegiance = -1 And $a_v_Effect = -1 _
    And $a_i_Range < 0 And $a_v_PlayerNumber = -1 Then

        Local $l_i_Count = 0, $l_p_Agent
        If $l_b_UseArray Then
            For $i = 1 To $l_i_MaxAgents
                $l_p_Agent = $a_ap_PtrArray[$i]
                If $l_p_Agent <> 0 Then
                    $l_i_Count += 1
                    $l_ap_Result[$l_i_Count] = $l_p_Agent
                EndIf
            Next
        Else
            For $i = 1 To $l_i_MaxAgents
                $l_p_Agent = DllStructGetData($l_d_PtrBuffer, 1, $i)
                If $l_p_Agent <> 0 Then
                    $l_i_Count += 1
                    $l_ap_Result[$l_i_Count] = $l_p_Agent
                EndIf
            Next
        EndIf

        $l_ap_Result[0] = $l_i_Count
        ReDim $l_ap_Result[$l_i_Count + 1]
        Return $l_ap_Result
    EndIf

    ; Range/center resolve
    Local $l_b_UseRange = ($a_i_Range >= 0)
    Local $l_i_RangeSq = 0x7FFFFFFF
    If $l_b_UseRange Then
        If Not $a_b_UseCoords Then
            Local $l_af_XY = AddOns_GetXY_($a_i_AgentID)
            If @error Then Return SetError(4, 0, $l_ap_Result)

            $a_f_X = $l_af_XY[0]
            $a_f_Y = $l_af_XY[1]
        EndIf
        $l_i_RangeSq = $a_i_Range * $a_i_Range
    EndIf

    ; Main filter loop
    Local $l_i_Count = 0, $l_p_Ptr = 0, $l_i_PlayerID = 0
    If $a_i_Type = 0x400 Then $l_i_PlayerID = Agent_GetMyID()

    For $i = 1 To $l_i_MaxAgents
        If $l_b_UseArray Then
            $l_p_Ptr = $a_ap_PtrArray[$i]
        Else
            $l_p_Ptr = DllStructGetData($l_d_PtrBuffer, 1, $i)
        EndIf
        If $l_p_Ptr = 0 Then ContinueLoop

        Local $l_av_AgentInfoCall = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_Ptr, _
            "struct*", $g_d_InfoStruct, _
            "ulong_ptr", $g_i_InfoStructSize, _
            "ulong_ptr*", 0)
        If @error Or Not $l_av_AgentInfoCall[0] Then ContinueLoop

        ; Type gate
        Local $l_i_Type = DllStructGetData($g_d_InfoStruct, "type")
        If $a_i_Type <> -1 And $l_i_Type <> $a_i_Type Then ContinueLoop

        ; Type-specific filters
        Switch $l_i_Type
            Case 0xDB
                Local $l_i_Effects = DllStructGetData($g_d_InfoStruct, "effects")
                ; Living/dead
                If $a_b_ExcludeDead And BitAND($l_i_Effects, 0x10) Then ContinueLoop

                ; Allegiance (+ exclude/require)
                If $a_i_Allegiance <> -1 Then
                    Local $l_i_Allegiance = DllStructGetData($g_d_InfoStruct, "allegiance")
                    If $a_b_ExcludeAllegiance Then
                        If $l_i_Allegiance = $a_i_Allegiance Then ContinueLoop
                    Else
                        If $l_i_Allegiance <> $a_i_Allegiance Then ContinueLoop
                    EndIf

                    ; Foe sub-filters: spirits/minions
                    If $l_i_Allegiance = 0x3 Then
                        Local $l_i_PlayerNumber = DllStructGetData($g_d_InfoStruct, "player")
                        If $a_b_ExcludeSpirits And AddOns_GetIsSpirit_($l_i_PlayerNumber) Then ContinueLoop
                        If $a_b_ExcludeMinions And AddOns_GetIsMinion_($l_i_PlayerNumber) Then ContinueLoop
                    EndIf
                EndIf

                ; Player number
                If $a_v_PlayerNumber <> -1 Then
                    Local $l_i_PlayerNumber = DllStructGetData($g_d_InfoStruct, "player")
                    Local $l_b_PlayerNumberMatch = False

                    If IsArray($a_v_PlayerNumber) Then
                        For $playerNumber In $a_v_PlayerNumber
                            If $l_i_PlayerNumber = $playerNumber Then
                                $l_b_PlayerNumberMatch = True
                                ExitLoop
                            EndIf
                        Next
                    Else
                        $l_b_PlayerNumberMatch = ($l_i_PlayerNumber = $a_v_PlayerNumber)
                    EndIf

                    If Not $l_b_PlayerNumberMatch Then ContinueLoop
                EndIf

                ; Effect include/exclude
                If $a_v_Effect <> -1 Then
                    Local $l_b_EffectMatch = False

                    If IsArray($a_v_Effect) Then
                        For $effect In $a_v_Effect
                            If BitAND($l_i_Effects, $effect) <> 0 Then
                                $l_b_EffectMatch = True
                                ExitLoop
                            EndIf
                        Next
                    Else
                        $l_b_EffectMatch = (BitAND($l_i_Effects, $a_v_Effect) <> 0)
                    EndIf

                    If $a_b_ExcludeEffect Then
                        If $l_b_EffectMatch Then ContinueLoop
                    Else
                        If Not $l_b_EffectMatch Then ContinueLoop
                    EndIf
                EndIf

            Case 0x200
                ; No extra rules

            Case 0x400
                If $a_b_ExcludeUnowned Then
                    Local $l_i_Owner = DllStructGetData($g_d_InfoStruct, "owner")
                    If $l_i_Owner <> 0 And $l_i_Owner <> $l_i_PlayerID Then ContinueLoop
                EndIf

            Case Else
                ; Unknown type
                If $a_i_Type = -1 Then ContinueLoop
        EndSwitch

        ; Range check
        Local $l_f_DistX = DllStructGetData($g_d_InfoStruct, "posX") - $a_f_X
        Local $l_f_DistY = DllStructGetData($g_d_InfoStruct, "posY") - $a_f_Y
        If ($l_f_DistX * $l_f_DistX + $l_f_DistY * $l_f_DistY) <= $l_i_RangeSq Then Return True
    Next

    Return False
EndFunc   ;==>AddOns_GetInRangeEx

; ===============================================================================================================================
; Note: Various wrappers for AddOns_GetInRangeEx
Func AddOns_GetInRange_AnyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc

Func AddOns_GetInRange_AnyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
EndFunc

Func AddOns_GetInRange_AllyLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x1)
EndFunc

Func AddOns_GetInRange_AllyDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, -1, False, False, -1, 0x10)
EndFunc

Func AddOns_GetInRange_EnemyLiving_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3)
EndFunc

Func AddOns_GetInRange_EnemyLiving_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, True, -1, -1, False, False, False)
EndFunc

Func AddOns_GetInRange_EnemyDead_NoSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10)
EndFunc

Func AddOns_GetInRange_EnemyDead_WithSM($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x3, False, False, -1, 0x10, False, False, False)
EndFunc

Func AddOns_GetInRange_SpiritLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x4, False, True, -1, -1, False, False)
EndFunc

Func AddOns_GetInRange_MinionLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x5, False, True, -1, -1, False, True, False)
EndFunc

Func AddOns_GetInRange_NPCLiving($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6)
EndFunc

Func AddOns_GetInRange_NPCDead($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0xDB,  $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0x6, False, False, -1, 0x10)
EndFunc

Func AddOns_GetInRange_Object($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0x200, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc

Func AddOns_GetInRange_ItemAny($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y, 0, 0, 0, 0, 0, 0, 0, 0, False)
EndFunc

Func AddOns_GetInRange_ItemOwned($a_i_AgentID = -2, $a_i_Range = -1, $a_b_UseCoords = False, $a_f_X = 0, $a_f_Y = 0, $a_ap_PtrArray = -1)
    Return AddOns_GetInRangeEx($a_ap_PtrArray, 0x400, $a_i_Range, $a_i_AgentID, $a_b_UseCoords, $a_f_X, $a_f_Y)
EndFunc
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsSpirit
; Description....: Checks whether the given agent’s PlayerNumber (model ID) corresponds to a spirit.
; Syntax.........: AddOns_GetIsSpirit ( $a_i_AgentID )
; Parameters.....: $a_i_AgentID  - AgentID to inspect (use -2 for the player, -1 for current target, etc., per Agent_* helpers).
; Return values..: Success - True  : Agent’s PlayerNumber falls within known spirit ranges (Nature/Binding rituals, EVA, spirits).
;                  Failure - False : Not a spirit or lookup failed (invalid agent pointer / unexpected ID).
; Remarks........: Reads PlayerNumber from Agent struct @+0xF4. No @error is set; invalid pointers simply fall through to False.
;                  Ranges include Nature Rituals (2870–2888, 4230–4239, 5711–5719, 5776), Binding Rituals (4209–4231, 5720, 5721,
;                  5723, 5853, 5854), and EVA + spirits (5848–5850).
; Related........: AddOns_GetIsMinion, AddOns_GetIsMinion_, AddOns_GetIsSpirit_, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsSpirit($a_i_AgentID)
	$l_i_PlayerNumber = Memory_Read(Agent_GetAgentPtr($a_i_AgentID) + 0xF4, "short")
	Switch $l_i_PlayerNumber
		Case 2870 To 2888, 4230 To 4239, 5711 To 5719, 5776
			Return True
		Case 4209 To 4231, 5720, 5721, 5723, 5853, 5854
			Return True
		Case 5848 To 5850
			Return True
	EndSwitch
	Return False
EndFunc   ;==>AddOns_GetIsSpirit

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsSpirit_
; Description....: Pure check against a PlayerNumber (model ID) value to determine if it is a spirit.
; Syntax.........: AddOns_GetIsSpirit_ ( $a_i_PlayerNumber )
; Parameters.....: $a_i_PlayerNumber  - PlayerNumber/model ID to test.
; Return values..: Success - True  : ID is in known spirit ranges.
;                  Failure - False : ID not in spirit ranges.
; Remarks........: Use this when you already have the PlayerNumber; avoids memory reads. Mirrors the ranges used by AddOns_GetIsSpirit.
; Related........: AddOns_GetIsMinion, AddOns_GetIsMinion_, AddOns_GetIsSpirit, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsSpirit_($a_i_PlayerNumber)
	Switch $a_i_PlayerNumber
		Case 2870 To 2888, 4230 To 4239, 5711 To 5719, 5776
			Return True
		Case 4209 To 4231, 5720, 5721, 5723, 5853, 5854
			Return True
		Case 5848 To 5850
			Return True
	EndSwitch
	Return False
EndFunc   ;==>AddOns_GetIsSpirit_

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsMinion
; Description....: Checks whether the given agent’s PlayerNumber (model ID) corresponds to a necromancer minion.
; Syntax.........: AddOns_GetIsMinion ( [$a_i_AgentID = -2] )
; Parameters.....: $a_i_AgentID  - AgentID to inspect (defaults to player with -2 per Agent_* helpers).
; Return values..: Success - True  : Agent’s PlayerNumber matches known minion IDs (bone minions, flesh golem, horrors, etc.).
;                  Failure - False : Not a minion or lookup failed (invalid agent pointer / unexpected ID).
; Remarks........: Reads PlayerNumber from Agent struct @+0xF4. No @error is set; invalid pointers simply fall through to False.
;                  Covered IDs: 2226–2228 (Bone Minions), 3962, 3963, 4205, 4206 (Corrupted Scale/Spore, Flesh Golem, Vampiric Horror),
;                  5709, 5710 (Shambling/Jagged Horror).
; Related........: AddOns_GetIsMinion_, AddOns_GetIsSpirit, AddOns_GetIsSpirit_, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsMinion($a_i_AgentID = -2)
	$l_i_PlayerNumber = Memory_Read(Agent_GetAgentPtr($a_i_AgentID) + 0xF4, "short")
	Switch $l_i_PlayerNumber
		Case 2226 To 2228
			Return True
		Case 3962, 3963, 4205, 4206
			Return True
		Case 5709, 5710
			Return True
	EndSwitch
	Return False
EndFunc   ;==>AddOns_GetIsMinion

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetIsMinion_
; Description....: Pure check against a PlayerNumber (model ID) value to determine if it is a necromancer minion.
; Syntax.........: AddOns_GetIsMinion_ ( $a_i_PlayerNumber )
; Parameters.....: $a_i_PlayerNumber  - PlayerNumber/model ID to test.
; Return values..: Success - True  : ID matches known minion IDs.
;                  Failure - False : ID not in minion list.
; Remarks........: Use this when you already have the PlayerNumber; avoids memory reads. Mirrors the IDs used by AddOns_GetIsMinion.
; Related........: AddOns_GetIsMinion, AddOns_GetIsSpirit, AddOns_GetIsSpirit_, Agent_GetAgentPtr, Memory_Read
; ===============================================================================================================================
Func AddOns_GetIsMinion_($a_i_PlayerNumber)
	Switch $a_i_PlayerNumber
		Case 2226 To 2228
			Return True
		Case 3962, 3963, 4205, 4206
			Return True
		Case 5709, 5710
			Return True
	EndSwitch
	Return False
EndFunc   ;==>AddOns_GetIsMinion_
#EndRegion Agents

#Region PointerUpdates
; #GLOBALS – NULL SENTINELS# ====================================================================================================
; Standardized null constants for pointer and array values.
Global Const $GC_P_NULL = Ptr(0)
Global Const $GC_A_NULL[1] = [0]
; ===============================================================================================================================

; #GLOBALS – PLAYER POINTER# ====================================================================================================
; Current player’s agent pointer.
Global $g_p_Player = $GC_P_NULL
; ===============================================================================================================================

; #GLOBALS – PARTY POINTERS# ====================================================================================================
; Party-wide agent pointers and metadata.
Global $g_i_PartySize = 0
Global $g_ap_PartyArray = $GC_A_NULL
Global $g_p_PartyMember_1 = $GC_P_NULL
Global $g_p_PartyMember_2 = $GC_P_NULL
Global $g_p_PartyMember_3 = $GC_P_NULL
Global $g_p_PartyMember_4 = $GC_P_NULL
Global $g_p_PartyMember_5 = $GC_P_NULL
Global $g_p_PartyMember_6 = $GC_P_NULL
Global $g_p_PartyMember_7 = $GC_P_NULL
Global $g_p_PartyMember_8 = $GC_P_NULL
Global $g_p_PartyMember_9 = $GC_P_NULL
Global $g_p_PartyMember_10 = $GC_P_NULL
Global $g_p_PartyMember_11 = $GC_P_NULL
Global $g_p_PartyMember_12 = $GC_P_NULL
; ===============================================================================================================================

; #GLOBALS – HERO POINTERS# =====================================================================================================
; Owned hero pointers and count.
Global $g_i_HeroCnt = 0
Global $g_ap_HeroArray = $GC_A_NULL
Global $g_p_Hero_1 = $GC_P_NULL
Global $g_p_Hero_2 = $GC_P_NULL
Global $g_p_Hero_3 = $GC_P_NULL
Global $g_p_Hero_4 = $GC_P_NULL
Global $g_p_Hero_5 = $GC_P_NULL
Global $g_p_Hero_6 = $GC_P_NULL
Global $g_p_Hero_7 = $GC_P_NULL
; ===============================================================================================================================

; #GLOBALS – SKILLBAR POINTERS# ==================================================================================================
; Player’s and owned heroes’ skillbar structures.
Global $g_p_PlayerSkillbar = $GC_P_NULL
Global $g_p_HeroSkillbar_1 = $GC_P_NULL
Global $g_p_HeroSkillbar_2 = $GC_P_NULL
Global $g_p_HeroSkillbar_3 = $GC_P_NULL
Global $g_p_HeroSkillbar_4 = $GC_P_NULL
Global $g_p_HeroSkillbar_5 = $GC_P_NULL
Global $g_p_HeroSkillbar_6 = $GC_P_NULL
Global $g_p_HeroSkillbar_7 = $GC_P_NULL
; ===============================================================================================================================

; #GLOBALS – FOE POINTERS# ======================================================================================================
; Array for nearby foe pointers used by combat routines.
Global $g_ap_Foes = $GC_A_NULL
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_UpdatePartyPtrs
; Description....: Rebuilds all pointer-based globals for the current session:
;                  - Player pointer ($g_p_Player)
;                  - Party array [$count, ptr...] and mirrors (g_p_PartyMember_1..12)
;                  - Owned hero array [$count, ptr...] and mirrors (g_p_Hero_1..7) + $g_i_HeroCnt
;                  - Skillbar pointers for player/heroes (g_p_PlayerSkillbar + g_p_HeroSkillbar_1..7)
;                  - Resets $g_ap_Foes to an empty sentinel
; Syntax.........: AddOns_UpdatePartyPtrs ( )
; Parameters.....: None
; Return values..: Success - None (globals are updated in-place).
;                  Failure - None (function best-effort; invalid entries are skipped).
; Author.........: KleuTSchi
; Remarks........: - Reads Party / World / Skillbar tables, then resolves agent pointers:
;                    * World_GetWorldInfo("PlayerArray"/"PlayerArraySize"/"SkillbarArray"/"SkillbarArraySize")
;                    * Party_GetMyPartyInfo("Array*PartyMember"/"Array*PartyMemberSize")
;                  - The local player is detected via Agent_GetMyID(); its agent pointer becomes $g_p_Player and its
;                    skillbar pointer is assigned to g_p_Skillbar_1. Owned heroes follow as g_p_Skillbar_2..N.
;                  - Hero pointers are only resolved in explorable instances ($GC_I_MAP_TYPE_EXPLORABLE).
;                  - Numbered globals (PartyMember_1..12, Hero_1..7, Skillbar_1..8) are assigned via Assign() to mirror
;                    the arrays for quick direct access.
;                  - Function fully re-initializes all related globals each call (idempotent refresh).
; Related........: Agent_GetAgentPtr, Agent_GetMyID, World_GetWorldInfo, Party_GetMyPartyInfo, Memory_Read,
;                  Map_GetInstanceInfo
; ===============================================================================================================================
Func AddOns_UpdatePartyPtrs()
    Local $l_i_InstanceType = Map_GetInstanceInfo("Type")

    Local $l_p_WorldPlayerArray = World_GetWorldInfo("PlayerArray")
    Local $l_i_WorldPlayerCnt = World_GetWorldInfo("PlayerArraySize")

    Local $l_p_SkillbarArray = World_GetWorldInfo("SkillbarArray")
    Local $l_i_SkillbarCnt = World_GetWorldInfo("SkillbarArraySize")

    Local $l_i_PartyPlayerCnt = Party_GetMyPartyInfo("ArrayPlayerPartyMemberSize")
    Local $l_i_PartyHeroCnt = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
    Local $l_i_PartyHenchmanCnt = Party_GetMyPartyInfo("ArrayHenchmanPartyMemberSize")

    Local $l_p_PartyPlayerArray = Party_GetMyPartyInfo("ArrayPlayerPartyMember")
    Local $l_p_PartyHeroArray, $l_p_PartyHenchmanArray
    If $l_i_PartyHeroCnt > 0 Then $l_p_PartyHeroArray = Party_GetMyPartyInfo("ArrayHeroPartyMember")
    If $l_i_PartyHenchmanCnt > 0 Then $l_p_PartyHenchmanArray = Party_GetMyPartyInfo("ArrayHenchmanPartyMember")

    ; Reset all existing ptr-related global variables
    $g_ap_Foes = $GC_A_NULL
    $g_ap_PartyArray = $GC_A_NULL
    $g_ap_HeroArray = $GC_A_NULL

    $g_p_Player = $GC_P_NULL
    $g_p_PlayerSkillbar = $GC_P_NULL
    
    For $i = 1 To 12
        Assign("g_p_PartyMember_" & $i, $GC_P_NULL)
    Next
    For $i = 1 To 7
        Assign("g_p_Hero_" & $i, $GC_P_NULL)
    Next
    For $i = 1 To 7
        Assign("g_p_HeroSkillbar_" & $i, $GC_P_NULL)
    Next

    ; Fetch player AgentID for later comparison
    Local $l_i_MyAgentID = Agent_GetMyID()

    ; Update $g_i_PartySize and resize $g_ap_PartyArray, size is final
    $g_i_PartySize = $l_i_PartyPlayerCnt + $l_i_PartyHeroCnt + $l_i_PartyHenchmanCnt
    ReDim $g_ap_PartyArray[$g_i_PartySize + 1]
    $g_ap_PartyArray[0] = $g_i_PartySize

    ; Loop through $l_p_PartyPlayerArray fetching PlayerNumber and AgentID for every player
    Local $l_i_PartyIdx = 0
    For $i = 0 To $l_i_PartyPlayerCnt - 1
        Local $l_p_CurrentPartyPlayerPtr = $l_p_PartyPlayerArray + ($i * $GC_I_STRIDE_PARTY_PLAYER_ARRAY)
        If Not $l_p_CurrentPartyPlayerPtr Then ContinueLoop

        Local $l_i_CurrentPlayerNumber = Memory_Read($l_p_CurrentPartyPlayerPtr, "long")
        If $l_i_CurrentPlayerNumber = 0 Then ContinueLoop

        Local $l_i_CurrentPlayerAgentID = 0
        For $j = 1 To $l_i_WorldPlayerCnt - 1
            Local $l_p_WorldPlayerPtr = $l_p_WorldPlayerArray + ($j * $GC_I_STRIDE_WORLD_PLAYER_ARRAY)
            If Not $l_p_WorldPlayerPtr Then ContinueLoop

            Local $l_i_WorldPlayerNumber = Memory_Read($l_p_WorldPlayerPtr + $GC_I_OFFSET_PLAYER_PLAYERNUMBER, "long")
            If $l_i_WorldPlayerNumber = $l_i_CurrentPlayerNumber Then
                $l_i_CurrentPlayerAgentID = Memory_Read($l_p_WorldPlayerPtr, "long")
                ExitLoop
            EndIf
        Next
        If $l_i_CurrentPlayerAgentID = 0 Then ContinueLoop

        Local $l_p_CurrentAgentPtr = Agent_GetAgentPtr($l_i_CurrentPlayerAgentID)
        If $l_p_CurrentAgentPtr = 0 Then ContinueLoop

        ; Assign PlayerPtr to global variable
        $l_i_PartyIdx += 1
        $g_ap_PartyArray[$l_i_PartyIdx] = $l_p_CurrentAgentPtr
        Assign("g_p_PartyMember_" & $l_i_PartyIdx, $l_p_CurrentAgentPtr)

        ; Path A: Current player is NOT "me"
        If $l_i_CurrentPlayerAgentID <> $l_i_MyAgentID Then
            ; Loop through $l_p_PartyHeroArray when present, fetching OwnerPlayerNumber and AgentID for every hero
            If $l_i_PartyHeroCnt > 0 Then               
                For $l_i_Height = 0 To $l_i_PartyHeroCnt - 1
                    Local $l_p_CurrentHeroPtr = $l_p_PartyHeroArray + ($l_i_Height * $GC_I_STRIDE_PARTY_HERO_ARRAY)
                    If Not $l_p_CurrentHeroPtr Then ContinueLoop

                    DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                        "handle", $g_h_GWProcess, _
                        "ptr", $l_p_CurrentHeroPtr, _
                        "struct*", $g_d_HeroOwnerStruct, _
                        "ulong_ptr", $g_i_HeroOwnerStructSize, _
                        "ulong_ptr*", 0 _
                    )
                    Local $l_i_HeroOwnerPlayerNumber = DllStructGetData($g_d_HeroOwnerStruct, "owner")
                    Local $l_i_HeroAgentID = DllStructGetData($g_d_HeroOwnerStruct, "agentID")

                    If $l_i_HeroOwnerPlayerNumber <> $l_i_CurrentPlayerNumber Or $l_i_HeroAgentID = 0 Then ContinueLoop

                    ; Assign HeroPtr only in explorable area
                    $l_i_PartyIdx += 1
                    If $l_i_InstanceType = $GC_I_MAP_TYPE_EXPLORABLE Then
                        Local $l_p_HeroAgentPtr = Agent_GetAgentPtr($l_i_HeroAgentID)
                        If $l_p_HeroAgentPtr Then
                            $g_ap_PartyArray[$l_i_PartyIdx] = $l_p_HeroAgentPtr
                            Assign("g_p_PartyMember_" & $l_i_PartyIdx, $l_p_HeroAgentPtr)
                        EndIf
                    EndIf
                Next
            EndIf
        ; Path B: Current player is "me"
        Else
            $g_p_Player = $l_p_CurrentAgentPtr

            ; Loop through $l_p_SkillbarArray to find player's SkillbarPtr
            For $k = 0 To $l_i_SkillbarCnt - 1
                Local $l_p_PlayerSkillbarPtr = $l_p_SkillbarArray + ($k * $GC_I_STRIDE_SKILLBAR_ARRAY)
                If Not $l_p_PlayerSkillbarPtr Then ContinueLoop
                
                ; Assign player SkillbarPtr once found
                Local $l_i_PlayerSkillbarAgentID = Memory_Read($l_p_PlayerSkillbarPtr, "dword")
                If $l_i_PlayerSkillbarAgentID = $l_i_MyAgentID Then
                    $g_p_PlayerSkillbar = $l_p_PlayerSkillbarPtr
                    ExitLoop
                EndIf
            Next

            Local $l_i_HeroIdx = 0
            ; Loop through $l_p_PartyHeroArray when present, fetching OwnerPlayerNumber and AgentID for every hero
            If $l_i_PartyHeroCnt > 0 Then
                ; Resize $g_ap_HeroArray to its temporary limit
                ReDim $g_ap_HeroArray[$l_i_PartyHeroCnt + 1]
                For $l_i_Height = 0 To $l_i_PartyHeroCnt - 1
                    Local $l_p_CurrentHeroPtr = $l_p_PartyHeroArray + ($l_i_Height * $GC_I_STRIDE_PARTY_HERO_ARRAY)
                    If Not $l_p_CurrentHeroPtr Then ContinueLoop

                    DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                        "handle", $g_h_GWProcess, _
                        "ptr", $l_p_CurrentHeroPtr, _
                        "struct*", $g_d_HeroOwnerStruct, _
                        "ulong_ptr", $g_i_HeroOwnerStructSize, _
                        "ulong_ptr*", 0 _
                    )
                    Local $l_i_HeroOwnerPlayerNumber = DllStructGetData($g_d_HeroOwnerStruct, "owner")
                    Local $l_i_HeroAgentID = DllStructGetData($g_d_HeroOwnerStruct, "agentID")
                    
                    If $l_i_HeroOwnerPlayerNumber <> $l_i_CurrentPlayerNumber Or $l_i_HeroAgentID = 0 Then ContinueLoop

                    ; Assign HeroPtr only in explorable area
                    $l_i_PartyIdx += 1
                    $l_i_HeroIdx += 1

                    If $l_i_InstanceType = $GC_I_MAP_TYPE_EXPLORABLE Then
                        Local $l_p_HeroAgentPtr = Agent_GetAgentPtr($l_i_HeroAgentID)
                        If $l_p_HeroAgentPtr Then
                            $g_ap_PartyArray[$l_i_PartyIdx] = $l_p_HeroAgentPtr
                            $g_ap_HeroArray[$l_i_HeroIdx] = $l_p_HeroAgentPtr
                            Assign("g_p_PartyMember_" & $l_i_PartyIdx, $l_p_HeroAgentPtr)
                            Assign("g_p_Hero_" & $l_i_HeroIdx, $l_p_HeroAgentPtr)
                        EndIf
                    EndIf

                    ; Loop through $l_p_SkillbarArray to find hero's SkillbarPtr
                    For $m = 0 To $l_i_SkillbarCnt - 1
                        Local $l_p_HeroSkillbarPtr = $l_p_SkillbarArray + ($m * $GC_I_STRIDE_SKILLBAR_ARRAY)
                        If Not $l_p_HeroSkillbarPtr Then ContinueLoop
                        
                        ; Assign hero SkillbarPtr once found
                        Local $l_i_HeroSkillbarAgentID = Memory_Read($l_p_HeroSkillbarPtr, "dword")
                        If $l_i_HeroSkillbarAgentID = $l_i_HeroAgentID Then
                            Assign("g_p_HeroSkillbar_" & $l_i_HeroIdx, $l_p_HeroSkillbarPtr)
                            ExitLoop
                        EndIf
                    Next
                Next
                ; Update $g_i_HeroCnt and resize $g_ap_HeroArray to its final size
                $g_i_HeroCnt = $l_i_HeroIdx
                ReDim $g_ap_HeroArray[$g_i_HeroCnt + 1]
                $g_ap_HeroArray[0] = $g_i_HeroCnt
            EndIf
        EndIf
    Next

    ; Loop through $l_p_PartyHenchmanArray when present, fetching AgentID for every henchman
    If $l_i_PartyHenchmanCnt > 0 Then
        For $n = 0 To $l_i_PartyHenchmanCnt - 1
            Local $l_p_CurrentPartyHenchmanPtr = $l_p_PartyHenchmanArray + ($n * $GC_I_STRIDE_PARTY_HENCHMAN_ARRAY)
            If Not $l_p_CurrentPartyHenchmanPtr Then ContinueLoop

            Local $l_i_HenchmanAgentID = Memory_Read($l_p_CurrentPartyHenchmanPtr, "long")
            If $l_i_HenchmanAgentID = 0 Then ContinueLoop

            ; Assign HenchmanPtr
            $l_i_PartyIdx += 1
            Local $l_p_HenchmanAgentPtr = Agent_GetAgentPtr($l_i_HenchmanAgentID)
            If $l_p_HenchmanAgentPtr Then
                $g_ap_PartyArray[$l_i_PartyIdx] = $l_p_HenchmanAgentPtr
                Assign("g_p_PartyMember_" & $l_i_PartyIdx, $l_p_HenchmanAgentPtr)
            EndIf
        Next
    EndIf
EndFunc   ;==>AddOns_UpdatePartyPtrs

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetSkillbarPtr
; Description....: Returns the Skillbar pointer for the given HeroNumber; exposes the matched AgentID via @extended if found.
; Syntax.........: AddOns_GetSkillbarPtr ( [$a_i_HeroNumber = 0] )
; Parameters.....: $a_i_HeroNumber - Int : 0 = player; 1..n = hero index in your party.
; Return values..: Success - Ptr to the skillbar.
;                  Failure - 0 and @error set (1=invalid skillbar ptr, 2=hero not found).
; Remarks........: Uses each skillbar’s AgentID to check for a respective hero number. Pass 0 to get the player’s own skillbar.
; Related........: AddOns_GetHeroNumber, AddOns_GetSkillbarPtrArray, Memory_Read, World_GetWorldInfo
; ===============================================================================================================================
Func AddOns_GetSkillbarPtr($a_i_HeroNumber = 0)
    Local $l_p_SkillbarArray = World_GetWorldInfo("SkillbarArray")
    Local $l_i_SkillbarArraySize = World_GetWorldInfo("SkillbarArraySize")

    If Not $l_p_SkillbarArray Then Return SetError(1, 0, 0)

    For $i = 0 To $l_i_SkillbarArraySize - 1
        Local $l_p_SkillbarPtr = $l_p_SkillbarArray + ($i * $GC_I_STRIDE_SKILLBAR_ARRAY)
        If Not $l_p_SkillbarPtr Then ContinueLoop

        Local $l_i_AgentID = Memory_Read($l_p_SkillbarPtr, "long")
        Local $l_i_HeroNumber = AddOns_GetHeroNumber($l_i_AgentID)
        If $l_i_HeroNumber = $a_i_HeroNumber Then Return SetExtended($l_i_AgentID, $l_p_SkillbarPtr)
    Next

    Return SetError(2, 0, 0)
EndFunc   ;==>AddOns_GetSkillbarPtr

; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GetSkillbarPtrArray
; Description....: Returns an Nx2 array of [AgentID, SkillbarPtr] for all entries in the skillbar array (debug helper).
; Syntax.........: AddOns_GetSkillbarPtrArray ( )
; Parameters.....: None
; Return values..: Success - Nx2 array: [i][0] = AgentID, [i][1] = SkillbarPtr.
;                  Failure - Zero-length array if the skillbar array is unavailable.
; Remarks........: Array is sized using World_GetWorldInfo("SkillbarArraySize"); entries may be 0 if not populated.
; Related........: AddOns_GetSkillbarPtr, Memory_Read, World_GetWorldInfo
; ===============================================================================================================================
Func AddOns_GetSkillbarPtrArray()
    Local $l_p_SkillbarArray = World_GetWorldInfo("SkillbarArray")
    Local $l_i_SkillbarArraySize = World_GetWorldInfo("SkillbarArraySize")
    Local $l_ap_SkillbarPtrs[$l_i_SkillbarArraySize][2]

    If Not $l_p_SkillbarArray Then Return $l_ap_SkillbarPtrs

    For $i = 0 To $l_i_SkillbarArraySize - 1
        Local $l_p_SkillbarPtr = $l_p_SkillbarArray + ($i * $GC_I_STRIDE_SKILLBAR_ARRAY)
        If Not $l_p_SkillbarPtr Then ContinueLoop

        Local $l_i_AgentID = Memory_Read($l_p_SkillbarPtr, "long")

        $l_ap_SkillbarPtrs[$i][0] = $l_i_AgentID
        $l_ap_SkillbarPtrs[$i][1] = $l_p_SkillbarPtr
    Next

    Return $l_ap_SkillbarPtrs
EndFunc   ;==>AddOns_GetSkillbarPtrArray
#EndRegion PointerUpdates

#Region GWProcess
; #FUNCTION# ====================================================================================================================
; Name...........: AddOns_GWRunning
; Description....: Lightweight liveness check for the Guild Wars client. Verifies the GW process is
;                  present and that the client reports no error.
; Syntax.........: AddOns_GWRunning ( )
; Parameters.....: None
; Return values..: Success - True  : Process exists AND Core_GetStatusError() == 0.
;                  Failure - False : Process not found OR Core_GetStatusError() != 0.
; Remarks........: Intended for frequent heartbeat polling. Does not throw or set @error.
; Related........: AddOns_Out, Core_GetStatusError, ProcessExists
; ===============================================================================================================================
Func AddOns_GWRunning()
	If Not ProcessExists($g_i_GWProcessId) Then Return False
	If Core_GetStatusError() Then Return False
	Return True
EndFunc
#EndRegion GWProcess