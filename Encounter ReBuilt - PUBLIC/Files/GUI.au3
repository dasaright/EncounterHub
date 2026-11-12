#include-once

; #INCLUDES# ====================================================================================================================
; Note: All native AutoIt includes are covered by GwAu3/API/_GwAu3.au3 which should always be included in the main script.
;       The same applies to GwAu3 API-specific includes. Other includes containing script-specific files are covered
;       by _EncounterRebuilt.au3.
;
; #include <Array.au3>
; #include <Crypt.au3>
; #include <EditConstants.au3>
; #include <FontConstants.au3>
; #include <GUIConstantsEx.au3>
; #include <GuiHeader.au3>
; #include <GuiListView.au3>
; #include <GuiRichEdit.au3>
; #include <ListViewConstants.au3>
; #include <MsgBoxConstants.au3>
; #include <StaticConstants.au3>
; #include <TabConstants.au3>
; #include <WindowsConstants.au3>
;
; #include "AddOns.au3"
; #include "Launch.au3"
; #include "Security.au3"
;
; #include "../../../API/_GwAu3.au3"
; ===============================================================================================================================

#Region GUICreate
; #GLOBALS - METADATA# ==========================================================================================================
; App metadata / paths
Global Const $GC_S_CHARACTERS_INI_PATH = @ScriptDir & "\Config\characters.ini" ; Persistent character list
Global Const $GC_S_SETTINGS_INI_PATH = @ScriptDir & "\Config\settings.ini" ; Persistent settings list
Global Const $GC_S_DATA_SEPARATOR = "~"
; ===============================================================================================================================

; #GLOBALS - MAIN GUI CONTROLS# =================================================================================================
Global $g_h_MainGUI
Global $g_i_CtrlID_Tab, $g_h_CtrlHnd_Tab
; General tab
Global $g_i_CtrlID_Combo_CharInput, $g_i_CtrlID_Combo_LocationInput
Global $g_i_CtrlID_CBX_Rendering, $g_i_CtrlID_CBX_OnTop, $g_i_CtrlID_CBX_NormalMode, $g_i_CtrlID_CBX_HardMode
Global $g_i_CtrlID_Label_Console, $g_h_CtrlHnd_Label_Console, $g_h_CtrlHnd_Edit_Console, $g_i_CtrlID_Edit_Console, $g_b_EditConsoleDirty
Global $g_i_CtrlID_Button_Start, $g_i_CtrlID_Button_OpenLockboxes, $g_i_CtrlID_Button_Trade
; Loot Config tab
Global $g_i_CtrlID_CBX_UseBag1, $g_i_CtrlID_CBX_UseBag2, $g_i_CtrlID_CBX_UseBag3, $g_i_CtrlID_CBX_UseBag4
Global $g_i_CtrlID_CBX_ExchangeGuard, $g_i_CtrlID_CBX_ExchangeSeal, $g_i_CtrlID_CBX_ExchangeLockbox
Global $g_i_CtrlID_CBX_ExchangeEcto, $g_i_CtrlID_CBX_ExchangeObby, $g_i_CtrlID_CBX_ExchangeLP
Global $g_i_CtrlID_CBX_LootTome, $g_i_CtrlID_CBX_LootLP, $g_i_CtrlID_CBX_LootBD
Global $g_i_CtrlID_CBX_LootPCon, $g_i_CtrlID_CBX_LootEventToken, $g_i_CtrlID_CBX_LootTPItem
; Trade Config tab
Global $g_i_CtrlID_CBX_TradeGuard, $g_i_CtrlID_CBX_TradeSeal, $g_i_CtrlID_CBX_TradeTengu, $g_i_CtrlID_CBX_TradeMC
Global $g_i_CtrlID_CBX_TradeEcto, $g_i_CtrlID_CBX_TradeObby
Global $g_i_CtrlID_CBX_TradeLP, $g_i_CtrlID_CBX_TradeBD
Global $g_i_CtrlID_CBX_TradeTome, $g_i_CtrlID_CBX_TradePCon
Global $g_i_CtrlID_CBX_TradeEventToken
Global $g_i_CtrlID_CBX_TradeIcedTea, $g_i_CtrlID_CBX_TradeDCake, $g_i_CtrlID_CBX_TradeBeacon, $g_i_CtrlID_CBX_TradeTPItem
; Statistics tab
Global $g_i_CtrlID_Label_AvgRuntime, $g_i_CtrlID_Label_FastestRuntime, $g_i_CtrlID_Label_AvgFoeCount
Global $g_i_CtrlID_Label_SuccessCount, $g_i_CtrlID_Label_SuccessCountPercentage
Global $g_i_CtrlID_Label_FailureCount, $g_i_CtrlID_Label_FailureCountPercentage
Global $g_i_CtrlID_Label_MikuFailureCount, $g_i_CtrlID_Label_MikuFailureCountPercentage
Global $g_i_CtrlID_Label_TotalCount
Global $g_i_CtrlID_Label_MCCount, $g_i_CtrlID_Label_MCCPR
Global $g_i_CtrlID_Label_GICount, $g_i_CtrlID_Label_GICPR
Global $g_i_CtrlID_Label_StoredGICount, $g_i_CtrlID_Label_StoredGICPR
Global $g_i_CtrlID_Label_LPCount, $g_i_CtrlID_Label_LPCPR
Global $g_i_CtrlID_Label_BDCount, $g_i_CtrlID_Label_BDCPR
Global $g_i_CtrlID_Label_Credits
; Characters tab
Global $g_i_CtrlID_AccountList, $g_h_CtrlHnd_AccountList
Global $g_i_CtrlID_Button_Add, $g_i_CtrlID_Button_Edit, $g_i_CtrlID_Button_Remove
; Cleanup
Global $g_b_CleanupDone = False
; ===============================================================================================================================

; #GLOBALS - STATISTICS / RUNTIME# ==============================================================================================
; Performance & runtime aggregates
Global $g_i_Count_Runs = 0, $g_i_Count_Fails = 0
Global $g_h_Runtime
Global $g_i_AvgRuntimeSeconds = 0, $g_i_AvgRuntimeMinutes = 0, $g_i_AvgRuntimeMinutesMod = 0
Global $g_f_FastestRuntimeSeconds = 0x7FFFFFFF, $g_i_FastestRuntimeMinutes = 0, $g_i_FastestRuntimeMinutesMod = 0
; Outcome / loot counters
Global $g_i_Count_MikuFails = 0, $g_i_Count_SpikedFoes = 0, $g_i_Count_AvgSpikedFoes = 0
Global $g_i_Count_MinisterialCommendation = 0, $g_i_Count_MinisterialCommendationLooted = 0
Global $g_i_Count_GoldItem = 0, $g_i_Count_StoredGoldItem = 0, $g_i_Count_Lockpick = 0, $g_i_Count_BlackDye = 0
; ===============================================================================================================================

; #GLOBALS - CHARACTER DIALOG# ==================================================================================================
Global $g_h_CharacterGUI
Global $g_i_CtrlID_CharsInput, $g_s_OldCharacter = ""
Global $g_i_CtrlID_EmailInput
Global $g_i_CtrlID_PwdInput, $g_i_CtrlID_ShowPwdButton, $g_b_PwdMasked
Global $g_i_CtrlID_FilePathInput, $g_i_CtrlID_BrowseButton
Global $g_i_CtrlID_OKButton, $g_i_CtrlID_CancelButton, $g_i_CtrlID_CancelAllButton
Global $g_ai_EditQueue[0], $g_i_QueuePos = 0
; Character dialog window types
Global Const $GC_I_CHARACTER_GUI_TYPE_ADD = 0
Global Const $GC_I_CHARACTER_GUI_TYPE_EDIT = 1
Global Const $GC_I_CHARACTER_GUI_TYPE_MULTI_EDIT = 2
; ===============================================================================================================================

; #GLOBALS - COMBO / LV SORTING# ================================================================================================
Global $g_i_AccSorting, $g_i_CharSorting
; ===============================================================================================================================

Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("GUIDataSeparatorChar", $GC_S_DATA_SEPARATOR)

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_FormatPercent
; Description....: Formats a percentage like "12.34%" or returns "N/A" when the denominator is zero.
; Syntax.........: GUI_FormatPercent ( $a_i_Part, $a_i_Whole [, $a_i_Decimals = 2 ] )
; Parameters.....: $a_i_Part      - The numerator (part of the whole).
;                  $a_i_Whole     - The denominator (whole). If 0, "N/A" is returned.
;                  $a_i_Decimals  - Optional. Number of decimal places to round to. Default is 2.
; Return values..: Success        - String with percentage and trailing "%".
;                  Edge case      - "N/A" when $a_i_Whole = 0.
; Author.........: KleuTSchi
; Remarks........: Pure formatting helper; does not set @error/@extended.
; Related........: Round
; ===============================================================================================================================
Func GUI_FormatPercent($a_i_Part, $a_i_Whole, $a_i_Decimals = 2)
    If $a_i_Whole = 0 Then Return "N/A"
    Return Round(($a_i_Part / $a_i_Whole) * 100, $a_i_Decimals) & "%"
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_PerRunAvg
; Description....: Computes a per-run average (count / runs) or returns "N/A" when runs is zero.
; Syntax.........: GUI_PerRunAvg ( $a_i_Count, $a_i_Runs [, $a_i_Decimals = 3 ] )
; Parameters.....: $a_i_Count     - Total count across all runs.
;                  $a_i_Runs      - Number of runs. If 0, "N/A" is returned.
;                  $a_i_Decimals  - Optional. Number of decimal places to round to. Default is 3.
; Return values..: Success        - Stringified average rounded to $a_i_Decimals.
;                  Edge case      - "N/A" when $a_i_Runs = 0.
; Author.........: KleuTSchi
; Remarks........: Returns a string for consistency with label updates; adjust as needed if numeric type is preferred.
; Related........: Round
; ===============================================================================================================================
Func GUI_PerRunAvg($a_i_Count, $a_i_Runs, $a_i_Decimals = 3)
    If $a_i_Runs = 0 Then Return "N/A"
    Return Round(($a_i_Count / $a_i_Runs), $a_i_Decimals)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_SetIcon
; Description....: Safely sets a window’s icon if the icon file exists.
; Syntax.........: GUI_SetIcon ( $a_h_Wnd, $a_s_Path [, $a_i_Index = -1 ] )
; Parameters.....: $a_h_Wnd       - Handle to the GUI window.
;                  $a_s_Path      - Filesystem path to the .ico file.
;                  $a_i_Index     - Optional. Icon index within the .ico; default -1.
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: If the path does not exist, the function silently does nothing (no @error set).
; Related........: GUISetIcon, FileExists
; ===============================================================================================================================
Func GUI_SetIcon($a_h_Wnd, $a_s_Path, $a_i_Index = -1)
    If FileExists($a_s_Path) Then GUISetIcon($a_s_Path, $a_i_Index, $a_h_Wnd)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreatePic
; Description....: Creates a picture control if the image file exists; otherwise returns -1.
; Syntax.........: GUI_CreatePic ( $a_s_Path, $a_i_X, $a_i_Y, $a_i_Width, $a_i_Height )
; Parameters.....: $a_s_Path      - Filesystem path to the image (bmp/jpg/png/etc.).
;                  $a_i_X, $a_i_Y - Control position (pixels).
;                  $a_i_Width     - Control width (pixels).
;                  $a_i_Height    - Control height (pixels).
; Return values..: Success        - Control ID (int) of the created Pic control.
;                  Failure        - -1 if file does not exist.
; Author.........: KleuTSchi
; Remarks........: No @error is set on failure; sentinel -1 allows simple guard checks.
; Related........: GUICtrlCreatePic, FileExists
; ===============================================================================================================================
Func GUI_CreatePic($a_s_Path, $a_i_X, $a_i_Y, $a_i_Width, $a_i_Height)
    If FileExists($a_s_Path) Then
        Return GUICtrlCreatePic($a_s_Path, $a_i_X, $a_i_Y, $a_i_Width, $a_i_Height)
    EndIf
    Return -1
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreateCheckbox
; Description....: Creates a checkbox control with optional initial state and event binding; autosizes when width/height <= 0.
; Syntax.........: GUI_CreateCheckbox ( $a_s_Text, $a_i_X, $a_i_Y [, $a_i_Width = -1 [, $a_i_Height = -1 [, $a_b_Checked = False [, $a_s_OnEventFunc = "" ] ] ] ] )
; Parameters.....: $a_s_Text      - Checkbox caption.
;                  $a_i_X, $a_i_Y - Control position (pixels).
;                  $a_i_Width     - Optional. Width; <= 0 becomes -1 (AutoIt autosize). Default -1.
;                  $a_i_Height    - Optional. Height; <= 0 becomes -1 (AutoIt autosize). Default -1.
;                  $a_b_Checked   - Optional. True to start checked. Default False.
;                  $a_s_OnEventFunc
;                                 - Optional. Name of OnEvent function to bind (GUIOnEventMode must be True).
; Return values..: Success        - Control ID (int) of the created checkbox.
; Author.........: KleuTSchi
; Remarks........: This function does not validate $a_s_OnEventFunc; pass "" to skip wiring.
; Related........: GUICtrlCreateCheckbox, GUICtrlSetOnEvent, GUICtrlSetState
; ===============================================================================================================================
Func GUI_CreateCheckbox($a_s_Text, $a_i_X, $a_i_Y, $a_i_Width = -1, $a_i_Height = -1, $a_b_Checked = False, $a_s_OnEventFunc = "")
    If $a_i_Width <= 0 Then $a_i_Width  = -1
    If $a_i_Height <= 0 Then $a_i_Height = -1
    Local $l_i_ControlID = GUICtrlCreateCheckbox($a_s_Text, $a_i_X, $a_i_Y, $a_i_Width, $a_i_Height)
    If $a_b_Checked Then GUICtrlSetState($l_i_ControlID, $GUI_CHECKED)
    If $a_s_OnEventFunc <> "" Then GUICtrlSetOnEvent($l_i_ControlID, $a_s_OnEventFunc)
    Return $l_i_ControlID
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreateRadio
; Description....: Creates a radio button control with optional initial state and event binding; autosizes when width/height <= 0.
; Syntax.........: GUI_CreateRadio ( $a_s_Text, $a_i_X, $a_i_Y [, $a_i_Width = -1 [, $a_i_Height = -1 [, $a_b_Checked = False [, $a_s_OnEventFunc = "" ] ] ] ] )
; Parameters.....: $a_s_Text      - Checkbox caption.
;                  $a_i_X, $a_i_Y - Control position (pixels).
;                  $a_i_Width     - Optional. Width; <= 0 becomes -1 (AutoIt autosize). Default -1.
;                  $a_i_Height    - Optional. Height; <= 0 becomes -1 (AutoIt autosize). Default -1.
;                  $a_b_Checked   - Optional. True to start checked. Default False.
;                  $a_s_OnEventFunc
;                                 - Optional. Name of OnEvent function to bind (GUIOnEventMode must be True).
; Return values..: Success        - Control ID (int) of the created checkbox.
; Author.........: KleuTSchi
; Remarks........: This function does not validate $a_s_OnEventFunc; pass "" to skip wiring.
; Related........: GUICtrlCreateRadio, GUICtrlSetOnEvent, GUICtrlSetState
; ===============================================================================================================================
Func GUI_CreateRadio($a_s_Text, $a_i_X, $a_i_Y, $a_i_Width = -1, $a_i_Height = -1, $a_b_Checked = False, $a_s_OnEventFunc = "")
    If $a_i_Width <= 0 Then $a_i_Width  = -1
    If $a_i_Height <= 0 Then $a_i_Height = -1
    Local $l_i_ControlID = GUICtrlCreateRadio($a_s_Text, $a_i_X, $a_i_Y, $a_i_Width, $a_i_Height)
    If $a_b_Checked Then GUICtrlSetState($l_i_ControlID, $GUI_CHECKED)
    If $a_s_OnEventFunc <> "" Then GUICtrlSetOnEvent($l_i_ControlID, $a_s_OnEventFunc)
    Return $l_i_ControlID
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreateLabeledInput
; Description....: Creates a label (fixed 80x20) and an adjacent input control at specified coordinates.
; Syntax.........: GUI_CreateLabeledInput ( $a_s_Label, $a_i_LabelX, $a_i_LabelY, $a_i_InputX, $a_i_InputY, $a_i_Width, $a_i_Height [, $a_i_Style = 0 ] )
; Parameters.....: $a_s_Label     - Label text.
;                  $a_i_LabelX, $a_i_LabelY
;                                 - Label position (pixels). Size is fixed at 80x20 to match existing layout.
;                  $a_i_InputX, $a_i_InputY
;                                 - Input position (pixels).
;                  $a_i_Width     - Input width (pixels).
;                  $a_i_Height    - Input height (pixels).
;                  $a_i_Style     - Optional. Input style flags (e.g., $ES_PASSWORD). Default 0.
; Return values..: Success        - Control ID (int) of the created input.
; Author.........: KleuTSchi
; Remarks........: Preserves current layout by using the same label size you already rely on.
; Related........: GUICtrlCreateLabel, GUICtrlCreateInput
; ===============================================================================================================================
Func GUI_CreateLabeledInput($a_s_Label, $a_i_LabelX, $a_i_LabelY, $a_i_InputX, $a_i_InputY, $a_i_Width, $a_i_Height, $a_i_Style = 0)
    GUICtrlCreateLabel($a_s_Label, $a_i_LabelX, $a_i_LabelY, 80, 20)
    Return GUICtrlCreateInput("", $a_i_InputX, $a_i_InputY, $a_i_Width, $a_i_Height, $a_i_Style)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreateCharDlgButtons
; Description....: Creates dialog buttons for the Character window based on the dialog type and wires their events.
; Syntax.........: GUI_CreateCharDlgButtons ( $a_i_Type )
; Parameters.....: $a_i_Type      - One of:
;                                    $GC_I_CHARACTER_GUI_TYPE_ADD
;                                    $GC_I_CHARACTER_GUI_TYPE_EDIT
;                                    $GC_I_CHARACTER_GUI_TYPE_MULTI_EDIT
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Populates the following globals with control IDs:
;                    $g_i_CtrlID_OKButton, $g_i_CtrlID_CancelButton, $g_i_CtrlID_CancelAllButton (multi-edit only)
;                  Coordinates/sizes match the existing layout; only the event target differs by type.
;                  Requires GUIOnEventMode = True.
; Related........: GUICtrlCreateButton, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_CreateCharDlgButtons($a_i_Type)
    Switch $a_i_Type
        Case $GC_I_CHARACTER_GUI_TYPE_ADD, $GC_I_CHARACTER_GUI_TYPE_EDIT
            $g_i_CtrlID_OKButton = GUICtrlCreateButton("Confirm", 49, 157, 112, 32)
            If $a_i_Type = $GC_I_CHARACTER_GUI_TYPE_ADD Then
                GUICtrlSetOnEvent($g_i_CtrlID_OKButton, "GUI_Character_OnConfirm_Add")
            Else
                GUICtrlSetOnEvent($g_i_CtrlID_OKButton, "GUI_Character_OnConfirm_Edit")
            EndIf

            $g_i_CtrlID_CancelButton = GUICtrlCreateButton("Cancel", 169,157, 112, 32)
            GUICtrlSetOnEvent($g_i_CtrlID_CancelButton, "GUI_Character_OnCancel")

        Case $GC_I_CHARACTER_GUI_TYPE_MULTI_EDIT
            $g_i_CtrlID_OKButton = GUICtrlCreateButton("Confirm", 49, 157, 72, 32)
            GUICtrlSetOnEvent($g_i_CtrlID_OKButton, "GUI_Character_OnConfirm_Edit")

            $g_i_CtrlID_CancelButton = GUICtrlCreateButton("Cancel", 129,157, 72, 32)
            GUICtrlSetOnEvent($g_i_CtrlID_CancelButton, "GUI_Character_OnCancel")

            $g_i_CtrlID_CancelAllButton = GUICtrlCreateButton("Cancel All", 209, 157, 72, 32)
            GUICtrlSetOnEvent($g_i_CtrlID_CancelAllButton, "GUI_Character_OnCancelAll")
    EndSwitch
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BuildTab_General
; Description....: Builds the "General" tab contents (version group, character combo, core checkboxes, console, Start button, banner).
; Syntax.........: GUI_BuildTab_General ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Wires events for: rendering, on-top, mode toggles, and Start.
;                  - Creates a RichEdit inside a label host for the debug console.
;                  - Requires GUIOnEventMode = True.
; Related........: GUI_CreateCheckbox, _GUICtrlRichEdit_Create, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_BuildTab_General()
    GUICtrlCreateGroup("Session", 10, 4, 279, 456)
    ; Dropdowns
    GUICtrlCreateLabel("Character", 21, 29)
    $g_i_CtrlID_Combo_CharInput = GUICtrlCreateCombo("", 21, 45, 257, 25)
    GUICtrlCreateLabel("Sell Items at", 21, 74)
    $g_i_CtrlID_Combo_LocationInput = GUICtrlCreateCombo("", 21, 90, 257, 25)
    GUICtrlSetData($g_i_CtrlID_Combo_LocationInput, "Guild Hall" & $GC_S_DATA_SEPARATOR & "Kaineng Center")

    ; Settings Checkboxes
    $g_i_CtrlID_CBX_OnTop = GUI_CreateCheckbox("Always On Top", 21, 122, -1, -1, False, "GUI_Main_OnToggleOnTop")
    $g_i_CtrlID_CBX_Rendering = GUI_CreateCheckbox("Disable Rendering", 21, 145, -1, -1, False, "GUI_Main_ToggleRendering")
    GUICtrlSetState($g_i_CtrlID_CBX_Rendering, $GUI_DISABLE)
    $g_i_CtrlID_CBX_NormalMode = GUI_CreateRadio("Normal Mode", 152, 122, -1, -1, False, "GUI_Main_OnToggleModeNM")
    $g_i_CtrlID_CBX_HardMode = GUI_CreateRadio("Hard Mode", 152, 145, -1, -1, True, "GUI_Main_OnToggleModeHM")

    ; Debugging Console
    $g_i_CtrlID_Edit_Console = GUICtrlCreateEdit("", 21, 177, 257, 195, BitOR($WS_VSCROLL, $ES_READONLY, $ES_AUTOVSCROLL), $WS_EX_STATICEDGE)
    $g_h_CtrlHnd_Edit_Console = GUICtrlGetHandle($g_i_CtrlID_Edit_Console)
    GUICtrlSetBkColor($g_i_CtrlID_Edit_Console, 0xFFFFFF)

    ; Buttons
    $g_i_CtrlID_Button_Start = GUICtrlCreateButton("Start", 20, 386, 259, 30)
    GUICtrlSetOnEvent($g_i_CtrlID_Button_Start, "GUI_Main_OnStart")
    $g_i_CtrlID_Button_OpenLockboxes = GUICtrlCreateButton("Open Lockboxes", 20, 419, 128, 30)
    GUICtrlSetOnEvent($g_i_CtrlID_Button_OpenLockboxes, "GUI_Main_OnOpenLockboxes")
    GUICtrlSetState($g_i_CtrlID_Button_OpenLockboxes, $GUI_DISABLE)
    $g_i_CtrlID_Button_Trade = GUICtrlCreateButton("Trade Mode", 151, 419, 128, 30)
    GUICtrlSetOnEvent($g_i_CtrlID_Button_Trade, "GUI_Main_OnTradeMode")
    GUICtrlSetState($g_i_CtrlID_Button_Trade, $GUI_DISABLE)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ; Banner
    GUICtrlCreateGroup("", 299, 4, 190, 456)
    GUI_CreatePic(@ScriptDir & "\Images\BannerGeneral.jpg", 300, 11, 188, 447)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BuildTab_LootConfig
; Description....: Builds the "Loot Config" tab (Bags, Exchange Ministerial Commendations, Exchange Gold, Loot) and the banner.
; Syntax.........: GUI_BuildTab_LootConfig ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Default checked states: Bags 1-4, Guards, Ecto, Lockpicks, Black Dyes.
;                  - Event callbacks are wired for toggles that impact runtime logic.
;                  - Requires GUIOnEventMode = True.
; Related........: GUI_CreateCheckbox, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_BuildTab_LootConfig()
    ; Bags
    GUICtrlCreateGroup("Bags", 10,  4, 279, 52)
    $g_i_CtrlID_CBX_UseBag1 = GUI_CreateCheckbox("Bag 1", 21, 27, -1, -1, True)
    $g_i_CtrlID_CBX_UseBag2 = GUI_CreateCheckbox("Bag 2", 75, 27, -1, -1, True)
    $g_i_CtrlID_CBX_UseBag3 = GUI_CreateCheckbox("Bag 3", 130, 27, -1, -1, True)
    $g_i_CtrlID_CBX_UseBag4 = GUI_CreateCheckbox("Bag 4", 185, 27, -1, -1, True)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ; Exchanges
    GUICtrlCreateGroup("Exchange – Ministerial Commendations", 10,  59, 279, 98) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_CBX_ExchangeGuard = GUI_CreateRadio("Imperial Guard Reinforcement Orders", 21, 82, -1, -1, True)
    $g_i_CtrlID_CBX_ExchangeSeal = GUI_CreateRadio("Seals of the Dragon Empire", 21, 105, -1, -1, False)
    $g_i_CtrlID_CBX_ExchangeLockbox = GUI_CreateRadio("Imperial Guard Lockboxes", 21, 128, -1, -1, False)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    GUICtrlCreateGroup("Exchange – Gold", 10,  160, 279, 98) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_CBX_ExchangeEcto = GUI_CreateRadio("Globs of Ectoplasm", 21, 183, -1, -1, True)
    $g_i_CtrlID_CBX_ExchangeObby = GUI_CreateRadio("Obsidian Shards", 21, 206, -1, -1, False)
    $g_i_CtrlID_CBX_ExchangeLP = GUI_CreateRadio("Lockpicks", 21, 229, -1, -1, False)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    GUICtrlCreateGroup("Loot – General", 10,  261, 279, 98) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_CBX_LootLP = GUI_CreateCheckbox("Pick up Lockpicks", 21, 284, -1, -1, True)
    $g_i_CtrlID_CBX_LootBD = GUI_CreateCheckbox("Pick up Black Dyes", 21, 307, -1, -1, True)
    $g_i_CtrlID_CBX_LootTome = GUI_CreateCheckbox("Pick up Tomes", 21, 330, -1, -1, False)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    GUICtrlCreateGroup("Loot – Event", 10,  362, 279, 98) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_CBX_LootPCon = GUI_CreateCheckbox("Pick up PCons", 21, 385, -1, -1, False)
    $g_i_CtrlID_CBX_LootEventToken = GUI_CreateCheckbox("Pick up Event Tokens", 21, 408, -1, -1, False)
    $g_i_CtrlID_CBX_LootTPItem = GUI_CreateCheckbox("Pick up Title Point Items", 21, 431, -1, -1, False)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ; Banner
    GUICtrlCreateGroup("", 299, 4, 190, 456)
    GUI_CreatePic(@ScriptDir & "\Images\BannerLootConfig.jpg", 300, 11, 188, 447)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BuildTab_TradeConfig
; Description....: Builds the "Trade Config" tab (determining tradeable items) and the banner.
; Syntax.........: GUI_BuildTab_TradeConfig ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Default checked states: Guards, Seals, Tengu.
;                  - Event callbacks are wired for toggles that impact runtime logic.
;                  - Requires GUIOnEventMode = True.
; Related........: GUI_CreateCheckbox, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_BuildTab_TradeConfig()
    GUICtrlCreateGroup("Trade – WoC Items", 10,  4, 279, 121) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_CBX_TradeGuard = GUI_CreateCheckbox("Imperial Guard Reinforcement Orders", 21, 27, -1, -1, True)
    $g_i_CtrlID_CBX_TradeSeal = GUI_CreateCheckbox("Seals of the Dragon Empire", 21, 50, -1, -1, True)
    $g_i_CtrlID_CBX_TradeTengu = GUI_CreateCheckbox("Tengu Support Flares", 21, 73, -1, -1, True)
    $g_i_CtrlID_CBX_TradeMC = GUI_CreateCheckbox("Ministerial Commendations", 21, 96, -1, -1, False)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    GUICtrlCreateGroup("Trade – General Items", 10,  128, 279, 332) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_CBX_TradeEcto = GUI_CreateCheckbox("Globs of Ectoplasm", 21, 151, -1, -1, False)
    $g_i_CtrlID_CBX_TradeObby = GUI_CreateCheckbox("Obsidian Shards", 21, 174, -1, -1, False)
    GUICtrlCreateLabel("", 16, 201, 267, 2, $SS_SUNKEN)
    $g_i_CtrlID_CBX_TradeLP = GUI_CreateCheckbox("Lockpicks", 21, 209, -1, -1, False)
    $g_i_CtrlID_CBX_TradeBD = GUI_CreateCheckbox("Black Dyes", 21, 232, -1, -1, False)
    GUICtrlCreateLabel("", 16, 259, 267, 2, $SS_SUNKEN)
    $g_i_CtrlID_CBX_TradeTome = GUI_CreateCheckbox("Tomes", 21, 267, -1, -1, False)
    $g_i_CtrlID_CBX_TradePCon = GUI_CreateCheckbox("PCons", 21, 290, -1, -1, False)
    GUICtrlCreateLabel("", 16, 317, 267, 2, $SS_SUNKEN)
    $g_i_CtrlID_CBX_TradeEventToken = GUI_CreateCheckbox("Event Tokens", 21, 326, -1, -1, False)
    GUICtrlCreateLabel("", 16, 354, 267, 2, $SS_SUNKEN)
    $g_i_CtrlID_CBX_TradeIcedTea = GUI_CreateCheckbox("Battle Isle Iced Teas", 21, 362, -1, -1, False)
    $g_i_CtrlID_CBX_TradeDCake = GUI_CreateCheckbox("Delicious Cakes", 21, 385, -1, -1, False)
    $g_i_CtrlID_CBX_TradeBeacon = GUI_CreateCheckbox("Party Beacons", 21, 408, -1, -1, False)
    $g_i_CtrlID_CBX_TradeTPItem = GUI_CreateCheckbox("Other Title Point Items", 21, 431, -1, -1, False)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ; Banner
    GUICtrlCreateGroup("", 299, 4, 190, 456)
    GUI_CreatePic(@ScriptDir & "\Images\BannerTradeConfig.jpg", 300, 11, 188, 447)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BuildTab_Statistics
; Description....: Builds the "Statistics" tab (runtime display, success/failure/total, item counts & per-run averages, credits).
; Syntax.........: GUI_BuildTab_Statistics ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Percentage/average labels are initialized via GUI_FormatPercent/GUI_PerRunAvg to avoid divide-by-zero.
;                  - Adds two sunken separators for readability; sets credits label font to italic.
;                  - Use GUI_UpdateStatistics() after each run to refresh values.
; Related........: GUI_FormatPercent, GUI_PerRunAvg, GUI_UpdateStatistics, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_BuildTab_Statistics()
    ; Performance
    GUICtrlCreateGroup("Performance", 10, 4, 479, 98)
    GUICtrlCreateLabel("Average Runtime", 21, 29, 98)
    $g_i_CtrlID_Label_AvgRuntime = GUICtrlCreateLabel($g_i_AvgRuntimeMinutes & " Minutes " & $g_i_AvgRuntimeMinutesMod & " Seconds", 173, 29, 284)
    GUICtrlCreateLabel("Fastest Runtime", 21, 48, 98)
    $g_i_CtrlID_Label_FastestRuntime = GUICtrlCreateLabel($g_i_FastestRuntimeMinutes & " Minutes " & $g_i_FastestRuntimeMinutesMod & " Seconds", 173, 48, 284)
    GUICtrlCreateLabel("", 16, 69, 467, 2, $SS_SUNKEN)
    GUICtrlCreateLabel("Average Foe Count", 21, 79, 457)
    $g_i_CtrlID_Label_AvgFoeCount = GUICtrlCreateLabel($g_i_Count_AvgSpikedFoes, 173, 79, 284)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ;~ ; Run Statistics
    GUICtrlCreateGroup("Run Statistics", 10, 105, 479, 148)
    GUICtrlCreateLabel("Status", 21, 130)
    GUICtrlCreateLabel("Count", 173, 130)
    GUICtrlCreateLabel("Count Percentage", 325, 130)
    GUICtrlCreateLabel("", 16, 151, 467, 2, $SS_SUNKEN)
    GUICtrlCreateLabel("Success", 21, 161)
    $g_i_CtrlID_Label_SuccessCount = GUICtrlCreateLabel($g_i_Count_Runs - $g_i_Count_Fails, 173, 161, 152)
    $g_i_CtrlID_Label_SuccessCountPercentage = GUICtrlCreateLabel(GUI_FormatPercent($g_i_Count_Runs - $g_i_Count_Fails, $g_i_Count_Runs), 325, 161, 152)
    GUICtrlCreateLabel("Failure", 21, 180)
    $g_i_CtrlID_Label_FailureCount = GUICtrlCreateLabel($g_i_Count_Fails, 173, 180, 152)
    $g_i_CtrlID_Label_FailureCountPercentage = GUICtrlCreateLabel(GUI_FormatPercent($g_i_Count_Fails, $g_i_Count_Runs), 325, 180, 152)
    GUICtrlCreateLabel("– Miku stuck", 21, 199) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_Label_MikuFailureCount = GUICtrlCreateLabel($g_i_Count_MikuFails, 173, 199, 152)
    $g_i_CtrlID_Label_MikuFailureCountPercentage = GUICtrlCreateLabel(GUI_FormatPercent($g_i_Count_MikuFails, $g_i_Count_Runs), 325, 199, 152)
    GUICtrlCreateLabel("", 16, 220, 467, 2, $SS_SUNKEN)
    GUICtrlCreateLabel("Total", 21, 230)
    $g_i_CtrlID_Label_TotalCount = GUICtrlCreateLabel($g_i_Count_Runs, 173, 230, 152)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ; Loot Statistics
    GUICtrlCreateGroup("Item Statistics", 10, 256, 479, 155)
    GUICtrlCreateLabel("Name", 21, 281)
    GUICtrlCreateLabel("Count", 173, 281)
    GUICtrlCreateLabel("Count/Run", 325, 281)
    GUICtrlCreateLabel("", 17, 302, 467, 2, $SS_SUNKEN)
    GUICtrlCreateLabel("Ministerial Commendations", 21, 312)
    $g_i_CtrlID_Label_MCCount = GUICtrlCreateLabel($g_i_Count_MinisterialCommendationLooted, 173, 312, 152)
    $g_i_CtrlID_Label_MCCPR = GUICtrlCreateLabel(GUI_PerRunAvg($g_i_Count_MinisterialCommendationLooted, $g_i_Count_Runs), 325, 312, 152)
    GUICtrlCreateLabel("Golden Items", 21, 331)
    $g_i_CtrlID_Label_GICount = GUICtrlCreateLabel($g_i_Count_GoldItem, 173, 331, 152)
    $g_i_CtrlID_Label_GICPR = GUICtrlCreateLabel(GUI_PerRunAvg($g_i_Count_GoldItem, $g_i_Count_Runs), 325, 331, 152)
    GUICtrlCreateLabel("– Put in Storage", 21, 350) ; En Dash for cleaner alignment with group bounding box
    $g_i_CtrlID_Label_StoredGICount = GUICtrlCreateLabel($g_i_Count_StoredGoldItem, 173, 350, 152)
    $g_i_CtrlID_Label_StoredGICPR = GUICtrlCreateLabel(GUI_PerRunAvg($g_i_Count_StoredGoldItem, $g_i_Count_Runs), 325, 350, 152)
    GUICtrlCreateLabel("Lockpicks", 21, 369)
    $g_i_CtrlID_Label_LPCount = GUICtrlCreateLabel($g_i_Count_Lockpick, 173, 369, 152)
    $g_i_CtrlID_Label_LPCPR = GUICtrlCreateLabel(GUI_PerRunAvg($g_i_Count_Lockpick, $g_i_Count_Runs), 325, 369, 152)
    GUICtrlCreateLabel("Black Dyes", 21, 388)
    $g_i_CtrlID_Label_BDCount = GUICtrlCreateLabel($g_i_Count_BlackDye, 173, 388, 152)
    $g_i_CtrlID_Label_BDCPR = GUICtrlCreateLabel(GUI_PerRunAvg($g_i_Count_BlackDye, $g_i_Count_Runs), 325, 388, 152)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group

    ; Credits
    GUICtrlCreateGroup("", 10, 414, 479, 46)
    $g_i_CtrlID_Label_Credits = GUICtrlCreateLabel("Author: KleuTSchi ft. ZupaBlahq", 11, 432, 446, -1, BitOR($GUI_SS_DEFAULT_LABEL, $SS_CENTER))
    GUICtrlSetFont($g_i_CtrlID_Label_Credits, 9, $FW_NORMAL,  $GUI_FONTITALIC)
    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BuildTab_Characters
; Description....: Builds the "Characters" tab (list view of registered characters with checkboxes and action buttons).
; Syntax.........: GUI_BuildTab_Characters ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - ListView columns: "E-Mail | Character Name | File Path"; LVS_REPORT with ascending sort.
;                  - Buttons "Add", "Edit", "Remove" are wired to their respective handlers.
;                  - Control IDs/handles are stored in globals for later access.
; Related........: GUICtrlCreateListView, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_BuildTab_Characters()
    GUICtrlCreateGroup("Registered Characters", 10,  4, 479, 456)

    ; Character List
    Local $l_i_ListViewStyle
    Switch $g_i_AccSorting
        Case 1
            $l_i_ListViewStyle = BitOR($LVS_REPORT, $LVS_SORTASCENDING)
        Case 2
            $l_i_ListViewStyle = BitOR($LVS_REPORT, $LVS_SORTDESCENDING)
        Case Else
            $l_i_ListViewStyle = $LVS_REPORT
    EndSwitch

    $g_i_CtrlID_AccountList = GUICtrlCreateListView("E-Mail" & $GC_S_DATA_SEPARATOR & "Character Name" & $GC_S_DATA_SEPARATOR & "File Path", 21, 31, 457, 374, $l_i_ListViewStyle, $WS_EX_STATICEDGE)
    $g_h_CtrlHnd_AccountList = GUICtrlGetHandle($g_i_CtrlID_AccountList)
    _GUICtrlListView_SetExtendedListViewStyle($g_h_CtrlHnd_AccountList, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_INFOTIP, $LVS_EX_FULLROWSELECT))

    ; Buttons
    $g_i_CtrlID_Button_Add = GUICtrlCreateButton("Add", 20, 419, 151, 30)
    GUICtrlSetOnEvent($g_i_CtrlID_Button_Add, "GUI_Main_OnAdd")
    $g_i_CtrlID_Button_Edit = GUICtrlCreateButton("Edit", 174, 419, 151, 30)
    GUICtrlSetOnEvent($g_i_CtrlID_Button_Edit, "GUI_Main_OnEdit")
    $g_i_CtrlID_Button_Remove = GUICtrlCreateButton("Remove", 328, 419, 151, 30)
    GUICtrlSetOnEvent($g_i_CtrlID_Button_Remove, "GUI_Main_OnRemove")

    GUICtrlCreateGroup("", -99, -99, 1, 1) ; Close group
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreateMainGUI
; Description....: Creates and shows the main application window with its tab control; delegates per-tab population to builders.
; Syntax.........: GUI_CreateMainGUI ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Ensures the "Config" folder exists before any INI access.
;                  - Sets main window icon and tray icon; wires window close to GUI_Exit.
;                  - Creates the Tab control, builds all four tabs, then shows the GUI.
;                  - Calls GUI_SetModalMsgBoxGUI() for modal message boxes and GUI_LoadCharacterList() to populate data.
;                  - Requires GUIOnEventMode = True.
; Related........: GUI_BuildTab_General, GUI_BuildTab_LootConfig, GUI_BuildTab_TradeConfig, GUI_BuildTab_Statistics, GUI_BuildTab_Characters, GUI_LoadCharacterList
; ===============================================================================================================================
Func GUI_CreateMainGUI()
    If Not FileExists(@ScriptDir & "\Config") Then DirCreate(@ScriptDir & "\Config")

    GUI_LoadGUISettingsFromINI($GC_S_SETTINGS_INI_PATH)

    _Crypt_Startup()

    $g_h_MainGUI = GUICreate("Encounter Re:Built", 499, 499, -1, -1)
    OnAutoItExitRegister("GUI_Cleanup")
    GUISetOnEvent($GUI_EVENT_CLOSE, "GUI_Exit", $g_h_MainGUI)
    GUI_SetIcon($g_h_MainGUI, @ScriptDir & "\Images\Encounter.ico")
    TraySetIcon(@ScriptDir & "\Images\Encounter.ico")

    $g_i_CtrlID_Tab = GUICtrlCreateTab(21, 477, 479, 27, BitOR($GUI_SS_DEFAULT_TAB, $TCS_FIXEDWIDTH, $TCS_HOTTRACK))
    $g_h_CtrlHnd_Tab = GUICtrlGetHandle($g_i_CtrlID_Tab)
    _GUICtrlTab_SetItemSize($g_h_CtrlHnd_Tab, 91, 20)

    GUICtrlCreateTabItem("General")
    GUI_BuildTab_General()

    GUICtrlCreateTabItem("Loot Config")
    GUI_BuildTab_LootConfig()

    GUICtrlCreateTabItem("Trade Config")
    GUI_BuildTab_TradeConfig()

    GUICtrlCreateTabItem("Statistics")
    GUI_BuildTab_Statistics()

    GUICtrlCreateTabItem("Characters")
    GUI_BuildTab_Characters()

    GUICtrlCreateTabItem("")

    GUI_SetModalMsgBoxGUI($g_h_MainGUI)
    GUI_LoadCharacterList()

    AddOns_SetOutput($g_h_CtrlHnd_Edit_Console)

    GUI_LoadBotSettingsFromINI($GC_S_SETTINGS_INI_PATH)

    GUISetState(@SW_SHOW, $g_h_MainGUI)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_CreateCharacterGUI
; Description....: Creates and shows the Character Add/Edit dialog as a child of the main GUI; wires events and buttons by type.
; Syntax.........: GUI_CreateCharacterGUI ( $a_s_WindowTitle, $a_i_WindowType )
; Parameters.....: $a_s_WindowTitle - Dialog caption text.
;                  $a_i_WindowType  - One of:
;                                     $GC_I_CHARACTER_GUI_TYPE_ADD
;                                     $GC_I_CHARACTER_GUI_TYPE_EDIT
;                                     $GC_I_CHARACTER_GUI_TYPE_MULTI_EDIT
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Disables the main window while the dialog is open; uses main as parent owner.
;                  - Creates labeled inputs for Character/E-Mail; password input with eye-toggle button; file path + browse button.
;                  - GUI_CreateCharDlgButtons() places OK/Cancel (and Cancel All for multi-edit) and wires their handlers.
;                  - Calls GUI_SetModalMsgBoxGUI() for modal message boxes; sets the dialog icon if available.
;                  - Requires GUIOnEventMode = True.
; Related........: GUI_CreateLabeledInput, GUI_CreateCharDlgButtons, GUI_Character_OnShowPwd, GUI_Character_OnBrowse
; ===============================================================================================================================
Func GUI_CreateCharacterGUI($a_s_WindowTitle, $a_i_WindowType)
    GUISetState(@SW_DISABLE, $g_h_MainGUI)

    $g_h_CharacterGUI = GUICreate($a_s_WindowTitle, 330, 208, -1, -1, BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU), -1, $g_h_MainGUI)
    GUISetOnEvent($GUI_EVENT_CLOSE, "GUI_Character_OnCancel", $g_h_CharacterGUI)
    GUI_SetIcon($g_h_CharacterGUI, @ScriptDir & "\Images\Encounter.ico", -1)

    $g_i_CtrlID_CharsInput = GUI_CreateLabeledInput("Character:", 19, 23, 87, 20, 223, 22)
    $g_i_CtrlID_EmailInput = GUI_CreateLabeledInput("E-Mail:",    19, 55, 87, 52, 223, 22)

    GUICtrlCreateLabel("Password:", 19, 87, 70, 20)
    $g_i_CtrlID_PwdInput = GUICtrlCreateInput("", 87, 84, 185, 22, BitOR($GUI_SS_DEFAULT_INPUT, $ES_PASSWORD))
    $g_i_CtrlID_ShowPwdButton = GUICtrlCreateButton("👁", 281, 83, 30, 24)
    $g_b_PwdMasked = True
    GUICtrlSetOnEvent($g_i_CtrlID_ShowPwdButton, "GUI_Character_OnShowPwd")

    GUICtrlCreateLabel("File Path:", 19, 119, 70, 20)
    $g_i_CtrlID_FilePathInput = GUICtrlCreateInput("", 87, 116, 185, 22)
    $g_i_CtrlID_BrowseButton = GUICtrlCreateButton("...", 281, 115, 30, 24)
    GUICtrlSetOnEvent($g_i_CtrlID_BrowseButton, "GUI_Character_OnBrowse")

    GUI_CreateCharDlgButtons($a_i_WindowType)

    GUI_SetModalMsgBoxGUI($g_h_CharacterGUI)
    GUISetState(@SW_SHOW, $g_h_CharacterGUI)
EndFunc
#EndRegion GUICreate

#Region GUIFunctions
; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Exit
; Description....: Performs a graceful shutdown: releases grid slot, closes the game process, tears down Crypto, and exits.
; Syntax.........: GUI_Exit ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Calls Launch_ReleaseGridSlot($g_i_GridAllocatedSlot); a value of -1 is ignored by the callee.
;                  - Calls ProcessClose($g_i_GWProcessId) if nonzero; errors are not surfaced to the user.
;                  - Always calls _Crypt_Shutdown() before Exit.
; Related........: Launch_ReleaseGridSlot, ProcessClose, _Crypt_Shutdown
; ===============================================================================================================================
Func GUI_Exit()
    GUI_Cleanup()
    Exit
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_GUICtrlIsChecked
; Description....: Helper that returns True if a checkbox control is currently checked.
; Syntax.........: GUI_GUICtrlIsChecked ( $a_h_Control )
; Parameters.....: $a_h_Control - Control ID returned by GUICtrlCreateCheckbox (or similar).
; Return values..: True  - Control is checked.
;                  False - Control is not checked.
; Author.........: KleuTSchi
; Remarks........: Wraps GUICtrlRead().
; Related........: GUICtrlRead
; ===============================================================================================================================
Func GUI_GUICtrlIsChecked($a_h_Control)
	Return GUICtrlRead($a_h_Control) = $GUI_CHECKED
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_AutoSizeColumns
; Description....: Autosizes all ListView columns to the header’s width.
; Syntax.........: GUI_AutoSizeColumns ( $a_h_ListView )
; Parameters.....: $a_h_ListView - Handle to a ListView control (NOT the control ID).
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Retrieves the header via _GUICtrlListView_GetHeader() and sizes each column to LVSCW_AUTOSIZE_USEHEADER.
;                  - Safe when column count is zero (no-op).
; Related........: _GUICtrlListView_GetHeader, _GUICtrlHeader_GetItemCount, _GUICtrlListView_SetColumnWidth
; ===============================================================================================================================
Func GUI_AutoSizeColumns($a_h_ListView)
	Local Const $LVSCW_AUTOSIZE_USEHEADER = -2

    Local $l_h_Header = _GUICtrlListView_GetHeader($a_h_ListView)
    Local $l_i_Cols= _GUICtrlHeader_GetItemCount($l_h_Header)

    For $i = 0 To $l_i_Cols - 1
        _GUICtrlListView_SetColumnWidth($a_h_ListView, $i, $LVSCW_AUTOSIZE_USEHEADER)
    Next
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_LoadCharacterList
; Description....: Loads characters from the INI, populates the ListView and ComboBox, and normalizes passwords to encrypted form.
; Syntax.........: GUI_LoadCharacterList ( )
; Parameters.....: None
; Return values..: Success - Number of sections found in the INI (may be 0).
;                  Failure - 0 when the INI is missing or cannot be read (a message box may already have been shown).
; Author.........: KleuTSchi
; Remarks........: - **INI I/O is serialized** via Security_AcquireFileMutex($GC_S_CHARACTERS_INI_PATH, 5000) / Security_CloseMutex().
;                  - For each section: reads Email/Pwd/FilePath; if Pwd is plaintext (no $GC_S_SEC_TAG), rewrites it encrypted.
;                  - Populates $g_h_CtrlHnd_AccountList with columns: E-Mail | Character Name | File Path.
;                  - Builds the character ComboBox from valid entries and sorts it ascending.
;                  - On first load only, shows a consolidated warning for entries with missing fields.
; Related........: Security_AcquireFileMutex, Security_CloseMutex, Security_EncryptString, IniRead, IniWrite, _
;                  _GUICtrlListView_AddItem, _GUICtrlListView_SetItemText, GUI_AutoSizeColumns
; ===============================================================================================================================
Func GUI_LoadCharacterList()
	Static $s_b_FirstLoad = True

    If Not FileExists($GC_S_CHARACTERS_INI_PATH) Then
        GUI_ModalMsgBox($MB_ICONERROR, "Error - INI File", "Could not find INI file: " & $GC_S_CHARACTERS_INI_PATH)
        Return 0
    EndIf

	_GUICtrlListView_DeleteAllItems($g_h_CtrlHnd_AccountList)

    Local $l_i_Timeout = 5000
    Local $l_h_IniMutex = Security_AcquireFileMutex($GC_S_CHARACTERS_INI_PATH, $l_i_Timeout)
    If $l_h_IniMutex = 0 Then Return 0

	Local $l_as_Sections = IniReadSectionNames($GC_S_CHARACTERS_INI_PATH)
	If @error Or Not IsArray($l_as_Sections) Then
        GUICtrlSetData($g_i_CtrlID_Combo_CharInput, $GC_S_DATA_SEPARATOR)
        GUI_AutoSizeColumns($g_h_CtrlHnd_AccountList)
        Return 0
    EndIf

    Local $l_as_ValidCharacters[UBound($l_as_Sections)], $l_i_Count_ValidCharacters = 0
	Local $l_s_MissingMsg = ""

	For $i = 1 To $l_as_Sections[0]
		Local $l_s_Character = $l_as_Sections[$i]
		Local $l_s_Email = IniRead($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Email", "")
		Local $l_s_Pwd = IniRead($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Pwd", "")
        If StringLeft($l_s_Pwd, $GC_S_SEC_TAG_LE) <> $GC_S_SEC_TAG Then
            IniWrite($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Pwd", Security_EncryptString($l_s_Pwd))
        EndIf
		Local $l_s_FilePath = IniRead($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "FilePath", "")

		Local $l_s_MissingInfo = ""
		If $l_s_Email = "" Then $l_s_MissingInfo &= "E-Mail, "
		If $l_s_Pwd = "" Then $l_s_MissingInfo &= "Pwd, "
		If $l_s_FilePath = "" Then $l_s_MissingInfo &= "File Path, "

		If $l_s_MissingInfo <> "" Then
			$l_s_MissingInfo = StringTrimRight($l_s_MissingInfo, 2)
			$l_s_MissingMsg &= "[" & $l_s_Character & "]: " & $l_s_MissingInfo & @CRLF
		Else
			$l_as_ValidCharacters[$l_i_Count_ValidCharacters] = $l_s_Character
			$l_i_Count_ValidCharacters += 1
		EndIf

		Local $l_i_Row = _GUICtrlListView_AddItem($g_h_CtrlHnd_AccountList, $l_s_Email)
		_GUICtrlListView_SetItemText($g_h_CtrlHnd_AccountList, $l_i_Row, $l_s_Character, 1)
		_GUICtrlListView_SetItemText($g_h_CtrlHnd_AccountList, $l_i_Row, $l_s_FilePath, 2)
	Next

    Security_CloseMutex($l_h_IniMutex)

	ReDim $l_as_ValidCharacters[$l_i_Count_ValidCharacters]

    Switch $g_i_CharSorting
        Case 1
            _ArraySort($l_as_ValidCharacters)
        Case 2
            _ArraySort($l_as_ValidCharacters, 1)
        Case Else
            ; Unsorted
    EndSwitch

    For $i = 0 To UBound($l_as_ValidCharacters) - 1
        $l_as_ValidCharacters[$i] = ($i + 1) & " - " & $l_as_ValidCharacters[$i]
    Next

	Local $l_s_CharInput = _ArrayToString($l_as_ValidCharacters, $GC_S_DATA_SEPARATOR)
	GUICtrlSetData($g_i_CtrlID_Combo_CharInput, $GC_S_DATA_SEPARATOR & $l_s_CharInput)

	If $s_b_FirstLoad And $l_s_MissingMsg <> "" Then
		Local Const $LC_I_MAX_ROWS = 20
		Local $l_a_Lines = StringSplit($l_s_MissingMsg, @CRLF, 1)
		Local $l_i_Count_Lines = UBound($l_a_Lines) - 1
		Local $l_s_DisplayMsg = ""

		If $l_i_Count_Lines > $LC_I_MAX_ROWS Then
			For $i = 1 To $LC_I_MAX_ROWS
				$l_s_DisplayMsg &= $l_a_Lines[$i] & @CRLF
			Next
			Local $l_i_Leftovers = $l_i_Count_Lines - $LC_I_MAX_ROWS
			$l_s_DisplayMsg &= @CRLF & "... and " & $l_i_Leftovers & " more items."
		Else
			$l_s_DisplayMsg = $l_s_MissingMsg
		EndIf

		$s_b_FirstLoad = False

		GUI_ModalMsgBox($MB_ICONWARNING, "Warning - Missing Character Information", _
			"The following character information is incomplete." & @CRLF & _
			"To be able to select the character(s) please update the character information." & @CRLF & @CRLF & $l_s_DisplayMsg)
	EndIf

	GUI_AutoSizeColumns($g_h_CtrlHnd_AccountList)

    Return $l_as_Sections[0]  ; number of items added
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_StripCharacterEnum
; Description....: Removes the numeric enumeration prefix from a character display string (e.g. "3 - Character Two")
;                  and returns the raw character name.
; Syntax.........: GUI_StripCharacterEnum ( $l_s_CharName )
; Parameters.....: $l_s_CharName - String : Character string as shown in the dropdown, optionally prefixed with "N - ".
; Return values..: Success - String : Raw character name with any leading "N - " prefix stripped.
;                  Failure - String : Returns the input unchanged if no enumeration prefix is present.
; Author.........: KleuTSchi
; Remarks........: - Strips only at the start of the string using regex: '^\s*\d+\s*-\s*'.
;                  - Safe for names containing hyphens (e.g. "-the rock-"); only a leading digit+hyphen pattern is removed.
;                  - If a real character name itself begins with "N - " it will be stripped as well (by design).
; Related........: StringRegExpReplace
; ===============================================================================================================================
Func GUI_StripCharacterEnum($l_s_CharName)
    Return StringRegExpReplace($l_s_CharName, '^\s*\d+\s*-\s*', '')
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_GetEnumCharacter
; Description....: Resolves a raw character name to its enumerated dropdown entry (e.g. "Character Two" -> "3 - Character Two")
;                  by scanning the current character ComboBox item list.
; Syntax.........: GUI_GetEnumCharacter ( $a_s_CharName )
; Parameters.....: $a_s_CharName - String : Raw character name (no enumeration prefix).
; Return values..: Success - String : The enumerated ComboBox item text if found (e.g. "3 - Character Two").
;                  Failure - String : Returns the input $a_s_CharName if the list cannot be read or no match exists.
; Author.........: KleuTSchi
; Remarks........: - Reads the current ComboBox items via _GUICtrlComboBox_GetListArray(GUICtrlGetHandle(...)).
;                  - Compares case-insensitively against GUI_StripCharacterEnum(item) to match raw names.
;                  - Depends on $g_i_CtrlID_Combo_CharInput being initialized and populated.
; Related........: GUICtrlGetHandle, _GUICtrlComboBox_GetListArray, GUI_StripCharacterEnum, StringLower
; ===============================================================================================================================
Func GUI_GetEnumCharacter($a_s_CharName)
    Local $l_h_CharInput = GUICtrlGetHandle($g_i_CtrlID_Combo_CharInput)
    Local $l_as_Characters = _GUICtrlComboBox_GetListArray($l_h_CharInput)
    If @error Or Not IsArray($l_as_Characters) Then Return $a_s_CharName

    Local $l_s_TargetChar = StringLower($a_s_CharName)
    For $i = 1 To $l_as_Characters[0]
        If StringLower(GUI_StripCharacterEnum($l_as_Characters[$i])) = $l_s_TargetChar Then
            Return $l_as_Characters[$i]
        EndIf
    Next

    Return $a_s_CharName
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_UpdateStatistics
; Description....: Refreshes the Statistics tab labels (success/failure/total and per-run averages).
; Syntax.........: GUI_UpdateStatistics ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Uses globals (e.g., $g_i_Count_Runs, $g_i_Count_Fails, item counters) and guards divide-by-zero via
;                    GUI_FormatPercent/GUI_PerRunAvg.
;                  - Keeps the runtime label text consistent with the initial build text.
; Related........: GUI_FormatPercent, GUI_PerRunAvg, GUICtrlSetData
; ===============================================================================================================================
Func GUI_UpdateStatistics()
    ; Keep label text consistent with initial build
    GUICtrlSetData($g_i_CtrlID_Label_AvgRuntime, $g_i_AvgRuntimeMinutes & " Minutes " & $g_i_AvgRuntimeMinutesMod & " Seconds")
    GUICtrlSetData($g_i_CtrlID_Label_FastestRuntime, $g_i_FastestRuntimeMinutes & " Minutes " & $g_i_FastestRuntimeMinutesMod & " Seconds")
    GUICtrlSetData($g_i_CtrlID_Label_AvgFoeCount, $g_i_Count_AvgSpikedFoes)

    Local $l_i_Runs = $g_i_Count_Runs
    Local $l_i_Fails = $g_i_Count_Fails
    Local $l_i_Success = $l_i_Runs - $l_i_Fails
    If $l_i_Success < 0 Then $l_i_Success = 0

    ; Success / Failure
    GUICtrlSetData($g_i_CtrlID_Label_SuccessCount, $l_i_Success)
    GUICtrlSetData($g_i_CtrlID_Label_SuccessCountPercentage, GUI_FormatPercent($l_i_Success, $l_i_Runs))

    GUICtrlSetData($g_i_CtrlID_Label_FailureCount, $l_i_Fails)
    GUICtrlSetData($g_i_CtrlID_Label_FailureCountPercentage, GUI_FormatPercent($l_i_Fails, $l_i_Runs))

    GUICtrlSetData($g_i_CtrlID_Label_MikuFailureCount, $g_i_Count_MikuFails)
    GUICtrlSetData($g_i_CtrlID_Label_MikuFailureCountPercentage, GUI_FormatPercent($g_i_Count_MikuFails, $l_i_Runs))

    ; Totals
    GUICtrlSetData($g_i_CtrlID_Label_TotalCount, $l_i_Runs)

    ; Per-item stats (safe when runs = 0)
    GUICtrlSetData($g_i_CtrlID_Label_MCCount, $g_i_Count_MinisterialCommendationLooted)
    GUICtrlSetData($g_i_CtrlID_Label_MCCPR, GUI_PerRunAvg($g_i_Count_MinisterialCommendationLooted, $l_i_Runs))

    GUICtrlSetData($g_i_CtrlID_Label_GICount, $g_i_Count_GoldItem)
    GUICtrlSetData($g_i_CtrlID_Label_GICPR, GUI_PerRunAvg($g_i_Count_GoldItem, $l_i_Runs))

    GUICtrlSetData($g_i_CtrlID_Label_StoredGICount, $g_i_Count_StoredGoldItem)
    GUICtrlSetData($g_i_CtrlID_Label_StoredGICPR, GUI_PerRunAvg($g_i_Count_StoredGoldItem, $l_i_Runs))

    GUICtrlSetData($g_i_CtrlID_Label_LPCount, $g_i_Count_Lockpick)
    GUICtrlSetData($g_i_CtrlID_Label_LPCPR, GUI_PerRunAvg($g_i_Count_Lockpick, $l_i_Runs))

    GUICtrlSetData($g_i_CtrlID_Label_BDCount, $g_i_Count_BlackDye)
    GUICtrlSetData($g_i_CtrlID_Label_BDCPR, GUI_PerRunAvg($g_i_Count_BlackDye, $l_i_Runs))
EndFunc   ;==>GUI_UpdateStatistics

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_StartBot
; Description....: Launches the selected character, positions the game window in the grid, navigates the pre-game screen, and enters the world.
; Syntax.........: GUI_StartBot ( )
; Parameters.....: None
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Launch_LaunchAccountFromINI failed
;                            2 -> Core_Initialize failed (no window handle)
;                            3 -> PreGame_Ptr() returned 0
;                            4 -> Character selection/enter failed (timeout or not found)
; Author.........: KleuTSchi
; Remarks........: - Uses ControlSend to send "{N}", "{RIGHT}", and "{ENTER}" with sleeps to advance the pre-game UI.
;                  - Allocates a grid slot and moves the window via Launch_AllocateGridSlot/Launch_MoveWindowToGridSlot.
;                  - Calls Map_WaitMapLoading() after entering the world to block until loading completes.
; Related........: Launch_LaunchAccountFromINI, Core_Initialize, Launch_AllocateGridSlot, Launch_MoveWindowToGridSlot, _
;                  PreGame_Ptr, PreGame_ChosenCharacter, PreGame_CharName, Map_WaitMapLoading, ControlSend
; ===============================================================================================================================
Func GUI_StartBot($a_s_Character, $a_b_Restart = False)
    If Not $a_b_Restart Then AddOns_InitLog(@ScriptDir & "\Log\" & $a_s_Character & ".log")

    Local $l_i_PID = Launch_LaunchAccountFromINI($GC_S_CHARACTERS_INI_PATH, $a_s_Character, $a_b_Restart)
	If $l_i_PID = 0 Then Return SetError(1, 0, False)
    Sleep(500)

	Local $l_h_Wnd = Core_Initialize($l_i_PID, False)
	If $l_h_Wnd = 0 Then
        AddOns_Out("[ERR] GwAu3 initialization failed")
        Security_CloseMutex($g_h_GameMutex)
        Return SetError(2, 0, False)
    EndIf
    Sleep(500)

	$g_i_GridAllocatedSlot = Launch_AllocateGridSlot()
	If $g_i_GridAllocatedSlot = -1 Then
        AddOns_Out("[ERR] Grid slot allocation failed")
        Security_CloseMutex($g_h_GameMutex)
        Return SetError(3, 0, False)
    EndIf
    Launch_MoveWindowToGridSlot($l_h_Wnd, $g_i_GridAllocatedSlot)
    WinSetTitle($l_h_Wnd, "", "Guild Wars - " & $a_s_Character)
	Sleep(500)

	Local $l_p_PreGame = PreGame_Ptr()
    If $l_p_PreGame = 0 Then
        Security_CloseMutex($g_h_GameMutex)
        Return SetError(4, 0, False)
    EndIf

    Local $l_i_CurrentIndex, $l_h_Timeout = TimerInit()
	Do
	    $l_i_CurrentIndex = Utils_MakeInt32(PreGame_ChosenCharacter())
		Sleep(500)
	Until $l_i_CurrentIndex <> -1 Or TimerDiff($l_h_Timeout) >= 60000
    If $l_i_CurrentIndex = -1 Then
        Security_CloseMutex($g_h_GameMutex)
        Return SetError(5, 0, False)
    EndIf

    ControlSend($l_h_Wnd, "", "", "{N}")
    Sleep(500)

    $l_i_CurrentIndex = Utils_MakeInt32(PreGame_ChosenCharacter())
	Local $l_s_CurrentName = StringStripWS(PreGame_CharName($l_i_CurrentIndex), 3)
	If StringCompare($l_s_CurrentName, $a_s_Character, 0) <> 0 Then
		Local Const $LC_I_MAX_ATTEMPTS = 20
		Local $l_i_Attempts = 0
		Local $l_b_Found = False
		Local $l_i_InitialIndex = $l_i_CurrentIndex

		While $l_i_Attempts < $LC_I_MAX_ATTEMPTS And Not $l_b_Found
			ControlSend($l_h_Wnd, "", "", "{RIGHT}")
			Sleep(500)

			$l_i_CurrentIndex = Utils_MakeInt32(PreGame_ChosenCharacter())
			$l_s_CurrentName = StringStripWS(PreGame_CharName($l_i_CurrentIndex), 3)

			If StringCompare($l_s_CurrentName, $a_s_Character, 0) = 0 Then
				$l_b_Found = True
			EndIf

			$l_i_Attempts += 1

			If $l_i_Attempts > 1 And $l_i_CurrentIndex = $l_i_InitialIndex Then
				ExitLoop
			EndIf
		WEnd

		If Not $l_b_Found Then
            Security_CloseMutex($g_h_GameMutex)
            Return SetError(6, 0, False)
        EndIf
	EndIf

    Map_InitMapIsLoaded()
    $l_h_Timeout = TimerInit()
    ControlSend($l_h_Wnd, "", "", "{ENTER}")
    While Not Map_WaitMapIsLoaded(10000) And TimerDiff($l_h_Timeout) < 60000
        ControlSend($l_h_Wnd, "", "", "{ENTER}")
    WEnd
    If TimerDiff($l_h_Timeout) >= 60000 Then
        Security_CloseMutex($g_h_GameMutex)
        Return SetError(7, 0, False)
    EndIf

	AddOns_Out("[INFO] Character loaded into game")

	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_ShowNextEdit
; Description....: Drives the multi-edit workflow: opens the next “Edit Character” dialog populated from the INI, or
;                  finalizes when the queue is exhausted (re-enables the main GUI).
; Syntax.........: GUI_ShowNextEdit ( )
; Parameters.....: None
; Return values..: Success - True when the edit queue is finished and control returns to the main GUI.
;                  Ongoing - (no explicit return) when another edit dialog is shown.
; Author.........: KleuTSchi
; Remarks........: - Uses $g_ai_EditQueue and $g_i_QueuePos to track which ListView rows are pending edits.
;                  - **INI reads are serialized** via Security_AcquireFileMutex($GC_S_CHARACTERS_INI_PATH, 5000) / Security_CloseMutex().
;                  - Populates the edit dialog inputs and sets $g_s_OldCharacter for rename handling in the OK handler.
;                  - When no more items remain, clears the queue, re-enables/activates the main GUI, and returns True.
; Related........: Security_AcquireFileMutex, Security_CloseMutex, IniRead, Security_DecryptString, _
;                  GUI_CreateCharacterGUI, _GUICtrlListView_GetItemText
; ===============================================================================================================================
Func GUI_ShowNextEdit()
	Local $l_i_QueueSize = UBound($g_ai_EditQueue)
    If $g_i_QueuePos >= $l_i_QueueSize Then
		ReDim $g_ai_EditQueue[0]
		$g_i_QueuePos = 0
		$g_s_OldCharacter = ""
		_GUICtrlListView_SetItemChecked($g_h_CtrlHnd_AccountList, -1, False)
		GUI_SetModalMsgBoxGUI($g_h_MainGUI)
		GUISetState(@SW_ENABLE, $g_h_MainGUI)
		WinActivate($g_h_MainGUI)
        Return True
    EndIf

    Local $l_i_Row = $g_ai_EditQueue[$g_i_QueuePos]
    Local $l_s_Character = _GUICtrlListView_GetItemText($g_h_CtrlHnd_AccountList, $l_i_Row, 1)

    Local $l_i_Timeout = 5000
    Local $l_h_IniMutex = Security_AcquireFileMutex($GC_S_CHARACTERS_INI_PATH, $l_i_Timeout)

    Local $l_s_Email = IniRead($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Email", "")
    Local $l_s_Pwd = Security_DecryptString(IniRead($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Pwd", ""))
    Local $l_s_FilePath = IniRead($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "FilePath", "")

    Security_CloseMutex($l_h_IniMutex)

	$g_s_OldCharacter = $l_s_Character

	Local $l_s_Title = ""
	If $l_i_QueueSize = 1 Then
		$l_s_Title = "Edit Character"
		GUI_CreateCharacterGUI($l_s_Title, $GC_I_CHARACTER_GUI_TYPE_EDIT)
	Else
    	$l_s_Title = "Edit Character [" & ($g_i_QueuePos + 1) & " of " & $l_i_QueueSize & "]"
		GUI_CreateCharacterGUI($l_s_Title, $GC_I_CHARACTER_GUI_TYPE_MULTI_EDIT)
	EndIf

	GUICtrlSetData($g_i_CtrlID_CharsInput, $l_s_Character)
	GUICtrlSetData($g_i_CtrlID_EmailInput, $l_s_Email)
	GUICtrlSetData($g_i_CtrlID_PwdInput, $l_s_Pwd)
	GUICtrlSetData($g_i_CtrlID_FilePathInput, $l_s_FilePath)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_RenderingCheck
; Description....: Syncs the game's rendering state with the "Disable Rendering" checkbox. If the checkbox state and the
;                  engine's render-disabled flag differ, it toggles rendering to match the checkbox.
; Syntax.........: GUI_RenderingCheck ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Idempotent: only calls Ui_ToggleRendering() when the checkbox state and render flag are out of sync.
; Related........: GUI_GUICtrlIsChecked, Ui_GetRenderDisabled, Ui_ToggleRendering
; ===============================================================================================================================
Func GUI_RenderingCheck()
    Local $l_b_DisableRenderingChecked = GUI_GUICtrlIsChecked($g_i_CtrlID_CBX_Rendering)
    Local $l_b_RenderingDisabled = Ui_GetRenderDisabled()

    If ($l_b_DisableRenderingChecked And Not $l_b_RenderingDisabled) _
    Or (Not $l_b_DisableRenderingChecked And $l_b_RenderingDisabled) Then
        Ui_ToggleRendering()
    EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_GetBotState
; Description....: Returns the current bot state value.
; Syntax.........: GUI_GetBotState()
; Parameters.....: None
; Return values..: Integer - One of $GC_I_BOTSTATE_* constants.
; Related........: GUI_BotIsIdle, GUI_BotIsOpening, GUI_BotIsRunning, GUI_BotIsTrading, GUI_SetBotState
; ===============================================================================================================================
Func GUI_GetBotState()
    Return $g_i_BotState
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BotIsRunning
; Description....: Helper to check whether the bot is currently running.
; Syntax.........: GUI_BotIsRunning()
; Parameters.....: None
; Return values..: True if state == $GC_I_BOTSTATE_RUN, else False.
; Related........: GUI_BotIsIdle, GUI_BotIsOpening, GUI_BotIsTrading, GUI_GetBotState
; ===============================================================================================================================
Func GUI_BotIsRunning()
    Return $g_i_BotState = $GC_I_BOTSTATE_RUN
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BotIsIdle
; Description....: Helper to check whether the bot is currently idle.
; Syntax.........: GUI_BotIsIdle()
; Parameters.....: None
; Return values..: True if state == $GC_I_BOTSTATE_IDLE, else False.
; Related........: GUI_BotIsOpening, GUI_BotIsRunning, GUI_BotIsTrading, GUI_GetBotState
; ===============================================================================================================================
Func GUI_BotIsIdle()
    Return $g_i_BotState = $GC_I_BOTSTATE_IDLE
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BotIsOpening
; Description....: Helper to check whether the bot is in "open lockboxes" mode.
; Syntax.........: GUI_BotIsOpening()
; Parameters.....: None
; Return values..: True if state == $GC_I_BOTSTATE_OPEN, else False.
; Related........: GUI_BotIsIdle, GUI_BotIsRunning, GUI_BotIsTrading, GUI_GetBotState
; ===============================================================================================================================
Func GUI_BotIsOpening()
    Return $g_i_BotState = $GC_I_BOTSTATE_OPEN
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BotIsTrading
; Description....: Helper to check whether the bot is in "trade" mode.
; Syntax.........: GUI_BotIsTrading()
; Parameters.....: None
; Return values..: True if state == $GC_I_BOTSTATE_TRADE, else False.
; Related........: GUI_BotIsIdle, GUI_BotIsOpening, GUI_BotIsRunning, GUI_GetBotState
; ===============================================================================================================================
Func GUI_BotIsTrading()
    Return $g_i_BotState = $GC_I_BOTSTATE_TRADE
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_EnterPause
; Description....: Transitions the bot into a paused state: cleans inventory, updates stats.
; Syntax.........: GUI_EnterPause()
; Parameters.....: None
; Return values..: None
; Related........: AddOns_Out, GUI_UpdateStatistics, Inventory
; ===============================================================================================================================
Func GUI_EnterPause()
    Inventory(True)
    AddOns_Out("[INFO] Bot is now paused")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_LeavePause
; Description....: Prepares the bot to resume from pause.
; Syntax.........: GUI_LeavePause()
; Parameters.....: None
; Return values..: None
; Related........: AddOns_Out, SetupEncounter
; ===============================================================================================================================
Func GUI_LeavePause()
    AddOns_Out("[INFO] Bot will now resume")
    SetupEncounter()
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_BotStateRender
; Description....: Renders and updates button labels and control enabled/disabled states based on the current bot state.
; Syntax.........: GUI_BotStateRender()
; Parameters.....: None
; Return values..: None
; Remarks........: Intended to be called after any state transition to keep the UI consistent.
; Related........: GUICtrlSetData, GUICtrlSetState, GUI_GetBotState
; ===============================================================================================================================
Func GUI_BotStateRender()
    Local $l_s_StartLabel = "Start"
    Local $l_s_OpenLabel = "Open Lockboxes"
    Local $l_s_TradeLabel = "Trade Mode"

    Local $l_i_StartState = $GUI_DISABLE
    Local $l_i_OpenState = $GUI_DISABLE
    Local $l_i_TradeState = $GUI_DISABLE
    Local $l_i_RenderingState = $GUI_DISABLE
    Local $l_i_NormalModeState = $GUI_DISABLE
    Local $l_i_HardModeState = $GUI_DISABLE

    Switch $g_i_BotState
        Case $GC_I_BOTSTATE_OPEN
            $l_s_OpenLabel  = "Stop Opening"
        Case $GC_I_BOTSTATE_TRADE
            $l_s_TradeLabel = "Stop Trade Mode"
    EndSwitch

    If $g_i_BotState = $GC_I_BOTSTATE_RUN And $g_b_PauseRequested Then
        $l_s_StartLabel = "Force pause now"
        $l_i_StartState = ($g_b_ForcePauseRequested ? $GUI_DISABLE : $GUI_ENABLE)
        $l_i_RenderingState = $GUI_ENABLE

    ElseIf $g_i_BotState <> $GC_I_BOTSTATE_RUN And $g_b_ResumeRequested Then
        $l_s_StartLabel = "Waiting to resume..."
        $l_s_OpenLabel  = "Open Lockboxes"
        $l_s_TradeLabel = "Trade Mode"
        $l_i_RenderingState = $GUI_ENABLE

    Else
        Switch $g_i_BotState
            Case $GC_I_BOTSTATE_RUN
                $l_s_StartLabel = "Pause"
                $l_i_StartState = $GUI_ENABLE
                $l_i_RenderingState = $GUI_ENABLE

            Case $GC_I_BOTSTATE_IDLE
                $l_s_StartLabel = "Resume"
                $l_i_StartState = $GUI_ENABLE
                $l_i_OpenState = $GUI_ENABLE
                $l_i_TradeState = ($g_b_TravelGH ? $GUI_ENABLE : $GUI_DISABLE)
                $l_i_RenderingState = $GUI_ENABLE
                $l_i_NormalModeState = $GUI_ENABLE
                $l_i_HardModeState = $GUI_ENABLE

            Case $GC_I_BOTSTATE_OPEN
                $l_s_StartLabel = "Resume"
                $l_i_StartState = $GUI_ENABLE
                $l_i_OpenState = $GUI_ENABLE
                $l_i_TradeState = ($g_b_TravelGH ? $GUI_ENABLE : $GUI_DISABLE)
                $l_i_RenderingState = $GUI_ENABLE
                $l_i_NormalModeState = $GUI_ENABLE
                $l_i_HardModeState = $GUI_ENABLE

            Case $GC_I_BOTSTATE_TRADE
                $l_s_StartLabel = "Resume"
                $l_i_StartState = $GUI_ENABLE
                $l_i_OpenState = $GUI_ENABLE
                $l_i_TradeState = $GUI_ENABLE
                $l_i_RenderingState = $GUI_ENABLE
                $l_i_NormalModeState = $GUI_ENABLE
                $l_i_HardModeState = $GUI_ENABLE

            Case $GC_I_BOTSTATE_ERROR
                $l_s_StartLabel = "Waiting for restart..."
        EndSwitch
    EndIf

    GUICtrlSetData($g_i_CtrlID_Button_Start, $l_s_StartLabel)
    GUICtrlSetData($g_i_CtrlID_Button_OpenLockboxes, $l_s_OpenLabel)
    GUICtrlSetData($g_i_CtrlID_Button_Trade, $l_s_TradeLabel)

    GUICtrlSetState($g_i_CtrlID_Button_Start, $l_i_StartState)
    GUICtrlSetState($g_i_CtrlID_Button_OpenLockboxes, $l_i_OpenState)
    GUICtrlSetState($g_i_CtrlID_Button_Trade, $l_i_TradeState)
    GUICtrlSetState($g_i_CtrlID_CBX_Rendering, $l_i_RenderingState)
    GUICtrlSetState($g_i_CtrlID_CBX_NormalMode, $l_i_NormalModeState)
    GUICtrlSetState($g_i_CtrlID_CBX_HardMode, $l_i_HardModeState)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_SetBotState
; Description....: Transitions the bot to a new state, triggers user feedback, and updates UI/flags as needed.
; Syntax.........: GUI_SetBotState($a_i_Mode)
; Parameters.....: $a_i_Mode  - One of $GC_I_BOTSTATE_* constants.
; Return values..: True if the state changed; False if the requested state equals the current state.
; Remarks........: Manages “Open Lockboxes” and “Trade Mode” announcements and leave/enter hooks, including auto-trade flags.
; Related........: AddOns_Out, GUI_BotStateRender, GUI_EnterPause, GUI_LeavePause
; ===============================================================================================================================
Func GUI_SetBotState($a_i_Mode)
    If $a_i_Mode = $g_i_BotState Then Return False

    Local $l_i_Old = $g_i_BotState
    $g_i_BotState = $a_i_Mode

    If $l_i_Old = $GC_I_BOTSTATE_OPEN And $a_i_Mode <> $GC_I_BOTSTATE_OPEN Then
        AddOns_Out("[INFO] Stopping opening of Lockboxes")
    EndIf
    If $l_i_Old = $GC_I_BOTSTATE_TRADE And $a_i_Mode <> $GC_I_BOTSTATE_TRADE Then
        AddOns_Out("[INFO] Leaving Trade Mode")
        $g_b_AutoTradeReady = False
        If $a_i_Mode = $GC_I_BOTSTATE_OPEN Or $a_i_Mode = $GC_I_BOTSTATE_IDLE Then $g_b_AutoTradeLeave = True
    EndIf
    If $l_i_Old <> $GC_I_BOTSTATE_OPEN And $a_i_Mode = $GC_I_BOTSTATE_OPEN Then
        AddOns_Out("[INFO] Opening available Lockboxes")
    EndIf
    If $l_i_Old <> $GC_I_BOTSTATE_TRADE And $a_i_Mode = $GC_I_BOTSTATE_TRADE Then
        AddOns_Out("[INFO] Entering Trade Mode")
    EndIf

    If $l_i_Old = $GC_I_BOTSTATE_RUN And $a_i_Mode = $GC_I_BOTSTATE_IDLE Then
        GUI_EnterPause()
    ElseIf ($l_i_Old = $GC_I_BOTSTATE_IDLE Or $l_i_Old = $GC_I_BOTSTATE_OPEN Or $l_i_Old = $GC_I_BOTSTATE_TRADE) _
        And $a_i_Mode = $GC_I_BOTSTATE_RUN Then
        $g_b_PauseRequested = False
        $g_b_ResumeRequested = False
        GUI_LeavePause()
    EndIf

    GUI_BotStateRender()
    Return True
EndFunc
#EndRegion GUIFunctions

#Region GUIEventHandlers
; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnStart
; Description....: Handles the Start button lifecycle:
;                  - If the bot is already running, queue a pause (after the current Quest18 finishes).
;                  - If the bot is paused/idle/other, queue a resume (after the current task finishes).
;                  - On first start, validates inputs, disables controls, starts the bot, initializes flags/hooks, updates
;                    the window title, and transitions the bot into RUN state. On failure, restores controls and logs error.
; Syntax.........: GUI_Main_OnStart ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Returns early for pause/resume queueing and on failed start paths; does not set @error.
;                  - Location dropdown: any selection other than "Guild Hall" sets $g_b_TravelGH = False for the session.
;                  - Uses GUI_StartBot()’s @error solely for logging; this function itself does not propagate @error.
;                  - Button/combobox states are toggled to prevent duplicate starts while initialization is in progress.
; Related........: AddOns_Out, GUI_BotIsRunning, GUI_BotStateRender, GUI_ModalMsgBox, GUI_RenderingCheck, GUI_SetBotState,
;                  GUI_StartBot, EnableWinEventHook, GUICtrlRead, GUICtrlSetData, GUICtrlSetState, WinSetTitle
; ===============================================================================================================================
Func GUI_Main_OnStart()
    ; Running → request normal pause, or immediately force the bot into IDLE.
    If $g_b_BotInitialized And GUI_BotIsRunning() Then
        If $g_b_PauseRequested Then
            $g_b_ForcePauseRequested = True
            $g_b_PauseRequested = False
            ; Do not call GUI_SetBotState here: GUI_EnterPause performs inventory
            ; cleanup, which can interfere with the manual Conset supply routine.
            $g_i_BotState = $GC_I_BOTSTATE_IDLE
            AddOns_Out("[WARN] Force pause activated; stopping the current run")
        Else
            $g_b_PauseRequested = True
            AddOns_Out("[INFO] Will pause after this run")
        EndIf
        GUI_BotStateRender()
        Return
    EndIf

    ; Paused/other → request resume
    If $g_b_BotInitialized And Not GUI_BotIsRunning() Then
        $g_b_ResumeRequested = True
        AddOns_Out("[INFO] Will resume after current task")
        GUI_BotStateRender()
        Return
    EndIf

    ; First start
    Local $l_s_Character = GUI_StripCharacterEnum(GUICtrlRead($g_i_CtrlID_Combo_CharInput))
    Local $l_s_Location  = GUICtrlRead($g_i_CtrlID_Combo_LocationInput)
    If $l_s_Character = "" Then
        GUI_ModalMsgBox($MB_ICONWARNING, "Warning - No Character Selected", "Please select a character.")
        Return
    EndIf

    GUICtrlSetData($g_i_CtrlID_Button_Start, "Starting bot...")

    GUICtrlSetState($g_i_CtrlID_Button_Start, $GUI_DISABLE)
    GUICtrlSetState($g_i_CtrlID_Combo_CharInput, $GUI_DISABLE)
    GUICtrlSetState($g_i_CtrlID_Combo_LocationInput, $GUI_DISABLE)
    GUICtrlSetState($g_i_CtrlID_CBX_NormalMode, $GUI_DISABLE)
    GUICtrlSetState($g_i_CtrlID_CBX_HardMode, $GUI_DISABLE)

    Sleep(10)

    If GUI_StartBot($l_s_Character) Then
        $g_b_BotInitialized = True
        $g_b_PauseRequested = False
        $g_b_ResumeRequested = False
        $g_b_AutoTradeReady = False
        $g_b_AutoTradeLeave = False
        If $l_s_Location <> "Guild Hall" Then $g_b_TravelGH = False

        EnableWinEventHook()
        WinSetTitle($g_h_MainGUI, "", "Encounter Re:Built - " & $l_s_Character)

        GUI_RenderingCheck()
        GUI_SetBotState($GC_I_BOTSTATE_RUN)
    Else
        Local $l_i_Err = @error
        AddOns_Out("[ERR] Start of bot failed (ERR:" & $l_i_Err & ")")

        GUICtrlSetData($g_i_CtrlID_Button_Start, "Start")

        GUICtrlSetState($g_i_CtrlID_Button_Start, $GUI_ENABLE)
        GUICtrlSetState($g_i_CtrlID_Combo_CharInput, $GUI_ENABLE)
        GUICtrlSetState($g_i_CtrlID_Combo_LocationInput, $GUI_ENABLE)
        GUICtrlSetState($g_i_CtrlID_CBX_NormalMode, $GUI_ENABLE)
        GUICtrlSetState($g_i_CtrlID_CBX_HardMode, $GUI_ENABLE)
    EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnOpenLockboxes
; Description....: Toggles the "Open Lockboxes" mode:
;                  - If already opening, switch to IDLE.
;                  - Otherwise enter OPEN mode.
; Syntax.........: GUI_Main_OnOpenLockboxes ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: State transitions are delegated to GUI_SetBotState(); GUI_BotStateRender() will be triggered by that path.
; Related........: GUI_BotIsOpening, GUI_SetBotState
; ===============================================================================================================================
Func GUI_Main_OnOpenLockboxes()
    If GUI_BotIsOpening() Then
        GUI_SetBotState($GC_I_BOTSTATE_IDLE)
    Else
        GUI_SetBotState($GC_I_BOTSTATE_OPEN)
    EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnTradeMode
; Description....: Toggles Trade Mode:
;                  - If already trading, switch to IDLE.
;                  - Otherwise enter TRADE mode.
; Syntax.........: GUI_Main_OnTradeMode ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Entering/leaving TRADE will prompt GUI_SetBotState() to handle any mode-specific side effects.
; Related........: GUI_BotIsTrading, GUI_SetBotState
; ===============================================================================================================================
Func GUI_Main_OnTradeMode()
    If GUI_BotIsTrading() Then
        GUI_SetBotState($GC_I_BOTSTATE_IDLE)
    Else
        GUI_SetBotState($GC_I_BOTSTATE_TRADE)
    EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnAdd
; Description....: Opens the “Add Character” dialog as a child of the main GUI.
; Syntax.........: GUI_Main_OnAdd ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Disables the main window (handled by GUI_CreateCharacterGUI) and wires OK/Cancel inside the dialog.
; Related........: GUI_CreateCharacterGUI, GUI_Character_OnConfirm_Add, GUI_Character_OnCancel
; ===============================================================================================================================
Func GUI_Main_OnAdd()
	GUI_CreateCharacterGUI("Add Character", $GC_I_CHARACTER_GUI_TYPE_ADD)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnEdit
; Description....: Builds an edit queue from the checked rows in the character ListView and opens the first edit dialog.
; Syntax.........: GUI_Main_OnEdit ( )
; Parameters.....: None
; Return values..: None (shows a warning MsgBox and returns early if nothing is checked)
; Author.........: KleuTSchi
; Remarks........: - Collects checked indices into $g_ai_EditQueue and calls GUI_ShowNextEdit().
;                  - Shows a warning if no rows are selected.
; Related........: GUI_ShowNextEdit, _GUICtrlListView_GetItemChecked, _GUICtrlListView_GetItemCount
; ===============================================================================================================================
Func GUI_Main_OnEdit()
    Local $l_i_Count_Rows = _GUICtrlListView_GetItemCount($g_h_CtrlHnd_AccountList)

    Local $l_ai_Checked[$l_i_Count_Rows], $l_i_Count_Checked = 0
    For $i = 0 To $l_i_Count_Rows - 1
        If _GUICtrlListView_GetItemChecked($g_h_CtrlHnd_AccountList, $i) Then
            $l_ai_Checked[$l_i_Count_Checked] = $i
			$l_i_Count_Checked += 1
        EndIf
    Next

	ReDim $l_ai_Checked[$l_i_Count_Checked]

    If $l_i_Count_Checked = 0 Then
        GUI_ModalMsgBox($MB_ICONWARNING, "Warning - Edit Character", _
			"Please select at least one item to edit.")
        Return
    EndIf

    $g_ai_EditQueue = $l_ai_Checked

    GUI_ShowNextEdit()
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnRemove
; Description....: Removes all checked characters from the INI after a confirmation prompt and refreshes the list.
; Syntax.........: GUI_Main_OnRemove ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Prompts the user; on confirmation, deletes each section via IniDelete and reloads the ListView.
;                  - Consider guarding INI deletes with your file mutex if multiple processes can modify the file concurrently.
; Related........: IniDelete, GUI_LoadCharacterList, _GUICtrlListView_GetItemChecked, GUI_ModalMsgBox
; ===============================================================================================================================
Func GUI_Main_OnRemove()
	Local $l_h_List = $g_h_CtrlHnd_AccountList
    Local $l_i_Count_Rows = _GUICtrlListView_GetItemCount($l_h_List)

    Local $l_ai_Checked[$l_i_Count_Rows], $l_i_Count_Checked = 0
    For $i = 0 To $l_i_Count_Rows - 1
        If _GUICtrlListView_GetItemChecked($l_h_List, $i) Then
            $l_ai_Checked[$l_i_Count_Checked] = $i
			$l_i_Count_Checked += 1
        EndIf
    Next

	ReDim $l_ai_Checked[$l_i_Count_Checked]

    If $l_i_Count_Checked = 0 Then
        GUI_ModalMsgBox($MB_ICONWARNING, "Warning - Remove Character", _
			"Please select at least one item to remove.")
        Return
    EndIf

    If GUI_ModalMsgBox($MB_YESNO + $MB_ICONWARNING, "Warning - Remove Character", _
        "Are you sure you want to remove the selected character(s)?") = 6 Then
		For $i = 1 To $l_i_Count_Checked
			Local $l_i_Row = $l_ai_Checked[$i - 1]
			Local $l_s_Character = _GUICtrlListView_GetItemText($g_h_CtrlHnd_AccountList, $l_i_Row, 1)

			IniDelete($GC_S_CHARACTERS_INI_PATH, $l_s_Character)
		Next
    EndIf

	GUI_LoadCharacterList()
	_GUICtrlListView_SetItemChecked($g_h_CtrlHnd_AccountList, -1, False)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnConfirm
; Description....: OK handler for Add/Edit dialogs. Validates input, locks the INI, writes fields (encrypting password), and advances queue.
; Syntax.........: GUI_Character_OnConfirm ( $a_i_Type )
; Parameters.....: $a_i_Type - One of:
;                                 $GC_I_CHARACTER_GUI_TYPE_ADD
;                                 $GC_I_CHARACTER_GUI_TYPE_EDIT
; Return values..: None (shows error MsgBoxes and returns early on validation/mutex failures)
; Author.........: KleuTSchi
; Remarks........: - Uses Security_AcquireFileMutex($GC_S_CHARACTERS_INI_PATH, 5000)/Security_CloseMutex() to serialize INI writes.
;                  - ADD: fails if the section already exists. EDIT: renames by deleting old section when name changed.
;                  - Writes Email, encrypted Pwd (via Security_EncryptString), and FilePath; refreshes UI and closes dialog.
;                  - In multi-edit mode, increments $g_i_QueuePos and calls GUI_ShowNextEdit() to open the next item.
; Related........: Security_AcquireFileMutex, Security_CloseMutex, Security_EncryptString, IniWrite, IniReadSection, GUI_ShowNextEdit
; ===============================================================================================================================
Func GUI_Character_OnConfirm($a_i_Type)
    Local $l_s_Character = GUICtrlRead($g_i_CtrlID_CharsInput)
    Local $l_s_Email = StringStripWS(GUICtrlRead($g_i_CtrlID_EmailInput), 8)
    Local $l_s_Pwd = GUICtrlRead($g_i_CtrlID_PwdInput)
    Local $l_s_FilePath = StringStripWS(GUICtrlRead($g_i_CtrlID_FilePathInput), 3)

    If $l_s_Character = "" Then Return GUI_ModalMsgBox($MB_ICONERROR, "Error - Add/Edit Character", "Character Name is required.")
    If $l_s_Email = "" Then Return GUI_ModalMsgBox($MB_ICONERROR, "Error - Add/Edit Character", "E-Mail is required.")
    If $l_s_Pwd = "" Then Return GUI_ModalMsgBox($MB_ICONERROR, "Error - Add/Edit Character", "Password is required.")
    If $l_s_FilePath = "" Then Return GUI_ModalMsgBox($MB_ICONERROR, "Error - Add/Edit Character", "File Path is required.")

    Local $l_i_Timeout = 5000
    Local $l_h_IniMutex = Security_AcquireFileMutex($GC_S_CHARACTERS_INI_PATH, $l_i_Timeout)
    If $l_h_IniMutex = 0 Then Return GUI_ModalMsgBox(16, "Error - Add/Edit Character", "Failed to lock character file. Please try again.")

    Switch $a_i_Type
        Case $GC_I_CHARACTER_GUI_TYPE_ADD
            IniReadSection($GC_S_CHARACTERS_INI_PATH, $l_s_Character)
            If Not @error Then GUI_ModalMsgBox($MB_ICONERROR, "Error - Add/Edit Character", "Character already exists.")
        Case $GC_I_CHARACTER_GUI_TYPE_EDIT
            If $g_s_OldCharacter <> $l_s_Character Then IniDelete($GC_S_CHARACTERS_INI_PATH, $g_s_OldCharacter)
    EndSwitch

    IniWrite($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Email", $l_s_Email)
    IniWrite($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "Pwd", Security_EncryptString($l_s_Pwd))
    IniWrite($GC_S_CHARACTERS_INI_PATH, $l_s_Character, "FilePath", $l_s_FilePath)

    Security_CloseMutex($l_h_IniMutex)

    GUI_LoadCharacterList()

    GUIDelete($g_h_CharacterGUI)
    GUI_SetModalMsgBoxGUI($g_h_MainGUI)
    GUISetState(@SW_ENABLE, $g_h_MainGUI)
    WinActivate($g_h_MainGUI)

    $g_i_QueuePos += 1
    GUI_ShowNextEdit()
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnConfirm_Add
; Description....: Thin wrapper that invokes GUI_Character_OnConfirm for the “Add” workflow.
; Syntax.........: GUI_Character_OnConfirm_Add ( )
; Parameters.....: None
; Return values..: Pass-through of GUI_Character_OnConfirm
; Author.........: KleuTSchi
; Remarks........: Keeps legacy event name while consolidating logic in GUI_Character_OnConfirm().
; Related........: GUI_Character_OnConfirm
; ===============================================================================================================================
Func GUI_Character_OnConfirm_Add()
    Return GUI_Character_OnConfirm($GC_I_CHARACTER_GUI_TYPE_ADD)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnConfirm_Edit
; Description....: Thin wrapper that invokes GUI_Character_OnConfirm for the “Edit” workflow.
; Syntax.........: GUI_Character_OnConfirm_Edit ( )
; Parameters.....: None
; Return values..: Pass-through of GUI_Character_OnConfirm
; Author.........: KleuTSchi
; Remarks........: Keeps legacy event name while consolidating logic in GUI_Character_OnConfirm().
; Related........: GUI_Character_OnConfirm
; ===============================================================================================================================
Func GUI_Character_OnConfirm_Edit()
    Return GUI_Character_OnConfirm($GC_I_CHARACTER_GUI_TYPE_EDIT)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnCancel
; Description....: Cancel/close handler for the Add/Edit dialog. Closes the dialog and moves to the next queued edit.
; Syntax.........: GUI_Character_OnCancel ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Re-enables and activates the main GUI if appropriate (handled via GUI_ShowNextEdit end-of-queue path).
; Related........: GUI_ShowNextEdit, GUIDelete, WinActivate
; ===============================================================================================================================
Func GUI_Character_OnCancel()
	GUIDelete($g_h_CharacterGUI)
    WinActivate($g_h_MainGUI)

	$g_i_QueuePos += 1
	GUI_ShowNextEdit()
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnCancelAll
; Description....: Aborts the multi-edit sequence by clearing the queue and closing the current dialog.
; Syntax.........: GUI_Character_OnCancelAll ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Unchecks all ListView items and closes the dialog; caller regains control of the main GUI.
; Related........: _GUICtrlListView_SetItemChecked, GUIDelete, GUI_SetModalMsgBoxGUI, GUISetState, WinActivate
; ===============================================================================================================================
Func GUI_Character_OnCancelAll()
    ReDim $g_ai_EditQueue[0]
    GUIDelete($g_h_CharacterGUI)

	_GUICtrlListView_SetItemChecked($g_h_CtrlHnd_AccountList, -1, False)
	GUI_SetModalMsgBoxGUI($g_h_MainGUI)
	GUISetState(@SW_ENABLE, $g_h_MainGUI)
	WinActivate($g_h_MainGUI)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnBrowse
; Description....: File-browse handler for the character dialog; fills the FilePath input with the selected Gw.exe.
; Syntax.........: GUI_Character_OnBrowse ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Uses FileOpenDialog with a filter; ignores empty/canceled selections.
; Related........: FileOpenDialog, GUICtrlSetData
; ===============================================================================================================================
Func GUI_Character_OnBrowse()
    Local $sFile = FileOpenDialog("Select Gw.exe", @ScriptDir, "Guild Wars (Gw.exe)|All Files (*.*)", 1)
    If Not @error And $sFile <> "" Then
        GUICtrlSetData($g_i_CtrlID_FilePathInput, $sFile)
    EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Character_OnShowPwd
; Description....: Toggles password visibility by recreating the input control with/without $ES_PASSWORD and re-binding the click handler.
; Syntax.........: GUI_Character_OnShowPwd ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Preserves current text, flips $g_b_PwdMasked, and reattaches the OnEvent handler to the eye button.
; Related........: GUICtrlCreateInput, GUICtrlDelete, GUICtrlSetOnEvent
; ===============================================================================================================================
Func GUI_Character_OnShowPwd()
    Local $l_s_Text = GUICtrlRead($g_i_CtrlID_PwdInput)
    GUICtrlDelete($g_i_CtrlID_PwdInput)
    If $g_b_PwdMasked Then
        $g_i_CtrlID_PwdInput = GUICtrlCreateInput($l_s_Text, 87,84,185,22)
    Else
        $g_i_CtrlID_PwdInput = GUICtrlCreateInput($l_s_Text, 87,84,185,22, BitOR($GUI_SS_DEFAULT_INPUT, $ES_PASSWORD))
    EndIf
    GUICtrlSetOnEvent($g_i_CtrlID_ShowPwdButton, "GUI_Character_OnShowPwd")
    $g_b_PwdMasked = Not $g_b_PwdMasked
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Func GUI_Main_ToggleRendering
; Description....: Toggles the rendering state of the Guild Wars window based on the checkbox.
; Syntax.........: GUI_Main_ToggleRendering ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Wraps Ui_ToggleRendering(), which enables/disables rendering in the Guild Wars client and
;                  shows/hides the game window accordingly. Also clears memory when disabling.
; Related........: GUI_RenderingCheck
; ===============================================================================================================================
Func GUI_Main_ToggleRendering()
    GUI_RenderingCheck()
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnToggleOnTop
; Description....: Toggles the main window’s “always on top” state based on the checkbox.
; Syntax.........: GUI_Main_OnToggleOnTop ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Calls WinSetOnTop with $WINDOWS_ONTOP / $WINDOWS_NOONTOP depending on the checkbox state.
; Related........: GUI_GUICtrlIsChecked, WinSetOnTop
; ===============================================================================================================================
Func GUI_Main_OnToggleOnTop()
	If GUI_GUICtrlIsChecked($g_i_CtrlID_CBX_OnTop) Then
		WinSetOnTop($g_h_MainGUI, "", $WINDOWS_ONTOP)
	Else
		WinSetOnTop($g_h_MainGUI, "", $WINDOWS_NOONTOP)
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnToggleModeNM
; Description....: Updates $g_b_HardMode.
; Syntax.........: GUI_Main_OnToggleModeNM ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Sets $g_b_HardMode = False; Radio button enforces mutual exclusivity with HM.
; Related........: AddOns_Out, GUI_Main_OnToggleModeHM
; ===============================================================================================================================
Func GUI_Main_OnToggleModeNM()
    If $g_b_HardMode = True Then
        AddOns_Out("[INFO] Game mode set to 'Normal Mode'")
		$g_b_HardMode = False
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Main_OnToggleModeHM
; Description....: Updates $g_b_HardMode.
; Syntax.........: GUI_Main_OnToggleModeHM ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Sets $g_b_HardMode = True; Radio button enforces mutual exclusivity with NM.
; Related........: AddOns_Out, GUI_Main_OnToggleModeNM
; ===============================================================================================================================
Func GUI_Main_OnToggleModeHM()
    If $g_b_HardMode = False Then
        AddOns_Out("[INFO] Game mode set to 'Hard Mode'")
		$g_b_HardMode = True
	EndIf
EndFunc
#Region GUIEventHandlers

#Region ModalMsgBox
; #GLOBALS# =====================================================================================================================
Global $g_h_ModalMsgBox_GUI = 0 ; Parent GUI handle for custom modal message boxes (0 = none)
Global $g_b_ModalMsgBox_MBActive = False ; True while a modal message box is displayed
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_SetModalMsgBoxGUI
; Description....: Registers the main GUI handle used to enforce modality for GUI_ModalMsgBox.
; Syntax.........: GUI_SetModalMsgBoxGUI ( $a_h_GUI )
; Parameters.....: $a_h_GUI  - Handle to your main GUI (from GUICreate).
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: Call this once after GUICreate() and before showing any modal message box.
; Related........: GUI_ModalMsgBox, GUI_IsModalMsgBoxActive, GUISetState
; ===============================================================================================================================
Func GUI_SetModalMsgBoxGUI($a_h_GUI)
    $g_h_ModalMsgBox_GUI = $a_h_GUI
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_ModalMsgBox
; Description....: Shows a modal MsgBox that disables the registered main GUI until closed.
; Syntax.........: GUI_ModalMsgBox ( $a_i_Flags, $a_s_Title, $a_s_Text [, $a_i_Timeout = 0 ] )
; Parameters.....: $a_i_Flags   - MsgBox flags (buttons, icon, modality, etc.).
;                  $a_s_Title   - Title text.
;                  $a_s_Text    - Message text.
;                  $a_i_Timeout - [optional] Timeout in seconds; default is 0 (no timeout).
; Return values..: Success      - MsgBox return code (e.g., IDOK, IDYES, etc.).
;                  Failure      - -1 if another modal message box is already active.
; Author.........: KleuTSchi
; Remarks........: - Disables the main GUI (set via GUI_SetModalMsgBoxGUI) while the MsgBox is visible, then re-enables and re-activates it.
;                  - Designed for OnEvent mode to prevent user interaction with the GUI during the message.
;                  - To avoid re-entrancy (stacked MsgBoxes from hotkeys/tray/timers), this function early-returns -1 if one is active.
; Related........: GUI_SetModalMsgBoxGUI, GUI_IsModalMsgBoxActive, MsgBox, GUISetState, WinActivate
; ===============================================================================================================================
Func GUI_ModalMsgBox($a_i_Flags, $a_s_Title, $a_s_Text, $a_i_Timeout = 0)
    If $g_b_ModalMsgBox_MBActive Then Return -1
    $g_b_ModalMsgBox_MBActive = True

    If $g_h_ModalMsgBox_GUI Then GUISetState(@SW_DISABLE, $g_h_ModalMsgBox_GUI)

    Local $l_i_Result = MsgBox($a_i_Flags, $a_s_Title, $a_s_Text, $a_i_Timeout)

    If $g_h_ModalMsgBox_GUI Then
        GUISetState(@SW_ENABLE, $g_h_ModalMsgBox_GUI)
        WinActivate($g_h_ModalMsgBox_GUI)
    EndIf

    $g_b_ModalMsgBox_MBActive = False
    Return $l_i_Result
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_IsModalMsgBoxActive
; Description....: Indicates whether a modal message box shown via GUI_ModalMsgBox is currently active.
; Syntax.........: GUI_IsModalMsgBoxActive ( )
; Parameters.....: None
; Return values..: True  - A modal message box is active.
;                  False - No modal message box is active.
; Author.........: KleuTSchi
; Remarks........: Useful to short-circuit GUI or hotkey event handlers during modal dialogs.
; Related........: GUI_ModalMsgBox, GUI_SetModalMsgBoxGUI
; ===============================================================================================================================
Func GUI_IsModalMsgBoxActive()
    Return $g_b_ModalMsgBox_MBActive
EndFunc
#EndRegion ModalMsgBox

#Region LoadSettings
; #FUNCTION# ====================================================================================================================
; Name...........: GUI_LoadGUISettingsFromINI
; Description....: Loads GUI-related settings from an INI file and updates global variables controlling account / character
;                  list sorting behaviour.
; Syntax.........: GUI_LoadGUISettingsFromINI ( $a_s_IniPath )
; Parameters.....: $a_s_IniPath - Full path to the INI file to read.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> INI file not found
;                            2 -> Failed to acquire file mutex within timeout
; Author.........: KleuTSchi
; Remarks........: - Uses a file mutex to avoid concurrent access while reading.
;                  - Reads GUI sorting settings from the [GUI] section:
;                      * AccSorting  -> stored in $g_i_AccSorting (sorting mode for the account list).
;                      * CharSorting -> stored in $g_i_CharSorting (sorting mode for the character list).
;                    Both keys default to "1" if missing, meaning the ascending sort mode is used.
;                  - Only reads and assigns values; it does not directly trigger any GUI refresh or re-sorting. The caller or
;                    GUI initialisation code is expected to apply these settings to the relevant controls.
;                  - Always releases the file mutex before returning.
; Related........: Security_AcquireFileMutex, Security_CloseMutex, FileExists, IniRead
; ===============================================================================================================================
Func GUI_LoadGUISettingsFromINI($a_s_IniPath)
    If Not FileExists($a_s_IniPath) Then Return SetError(1, 0, False)

    Local $l_i_Timeout = 5000
    Local $l_h_IniMutex = Security_AcquireFileMutex($a_s_IniPath, $l_i_Timeout)
    If $l_h_IniMutex = 0 Then Return SetError(2, 0, False)

    $g_i_AccSorting = IniRead($a_s_IniPath, "GUI", "AccSorting", "1")
    $g_i_CharSorting = IniRead($a_s_IniPath, "GUI", "CharSorting", "1")

    Security_CloseMutex($l_h_IniMutex)

    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: GUI_LoadBotSettingsFromINI
; Description....: Loads bot settings from INI file, sets checkboxe states, and triggers the appropriate
;                  toggle handlers where necessary to keep internal state in sync with the UI.
; Syntax.........: GUI_LoadBotSettingsFromINI ( $a_s_IniPath )
; Parameters.....: $a_s_IniPath - Full path to the INI file to read.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> INI file not found
;                            2 -> Failed to acquire file mutex within timeout
; Author.........: KleuTSchi
; Remarks........: - Uses a file mutex to avoid concurrent access while reading.
;                  - Rendering checkbox is set based on [General]::Rendering (1=rendering enabled → checkbox unchecked).
;                  - Game mode is read from [General]::Mode (0=Normal, 1=Hard) and the corresponding toggle handler is called.
;                  - Validates single-choice sections:
;                      * [ExcMC]::ItemMC in {1..3} → Guards / Seals / Lockboxes.
;                      * [ExcGold]::ItemGold in {1..3} → Ectos / Obbys / Lockpicks.
;                    When switching selection, it checks the current state, sets the checkbox if needed, and calls the matching
;                    GUI_Main_OnToggle* handler to keep logic consistent.
;                  - Applies per-bag toggles from [Bags]::Bag1..Bag4 (1=checked, 0=unchecked).
;                  - Applies loot toggles from [LootGeneral] and [LootEvent].
;                  - Applies trading toggles from [TradeWoC] and [TradeGeneral].
;                  - Always releases the file mutex before returning.
; Related........: AddOns_Out, Security_AcquireFileMutex, Security_CloseMutex, FileExists, GUICtrlRead, GUICtrlSetState, IniRead
; ===============================================================================================================================
Func GUI_LoadBotSettingsFromINI($a_s_IniPath)
    If Not FileExists($a_s_IniPath) Then Return SetError(1, 0, False)
    AddOns_Out("[INFO] Loading settings from INI file: " & $a_s_IniPath)

    Local $l_i_Timeout = 5000
    Local $l_h_IniMutex = Security_AcquireFileMutex($a_s_IniPath, $l_i_Timeout)
    If $l_h_IniMutex = 0 Then Return SetError(2, 0, False)

    Local $l_i_LocationIdx = IniRead($a_s_IniPath, "General", "Location", "0")
    Local $l_s_Location = ($l_i_LocationIdx = 1) ? "Kaineng Center" : "Guild Hall"
    GUICtrlSetData($g_i_CtrlID_Combo_LocationInput, $l_s_Location)

    AddOns_Out("[INFO] Rendering settings will take effect after the game has been started")
    GUICtrlSetState($g_i_CtrlID_CBX_Rendering, IniRead($a_s_IniPath, "General", "Rendering", "1") = 1 ? $GUI_UNCHECKED : $GUI_CHECKED)

    If IniRead($a_s_IniPath, "General", "Mode", "1") = 1 Then
        GUICtrlSetState($g_i_CtrlID_CBX_HardMode, $GUI_CHECKED)
        AddOns_Out("[INFO] Game mode set to 'Hard Mode'")
		$g_b_HardMode = True
    Else
        GUICtrlSetState($g_i_CtrlID_CBX_NormalMode, $GUI_CHECKED)
        AddOns_Out("[INFO] Game mode set to 'Normal Mode'")
		$g_b_HardMode = False
    EndIf

    GUICtrlSetState($g_i_CtrlID_CBX_UseBag1, IniRead($a_s_IniPath, "Bags", "Bag1", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_UseBag2, IniRead($a_s_IniPath, "Bags", "Bag2", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_UseBag3, IniRead($a_s_IniPath, "Bags", "Bag3", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_UseBag4, IniRead($a_s_IniPath, "Bags", "Bag4", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)

    Local $l_i_ExchangeMC = IniRead($a_s_IniPath, "ExcMC", "ItemMC", "1")
    If $l_i_ExchangeMC < 1 Or $l_i_ExchangeMC > 3 Then $l_i_ExchangeMC = 1

    Switch $l_i_ExchangeMC
        Case 1 ; Guards
            GUICtrlSetState($g_i_CtrlID_CBX_ExchangeGuard, $GUI_CHECKED)
        Case 2 ; Seals
            GUICtrlSetState($g_i_CtrlID_CBX_ExchangeSeal, $GUI_CHECKED)
        Case 3 ; Lockboxes
            GUICtrlSetState($g_i_CtrlID_CBX_ExchangeLockbox, $GUI_CHECKED)
    EndSwitch

    Local $l_i_ExchangeGold = IniRead($a_s_IniPath, "ExcGold", "ItemGold", "1")
    If $l_i_ExchangeGold < 1 Or $l_i_ExchangeGold > 3 Then $l_i_ExchangeGold = 1

    Switch $l_i_ExchangeGold
        Case 1 ; Ectos
            GUICtrlSetState($g_i_CtrlID_CBX_ExchangeEcto, $GUI_CHECKED)
        Case 2 ; Obbys
            GUICtrlSetState($g_i_CtrlID_CBX_ExchangeObby, $GUI_CHECKED)
        Case 3 ; Lockpicks
            GUICtrlSetState($g_i_CtrlID_CBX_ExchangeLP, $GUI_CHECKED)
    EndSwitch

    ; LootGeneral
    GUICtrlSetState($g_i_CtrlID_CBX_LootLP, IniRead($a_s_IniPath, "LootGeneral", "Lockpicks", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_LootBD, IniRead($a_s_IniPath, "LootGeneral", "BlackDyes", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_LootTome, IniRead($a_s_IniPath, "LootGeneral", "Tomes", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)

    ; LootEvent
    GUICtrlSetState($g_i_CtrlID_CBX_LootPCon, IniRead($a_s_IniPath, "LootEvent", "PCons", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_LootEventToken, IniRead($a_s_IniPath, "LootEvent", "EventTokens", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_LootTPItem, IniRead($a_s_IniPath, "LootEvent", "TPItems", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)

    ; TradeWoC
    GUICtrlSetState($g_i_CtrlID_CBX_TradeGuard, IniRead($a_s_IniPath, "TradeWoC", "Guards", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeSeal, IniRead($a_s_IniPath, "TradeWoC", "Seals", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeTengu, IniRead($a_s_IniPath, "TradeWoC", "Tengu", "1") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeMC, IniRead($a_s_IniPath, "TradeWoC", "MC", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)

    ; TradeGeneral
    GUICtrlSetState($g_i_CtrlID_CBX_TradeEcto, IniRead($a_s_IniPath, "TradeGeneral", "Ectos", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeObby, IniRead($a_s_IniPath, "TradeGeneral", "Obbys", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeLP, IniRead($a_s_IniPath, "TradeGeneral", "Lockpicks", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeBD, IniRead($a_s_IniPath, "TradeGeneral", "BlackDyes", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeTome, IniRead($a_s_IniPath, "TradeGeneral", "Tomes", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradePCon, IniRead($a_s_IniPath, "TradeGeneral", "PCons", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeEventToken, IniRead($a_s_IniPath, "TradeGeneral", "EventTokens", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeIcedTea, IniRead($a_s_IniPath, "TradeGeneral", "IcedTeas", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeDCake, IniRead($a_s_IniPath, "TradeGeneral", "DCakes", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeBeacon, IniRead($a_s_IniPath, "TradeGeneral", "Beacons", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($g_i_CtrlID_CBX_TradeTPItem, IniRead($a_s_IniPath, "TradeGeneral", "TPItems", "0") = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)

    Security_CloseMutex($l_h_IniMutex)

    Return True
EndFunc
#EndRegion LoadSettings

#Region Cleanup
; #FUNCTION# ====================================================================================================================
; Name...........: GUI_Cleanup
; Description....: One-shot shutdown routine that tears down hooks, terminates the GW process (if running), releases
;                  launcher resources, closes logging, and shuts down the Crypt UDF.
; Syntax.........: GUI_Cleanup ( )
; Parameters.....: None
; Return values..: None
; Author.........: KleuTSchi
; Remarks........: - Idempotent: guarded by $g_b_CleanupDone to ensure the sequence runs at most once.
;                  - Safe to call even if some resources were never initialized; existence/guard checks prevent errors.
;                  - Intended for application exit paths and fatal error recovery; does not set @error.
; Related........: DisableWinEventHook, ProcessExists, ProcessClose, Launch_ReleaseGridSlot,
;                  AddOns_CloseLog, _Crypt_Shutdown
; ===============================================================================================================================
Func GUI_Cleanup()
    If $g_b_CleanupDone Then Return
    $g_b_CleanupDone = True

    DisableWinEventHook()
    If ProcessExists($g_i_GWProcessId) Then ProcessClose($g_i_GWProcessId)
    Launch_ReleaseGridSlot($g_i_GridAllocatedSlot)
    AddOns_CloseLog()
    _Crypt_Shutdown()
EndFunc
#EndRegion Cleanup