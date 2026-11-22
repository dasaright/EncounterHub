#include-once
#cs ==============================================================================================================================
	Fiber farm for Encounter Re:Built (selected per character by Encounter Hub's Farm column).

	Ported from gw-suite fiber.au3 (Blake) and lib_res_scrolls.au3:
	  - Ranger (R/A) + Pyre Fierceshot farm Dragon Moss in Drazach Thicket from Saint Anjeka's Shrine.
	    The character needs the quest "A New Escort" in its quest log.
	  - Once the stored fiber (bags + storage + material storage) reaches [Fiber] Threshold in
	    Config\supply.ini (default 6500), it travels to Embark Beach, buys the bones that are missing
	    to match the fiber (stored bones are used first), crafts Scrolls of Resurrection at Alcus
	    Nailbiter with the same trader/crafter routines as the Buy Cons supply run, stores everything
	    and resumes. Bones are bought and crafted in rounds sized to the free bag slots, so they never
	    need storage space.
	  - The global Buy Cons gold trigger (Supply_CheckRequests) runs after every fiber run, exactly as
	    it does after every Ministerial run.

	Config\farms.ini (written by Encounter Hub):
	    [Farms]
	    <character name>=Fiber | Ministerial
#ce ==============================================================================================================================

Global Const $GC_S_FARM_INI = @ScriptDir & "\Config\farms.ini"

Global Const $GC_I_FIBER_OUTPOST = $GC_I_MAP_ID_SAINT_ANJEKAS_SHRINE
Global Const $GC_I_FIBER_EXPLORABLE = $GC_I_MAP_ID_DRAZACH_THICKET
Global Const $GC_S_FIBER_BUILD_PLAYER = "OgcTcZ88ZSgZCSn5AiVK0R4wtEA"
Global Const $GC_S_FIBER_BUILD_PYRE = "OgcTcZ885ZCG6eObHAAAAAAAAA"
Global Const $GC_I_FIBER_SALVAGE_KITS = 3      ; kept in the bags (dragon roots / spiritwood are salvaged during runs)
Global Const $GC_I_FIBER_FREE_SLOTS_MIN = 5     ; clean up the inventory at or below this many free slots
Global Const $GC_I_FIBER_PYRE = 1               ; hero number of Pyre Fierceshot

; Player skill slots (build above)
Global Const $GC_I_FIBER_SKILL_RETURN = 1
Global Const $GC_I_FIBER_SKILL_DASH = 2
Global Const $GC_I_FIBER_SKILL_SHADOW_FORM = 3
Global Const $GC_I_FIBER_SKILL_SHROUD = 4
Global Const $GC_I_FIBER_SKILL_ZOJUNS = 5
Global Const $GC_I_FIBER_SKILL_SHADOW_HASTE = 6
Global Const $GC_I_FIBER_SKILL_WHIRLING = 7
Global Const $GC_I_FIBER_SKILL_RADIANT = 8

Global $g_b_FiberScrollsDisabled = False
Global $g_i_FiberScrollsCrafted = 0

#Region Farm selection and settings
Func Farm_Name()
	Local $l_s_Farm = IniRead($GC_S_FARM_INI, "Farms", Supply_CharacterName(), "Ministerial")
	If StringLower($l_s_Farm) = "fiber" Then Return "Fiber"
	Return "Ministerial"
EndFunc

Func Farm_IsFiber()
	Return Farm_Name() = "Fiber"
EndFunc

; Setup function for the selected farm (start, restart, resume).
Func Farm_SetupFunc()
	If Farm_IsFiber() Then Return "Fiber_Setup"
	Return "SetupEncounter"
EndFunc

Func Fiber_Setting($a_s_Key, $a_v_Default)
	Return IniRead(Supply_ConfigPath(), "Fiber", $a_s_Key, $a_v_Default)
EndFunc

Func Fiber_Threshold()
	Local $l_i_Value = Int(Fiber_Setting("Threshold", "6500"))
	If $l_i_Value < 25 Then $l_i_Value = 6500
	Return $l_i_Value
EndFunc

Func Fiber_GoldReserve()
	Return _Max(0, Int(Fiber_Setting("GoldReserve", "30000")))
EndFunc

Func Fiber_ScrollsEnabled()
	Return StringLower(Fiber_Setting("CraftScrolls", "true")) <> "false"
EndFunc
#EndRegion Farm selection and settings

#Region Setup
; Party, builds and hard mode, then the resign spot. Called at start, after a restart and on resume.
Func Fiber_Setup()
	Local $l_i_Ping = Other_GetPing()
	Friend_SetOfflineStatus()
	Sleep(500 + $l_i_Ping)

	If Map_GetMapID() <> $GC_I_FIBER_OUTPOST Then
		AddOns_Out("[FIBER] Travelling to Saint Anjeka's Shrine")
		If Not HeartbeatTravel($GC_I_FIBER_OUTPOST) Then Return SetError(1, 0, False)
	EndIf

	Ui_LeaveGroup()
	Sleep(500 + $l_i_Ping)
	Local $l_ai_Heroes[1] = [$GC_I_HERO_ID_PYRE_FIERCESHOT]
	AddOns_AddHeroes($l_ai_Heroes)
	Sleep(500 + $l_i_Ping)

	AddOns_Out("[FIBER] Loading skillbars")
	Attribute_LoadSkillTemplate($GC_S_FIBER_BUILD_PLAYER)
	Sleep(300 + $l_i_Ping)
	Attribute_LoadSkillTemplate($GC_S_FIBER_BUILD_PYRE, $GC_I_FIBER_PYRE)
	Sleep(300 + $l_i_Ping)
	AddOns_DisableHeroSkillbar($GC_I_FIBER_PYRE) ; Pyre's skills are used on command only

	Ui_SetDifficulty(True)
	Sleep(500 + $l_i_Ping)

	Return Fiber_SetUpFastWay()
EndFunc

; Zone into Drazach Thicket and straight back, so that resigning returns next to the portal.
Func Fiber_SetUpFastWay()
	AddOns_Out("[FIBER] Setting up resign")
	AddOns_MoveTo(-11336, -22580)
	If Not Fiber_Zone(-11209, -23100, $GC_I_FIBER_EXPLORABLE) Then Return SetError(2, 0, False)
	Skill_UseSkill($GC_I_FIBER_SKILL_DASH)
	If Not Fiber_Zone(-11438, 20540, $GC_I_FIBER_OUTPOST) Then Return SetError(3, 0, False)
	Return True
EndFunc

Func Fiber_Zone($a_f_X, $a_f_Y, $a_i_MapID)
	Map_InitMapIsLoaded()
	Map_Move($a_f_X, $a_f_Y, 0)
	Local $l_h_Timer = TimerInit()
	While Map_GetMapID() <> $a_i_MapID And TimerDiff($l_h_Timer) < 30000
		Sleep(250)
		If Not AddOns_GetIsMoving(-2) And Map_GetMapID() <> $a_i_MapID Then Map_Move($a_f_X, $a_f_Y, 0)
	WEnd
	If Map_GetMapID() <> $a_i_MapID Then
		AddOns_Out("[ERR] Fiber zoning timed out (map " & Map_GetMapID() & ")")
		Return False
	EndIf
	Map_WaitMapLoading($a_i_MapID)
	Return IsAlive("Fiber zoning")
EndFunc
#EndRegion Setup

#Region Run
; One farm cycle: outpost housekeeping (inventory, scroll crafting), then one run.
Func Fiber_Main()
	AddOns_PurgeHook()

	If Map_GetMapID() <> $GC_I_FIBER_OUTPOST Then
		; e.g. after a Buy Cons supply run or a scroll trip
		If Not HeartbeatStep("Fiber_Setup", "Fiber_Setup") Then
			If Quest18_ForcePauseReturn() Then Return True
			Return SetError(1, 0, False)
		EndIf
	EndIf
	If Quest18_ForcePauseReturn() Then Return True

	Fiber_StoreMaterials()

	If Fiber_NeedsInventory() Then
		If Not HeartbeatStep("Fiber_Inventory", "Fiber_Inventory") Then
			If Quest18_ForcePauseReturn() Then Return True
			Return SetError(1, 0, False)
		EndIf
		If Not HeartbeatStep("Fiber_Setup", "Fiber_Setup") Then Return SetError(1, 0, False)
	EndIf
	If Quest18_ForcePauseReturn() Then Return True

	If Fiber_ScrollsDue() Then
		If Not HeartbeatStep("Fiber_CraftScrolls", "Fiber_CraftScrolls") Then
			If Quest18_ForcePauseReturn() Then Return True
			Return SetError(1, 0, False)
		EndIf
		If Not HeartbeatStep("Fiber_Setup", "Fiber_Setup") Then Return SetError(1, 0, False)
	EndIf
	If Quest18_ForcePauseReturn() Then Return True

	AddOns_Out("[FIBER] Starting run #" & ($g_i_Count_Runs + 1))
	If Not Fiber_Zone(-11209, -23100, $GC_I_FIBER_EXPLORABLE) Then Return SetError(2, 0, False)

	$g_h_Runtime = TimerInit()
	Local $l_b_Success = Fiber_Combat()
	$g_i_Count_Runs += 1
	If Not $l_b_Success Then
		$g_i_Count_Fails += 1
		AddOns_Out("[WARN] Fiber run failed")
	EndIf

	Fiber_ResignAndReturn()
	Return True
EndFunc

Func Fiber_ResignAndReturn()
	If Map_GetMapID() <> $GC_I_FIBER_EXPLORABLE Then Return True
	Chat_SendChat("resign", "/")
	Local $l_h_Timer = TimerInit()
	Do
		Sleep(100)
	Until Party_GetPartyContextInfo("IsDefeated") Or TimerDiff($l_h_Timer) > 5000
	Other_PingSleep(1000)
	Map_ReturnToOutpost()
	Map_WaitMapLoading($GC_I_FIBER_OUTPOST)
	Return IsAlive("Fiber resign")
EndFunc

; Movement with Dash / Zojun's Haste like gw-suite MoveRun.
Func Fiber_MoveRun($a_f_X, $a_f_Y, $a_b_UseDash = False, $a_b_UseZojuns = False)
	If AddOns_GetIsDead(-2) Or Map_GetMapID() <> $GC_I_FIBER_EXPLORABLE Then Return False
	Local $l_i_Blocked = 0
	Map_Move($a_f_X, $a_f_Y, 0)
	Fiber_SalvageOne()
	Do
		Other_PingSleep(200)
		If AddOns_GetIsDead(-2) Or Map_GetMapID() <> $GC_I_FIBER_EXPLORABLE Then Return False
		If $a_b_UseDash And AddOns_GetIsRecharged($GC_I_FIBER_SKILL_DASH) Then
			AddOns_UseSkillEx($GC_I_FIBER_SKILL_DASH)
		ElseIf $a_b_UseZojuns And AddOns_GetIsRecharged($GC_I_FIBER_SKILL_ZOJUNS) _
				And Not AddOns_GetHasEffect($GC_I_SKILL_ID_DASH) And Not AddOns_GetHasEffect($GC_I_SKILL_ID_ZOJUNS_HASTE) Then
			AddOns_UseSkillEx($GC_I_FIBER_SKILL_ZOJUNS)
		EndIf
		If Not AddOns_GetIsMoving(-2) Then
			Map_Move($a_f_X, $a_f_Y, 0)
			$l_i_Blocked += 1
		Else
			$l_i_Blocked = 0
		EndIf
	Until AddOns_GetDistanceToXY($a_f_X, $a_f_Y) < 250 Or $l_i_Blocked > 10
	Return True
EndFunc

; The Dragon Moss route from gw-suite fiber.au3. Returns True when the character survived.
Func Fiber_Combat()
	If Map_GetMapID() <> $GC_I_FIBER_EXPLORABLE Then Return False

	Skill_UseHeroSkill($GC_I_FIBER_PYRE, 4) ; Quickening Zephyr
	Skill_UseHeroSkill($GC_I_FIBER_PYRE, 2) ; Shadow of Haste
	Skill_UseSkill($GC_I_FIBER_SKILL_DASH)
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_RETURN, AddOns_GetNearestAgent_NPCLiving(-2, -1, True, -8440, 18389))
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_SHROUD)
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_SHADOW_FORM)
	Party_CommandHero($GC_I_FIBER_PYRE, -7924, 18281)

	Fiber_MoveRun(-7086, 17979, True)
	Fiber_MoveRun(-6423, 17012, False, True)
	Fiber_MoveRun(-5404, 15538, False, True) ; far point

	Skill_UseHeroSkill($GC_I_FIBER_PYRE, 3) ; Winnowing

	Fiber_MoveRun(-6111, 17160)
	AddOns_MoveTo(-6111, 17160) ; Shadow of Haste spot
	Sleep(500)
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_SHADOW_HASTE)
	Fiber_MoveRun(-6604, 18585)
	AddOns_MoveTo(-6604, 18585) ; cancels Shadow of Haste

	Skill_UseHeroSkill($GC_I_FIBER_PYRE, 1) ; Dash
	Party_CommandHero($GC_I_FIBER_PYRE, -11329, 19792)

	Local $l_h_Deadlock = TimerInit()
	Do
		Sleep(100)
	Until AddOns_GetIsRecharged($GC_I_FIBER_SKILL_SHADOW_FORM) Or AddOns_GetIsDead(-2) Or TimerDiff($l_h_Deadlock) > 30000
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_SHADOW_FORM)
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_WHIRLING)

	$l_h_Deadlock = TimerInit()
	Do
		Sleep(250)
		If AddOns_GetIsDead(-2) Then ExitLoop
	Until AddOns_GetCurrentEnergy(-2) > 15 Or TimerDiff($l_h_Deadlock) > 5000
	AddOns_UseSkillEx($GC_I_FIBER_SKILL_RADIANT)

	; Wait for the balled-up moss to die, salvaging roots while waiting.
	$l_h_Deadlock = TimerInit()
	Do
		If AddOns_GetIsDead(-2) Or Not IsAlive("Fiber_Combat") Then ExitLoop
		If Not Fiber_SalvageOne() Then Sleep(500)
	Until AddOns_GetNumberOfAgent_EnemyLiving_NoSM(-2, 156) = 0 Or TimerDiff($l_h_Deadlock) > 20000

	If AddOns_GetIsDead(-2) Then
		AddOns_Out("[FIBER] Died")
		Return False
	EndIf
	AddOns_Out("[FIBER] Looting")
	Sleep(500)
	PickUpLoot(1000)
	Return True
EndFunc

; Extra pickups for the fiber farm (CreatePickupSet adds these when the Fiber farm is selected).
Func Fiber_AddPickups(ByRef $a_m_PickUpSet)
	Local $l_ai_Models[] = [$GC_I_MODELID_PLANT_FIBRES, $GC_I_MODELID_DRAGON_ROOT, $GC_I_MODELID_SPIRITWOOD_PLANK, _
		$GC_I_MODELID_MONSTROUS_EYE, $GC_I_MODELID_MONSTROUS_CLAW, $GC_I_MODELID_MONSTROUS_FANG, _
		$GC_I_MODELID_RUBY, $GC_I_MODELID_SAPPHIRE, $GC_I_MODELID_DIAMOND, $GC_I_MODELID_LOCKPICK]
	For $i = 0 To UBound($l_ai_Models) - 1
		If MapExists($a_m_PickUpSet, $l_ai_Models[$i]) Then ContinueLoop
		$a_m_PickUpSet[$l_ai_Models[$i]] = BitOR(BitShift($GC_I_STATISTICS_TRACKER_NONE, -16), BitAND($GC_I_EXTRAID_ANY, 0xFFFF))
	Next
EndFunc
#EndRegion Run

#Region Inventory
; Salvage one dragon root or spiritwood plank (for fiber). Returns True when something was salvaged.
Func Fiber_SalvageOne()
	If Supply_BagCount($GC_I_MODELID_SALVAGE_KIT) = 0 Then Return False
	Local $l_av2_Inv = Item_GetInventoryArray()
	For $i = 0 To UBound($l_av2_Inv, $UBOUND_ROWS) - 1
		Local $l_i_Model = $l_av2_Inv[$i][$GC_I_INVENTORY_MODELID]
		If $l_i_Model <> $GC_I_MODELID_DRAGON_ROOT And $l_i_Model <> $GC_I_MODELID_SPIRITWOOD_PLANK Then ContinueLoop
		If Not Item_SalvageItem($l_av2_Inv[$i][$GC_I_INVENTORY_ITEMID], "Standard", "Materials") Then Return False
		Other_PingSleep(600)
		Return True
	Next
	Return False
EndFunc

; Full material stacks to the material tab (then storage) after every run.
Func Fiber_StoreMaterials()
	Local $l_ai_Models[] = [$GC_I_MODELID_PLANT_FIBRES, $GC_I_MODELID_IRON, $GC_I_MODELID_DUST, $GC_I_MODELID_BONES, $GC_I_MODELID_GRANITE]
	For $i = 0 To UBound($l_ai_Models) - 1
		If Supply_BagCount($l_ai_Models[$i]) < 250 Then ContinueLoop
		Supply_DepositMatStorage($l_ai_Models[$i])
		If Supply_BagCount($l_ai_Models[$i]) >= 250 Then AddOns_DepositItemsToStorage($l_ai_Models[$i], -1, 1, True, False)
	Next
	If Supply_BagCount($GC_I_MODELID_LOCKPICK) > 0 Then AddOns_DepositItemsToStorage($GC_I_MODELID_LOCKPICK, -1, -1, True, False)
EndFunc

Func Fiber_NeedsInventory()
	If AddOns_GetEmptyInventorySlotCount() <= $GC_I_FIBER_FREE_SLOTS_MIN Then Return True
	Return Supply_BagCount($GC_I_MODELID_SALVAGE_KIT) = 0
EndFunc

; Identify / sell / store with the bot's normal rules, then top up salvage kits at the same merchant.
Func Fiber_Inventory()
	AddOns_Out("[FIBER] Inventory clean-up")
	Inventory(True)
	Local $l_i_Map = Map_GetMapID()
	If Supply_BagCount($GC_I_MODELID_SALVAGE_KIT) < $GC_I_FIBER_SALVAGE_KITS Then
		If Pathing_GoMerchant($l_i_Map) Then
			Local $l_i_Tries = 0
			While Supply_BagCount($GC_I_MODELID_SALVAGE_KIT) < $GC_I_FIBER_SALVAGE_KITS And $l_i_Tries < $GC_I_FIBER_SALVAGE_KITS + 2
				$l_i_Tries += 1
				If AddOns_GetEmptyInventorySlotCount() < 2 Then ExitLoop
				Supply_KeepGold(500)
				Local $l_i_Before = Supply_BagCount($GC_I_MODELID_SALVAGE_KIT)
				If Not Merchant_BuyItem($GC_I_MODELID_SALVAGE_KIT, 1) Then ExitLoop
				Local $l_h_Timer = TimerInit()
				While Supply_BagCount($GC_I_MODELID_SALVAGE_KIT) <= $l_i_Before And TimerDiff($l_h_Timer) < 2000
					Sleep(50)
				WEnd
			WEnd
			AddOns_Out("[FIBER] Salvage kits: " & Supply_BagCount($GC_I_MODELID_SALVAGE_KIT))
		EndIf
	EndIf
	Return True
EndFunc
#EndRegion Inventory

#Region Res Scrolls
Func Fiber_ScrollsDue()
	If $g_b_FiberScrollsDisabled Or Not Fiber_ScrollsEnabled() Then Return False
	Return Supply_MatOwned(1) >= Fiber_Threshold()
EndFunc

Func Fiber_ScrollCost($a_i_Scrolls, $a_i_Bones, $a_i_LotPrice)
	Local $l_i_Missing = $a_i_Scrolls * 25 - $a_i_Bones
	Local $l_i_Cost = $a_i_Scrolls * $GC_I_SUPPLY_CRAFT_FEE
	If $l_i_Missing > 0 Then $l_i_Cost += Ceiling($l_i_Missing / $GC_I_SUPPLY_TRADER_LOT) * $a_i_LotPrice
	Return $l_i_Cost
EndFunc

; Embark Beach: buy the missing bones at Shad, craft scrolls at Alcus Nailbiter, store everything.
Func Fiber_CraftScrolls()
	Local $l_i_Fiber = Supply_MatOwned(1), $l_i_Bones = Supply_MatOwned(0)
	AddOns_Out("[FIBER] Res Scrolls: " & $l_i_Fiber & " fiber, " & $l_i_Bones & " bones stored")
	AddOns_Out("[FIBER] Travelling to Embark Beach")
	If Not Map_TravelTo($GC_I_SUPPLY_EMBARK, 0, 0, 0, True) Then Return SetError(1, 0, False)
	Sleep(1000)

	; 1. Plan from the live bones price and total gold (bank + carried).
	Local $l_i_Scrolls = Floor($l_i_Fiber / 25)
	If Not Supply_Talk("Shad") Then Return SetError(2, 0, False)
	Local $l_i_Price = Supply_QuoteBuy($GC_I_MODELID_BONES)
	If $l_i_Price <= 0 And Supply_Talk("Shad") Then $l_i_Price = Supply_QuoteBuy($GC_I_MODELID_BONES)
	If $l_i_Price > 0 Then
		Supply_PublishPrices($l_i_Price, 0, 0, 0, 0, 0)
	Else
		AddOns_Out("[FIBER] Shad has no bones quote; crafting from stored bones only")
		$l_i_Scrolls = _Min($l_i_Scrolls, Floor($l_i_Bones / 25))
		$l_i_Price = 1000000000
	EndIf
	Local $l_i_Reserve = Fiber_GoldReserve()
	Local $l_i_Budget = Item_GetInventoryInfo("GoldCharacter") + Item_GetInventoryInfo("GoldStorage") - $l_i_Reserve
	If Fiber_ScrollCost($l_i_Scrolls, $l_i_Bones, $l_i_Price) > $l_i_Budget Then
		Local $l_i_Afford = 0
		While $l_i_Afford < $l_i_Scrolls And Fiber_ScrollCost($l_i_Afford + 1, $l_i_Bones, $l_i_Price) <= $l_i_Budget
			$l_i_Afford += 1
		WEnd
		$l_i_Scrolls = Floor($l_i_Afford * $GC_F_SUPPLY_TARGET_SHARE)
		AddOns_Out("[FIBER] Gold limits this trip to " & $l_i_Scrolls & " scrolls")
	EndIf
	AddOns_Out("[FIBER] Plan: " & $l_i_Scrolls & " scrolls, " & _Max(0, $l_i_Scrolls * 25 - $l_i_Bones) & " bones to buy" & _
		($l_i_Price < 1000000000 ? " at " & $l_i_Price & "g/10" : ""))

	; 2. Rounds sized to free bag slots: stored bones in, buy the rest, craft (Supply_CraftBulk
	;    withdraws the fiber batch by batch).
	Local $l_i_Made = 0
	While $l_i_Made < $l_i_Scrolls
		; bones need 1 slot per 10 scrolls; keep 4 for a fiber batch, 1 for scrolls, 1 spare
		Local $l_i_Round = _Min($l_i_Scrolls - $l_i_Made, (AddOns_GetEmptyInventorySlotCount() - 6) * 10)
		If $l_i_Round <= 0 Then
			AddOns_Out("[FIBER] Not enough free bag slots for another round")
			ExitLoop
		EndIf
		Local $l_i_Need = $l_i_Round * 25
		Supply_WithdrawMat($GC_I_MODELID_BONES, $l_i_Need - Supply_BagCount($GC_I_MODELID_BONES))
		Local $l_i_Short = $l_i_Need - Supply_BagCount($GC_I_MODELID_BONES)
		If $l_i_Short > 0 Then
			If Not Supply_Talk("Shad") Then ExitLoop
			Local $l_i_Lots = Ceiling($l_i_Short / $GC_I_SUPPLY_TRADER_LOT), $l_i_Bought = 0, $l_i_Spent = 0
			Local $l_i_Start = Supply_Count($GC_I_MODELID_BONES)
			AddOns_Out("[FIBER] Buying " & ($l_i_Lots * $GC_I_SUPPLY_TRADER_LOT) & " bones")
			For $n = 1 To $l_i_Lots
				Local $l_i_Paid = Supply_BuyLot(0, $l_i_Reserve + $GC_I_SUPPLY_CRAFT_FEE * ($l_i_Scrolls - $l_i_Made))
				If $l_i_Paid <= 0 Then ExitLoop
				$l_i_Bought += 1
				$l_i_Spent += $l_i_Paid
				If Mod($l_i_Bought, 10) = 0 And Not Supply_WaitArrival($GC_I_MODELID_BONES, $l_i_Start + ($l_i_Bought - 6) * $GC_I_SUPPLY_TRADER_LOT, 2000) Then
					AddOns_Out("[FIBER] Bones are not arriving; stopping purchases")
					ExitLoop
				EndIf
			Next
			Supply_WaitArrival($GC_I_MODELID_BONES, $l_i_Start + $l_i_Bought * $GC_I_SUPPLY_TRADER_LOT, 3000)
			Supply_KeepGold()
			AddOns_Out("[FIBER] Bought " & ($l_i_Bought * $GC_I_SUPPLY_TRADER_LOT) & " bones for " & $l_i_Spent & "g")
		EndIf
		Local $l_i_Craft = _Min($l_i_Round, Floor(Supply_BagCount($GC_I_MODELID_BONES) / 25))
		Local $l_i_Crafted = Supply_CraftBulk("Res Scrolls", $l_i_Craft)
		$l_i_Made += $l_i_Crafted
		If $l_i_Crafted < $l_i_Round Then ExitLoop
	WEnd

	; 3. Bank scrolls and leftover materials (same clean-up as the Buy Cons routine).
	Supply_CleanInventory()
	Supply_KeepGold()
	$g_i_FiberScrollsCrafted += $l_i_Made
	AddOns_Out("[FIBER] Res Scrolls done: " & $l_i_Made & " crafted (" & $g_i_FiberScrollsCrafted & " this session)")
	If $l_i_Made = 0 Then
		$g_b_FiberScrollsDisabled = True
		AddOns_Out("[WARN] No scrolls crafted; scroll crafting is off until the bot restarts")
	EndIf
	Return True
EndFunc
#EndRegion Res Scrolls
