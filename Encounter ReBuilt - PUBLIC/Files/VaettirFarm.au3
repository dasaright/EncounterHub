#include-once
#cs ==============================================================================================================================
	Vaettir farm for Encounter Re:Built (Farm = Vaettir in Encounter Hub; plays the account's Assassin).

	Ported from gw-suite vaettir.au3 (Blake, v3.4). Solo A/Me from Longeye's Ledge through Bjora Marches into
	Jaga Moraine: takes the Norn blessing, aggroes the left and right Vaettir groups while staying alive with
	Shadow Form / Shroud / Way of Perfection / Channeling / Heart of Shadow, balls them, kills with Wastrel's
	Demise + Arcane Echo, loots and rezones through Bjora.

	Build: OwVUI2h5lPP8Id2BkAiAvpLBTAA  (5x Blessed insignia, +1 Shadow Arts headpiece, +3 Shadow Arts,
	Superior Vigor, 3x Attunement; Sword/Axe/Spear of Enchanting (+5 energy) + shield +45^ench / +10 vs Earth).

	Shared with the Fiber farm (FiberFarm.au3): Farm_UseSkill, salvaging, rare-weapon storage, inventory
	clean-up, and the global Buy Cons gold trigger after every run.

	Config\supply.ini [Vaettir] (optional): PickUpMapPieces=false, PickUpMesmerTomes=false
#ce ==============================================================================================================================

Global Const $GC_I_VAETTIR_OUTPOST = $GC_I_MAP_ID_LONGEYES_LEDGE
Global Const $GC_I_VAETTIR_BJORA = $GC_I_MAP_ID_BJORA_MARCHES
Global Const $GC_I_VAETTIR_JAGA = $GC_I_MAP_ID_JAGA_MORAINE
Global Const $GC_S_VAETTIR_BUILD = "OwVUI2h5lPP8Id2BkAiAvpLBTAA"

; Skill slots
Global Const $GC_I_VAETTIR_PARADOX = 1
Global Const $GC_I_VAETTIR_SF = 2
Global Const $GC_I_VAETTIR_SHROUD = 3
Global Const $GC_I_VAETTIR_WAYOFPERF = 4
Global Const $GC_I_VAETTIR_HOS = 5
Global Const $GC_I_VAETTIR_WASTREL = 6
Global Const $GC_I_VAETTIR_ECHO = 7
Global Const $GC_I_VAETTIR_CHANNELING = 8

; gw-suite ranges (squared, compared with AddOns_GetPseudoDistance)
Global Const $GC_I_VAETTIR_NEARBY_2 = 240 * 240
Global Const $GC_I_VAETTIR_AREA_2 = 312 * 312
Global Const $GC_I_VAETTIR_EARSHOT_2 = 1000 * 1000
Global Const $GC_I_VAETTIR_SPELLCAST_2 = 1085 * 1085

Global $g_h_VaettirStuck = TimerInit()

#Region Settings, setup
Func Vaettir_Setting($a_s_Key, $a_s_Default)
	Return StringLower(IniRead(Supply_ConfigPath(), "Vaettir", $a_s_Key, $a_s_Default)) = "true"
EndFunc

; Start, restart and resume: be in Longeye's Ledge (or already in Jaga), solo, hard mode, build loaded.
Func Vaettir_Setup()
	Local $l_i_Ping = Other_GetPing()
	Friend_SetOfflineStatus()
	Sleep(500 + $l_i_Ping)
	Local $l_i_Map = Map_GetMapID()
	If $l_i_Map = $GC_I_VAETTIR_JAGA Then Return True ; continue the farm where it is
	If $l_i_Map <> $GC_I_VAETTIR_OUTPOST Then
		AddOns_Out("[VAETTIR] Travelling to Longeye's Ledge")
		If Not HeartbeatTravel($GC_I_VAETTIR_OUTPOST) Then Return SetError(1, 0, False)
	EndIf
	AddOns_Out("[VAETTIR] Loading skillbar")
	Attribute_LoadSkillTemplate($GC_S_VAETTIR_BUILD)
	Sleep(500 + $l_i_Ping)
	Ui_LeaveGroup()
	Sleep(500 + $l_i_Ping)
	Ui_SetDifficulty(True)
	Sleep(500 + $l_i_Ping)
	Return True
EndFunc

; Extra pickups (gw-suite vaettir CanPickUpEx): lockpicks, glacial stones, black dye, event drops, and
; weapons to salvage for materials. Gold items are always picked up by CanPickUp.
Func Vaettir_AddPickups(ByRef $a_m_PickUpSet)
	Fiber_AddPickups($a_m_PickUpSet) ; same event/consumable list and the salvage-weapon marker
	Fiber_AddPickup($a_m_PickUpSet, $GC_I_MODELID_GLACIAL_STONE)
	If Vaettir_Setting("PickUpMesmerTomes", "false") Then Fiber_AddPickup($a_m_PickUpSet, $GC_I_MODELID_MESMER_TOME)
	If Vaettir_Setting("PickUpMapPieces", "false") Then
		For $i = 0 To UBound($GC_AI_QUEST_ITEMS) - 1
			Fiber_AddPickup($a_m_PickUpSet, $GC_AI_QUEST_ITEMS[$i])
		Next
	EndIf
EndFunc
#EndRegion Settings, setup

#Region Main
Func Vaettir_Main()
	AddOns_PurgeHook()
	If Map_GetMapID() <> $GC_I_VAETTIR_JAGA Then
		If Not Vaettir_RunThere() Then
			If Quest18_ForcePauseReturn() Then Return True
			Return SetError(1, 0, False)
		EndIf
	EndIf
	If Quest18_ForcePauseReturn() Then Return True
	If Map_GetMapID() <> $GC_I_VAETTIR_JAGA Then Return SetError(2, 0, False)

	AddOns_Out("[VAETTIR] Starting run #" & ($g_i_Count_Runs + 1))
	$g_h_Runtime = TimerInit()
	Local $l_i_Result = Vaettir_CombatLoop()
	If $l_i_Result >= 0 Then
		$g_i_Count_Runs += 1
		If $l_i_Result = 0 Then
			$g_i_Count_Fails += 1
			AddOns_Out("[WARN] Vaettir run failed")
		EndIf
	EndIf
	Return True
EndFunc

; Longeye's Ledge housekeeping, then the run through Bjora Marches into Jaga Moraine.
Func Vaettir_RunThere()
	If Map_GetMapID() <> $GC_I_VAETTIR_OUTPOST Then
		If Not HeartbeatStep("Vaettir_Setup", "Vaettir_Setup") Then Return False
	EndIf
	Fiber_StoreMaterials()
	If Fiber_NeedsInventory() Then
		If Not HeartbeatStep("Fiber_Inventory", "Fiber_Inventory") Then Return False
		If Not HeartbeatStep("Vaettir_Setup", "Vaettir_Setup") Then Return False
	EndIf
	If AddOns_GetEmptyStorageSlotCount() = 0 And AddOns_GetEmptyInventorySlotCount() < 5 Then
		AddOns_Out("[WARN] Storage and bags are full; pausing")
		$g_b_PauseRequested = True
		Return False
	EndIf
	If Quest18_ForcePauseReturn() Then Return False

	AddOns_Out("[VAETTIR] Exiting Longeye's Ledge")
	Ui_SetDifficulty(True)
	AddOns_MoveTo(-25745, 15900)
	If Not Fiber_Zone(-26472, 16217, $GC_I_VAETTIR_BJORA) Then Return False

	Local $l_p_Cupcake = 0
	Local $l_av2_Inv = Item_GetInventoryArray()
	For $i = 0 To UBound($l_av2_Inv, $UBOUND_ROWS) - 1
		If $l_av2_Inv[$i][$GC_I_INVENTORY_MODELID] = $GC_I_MODELID_CUPCAKE Then $l_p_Cupcake = $l_av2_Inv[$i][$GC_I_INVENTORY_ITEMID]
	Next
	If $l_p_Cupcake <> 0 Then Item_UseItem($l_p_Cupcake)

	Local $l_ai2_Way[27][2] = [[15003, -16598], [12699, -14589], [11628, -13867], [10891, -12989], [10517, -11229], _
		[10209, -9973], [9296, -8811], [7815, -7967], [6266, -6328], [4940, -4655], _
		[3867, -2397], [2279, -1331], [7, -1072], [-1752, -1209], [-3596, -1671], _
		[-5386, -1526], [-6904, -283], [-7711, 364], [-9537, 1265], [-11141, 857], _
		[-12730, 371], [-13379, 40], [-14925, 1099], [-16183, 2753], [-17803, 4439], _
		[-18852, 5290], [-19771, 5547]]
	AddOns_Out("[VAETTIR] Running to Jaga Moraine")
	For $i = 0 To UBound($l_ai2_Way) - 1
		If Not Vaettir_MoveRunning($l_ai2_Way[$i][0], $l_ai2_Way[$i][1]) Then Return False
	Next
	Return Fiber_Zone(-20400, 5620, $GC_I_VAETTIR_JAGA)
EndFunc

; Take the bounty, aggro left and right, ball, kill, loot, rezone. Returns 1 (success), 0 (failed) or
; -1 (left Jaga for inventory; not counted as a run).
Func Vaettir_CombatLoop()
	If Map_GetMapID() <> $GC_I_VAETTIR_JAGA Then Return -1
	AddOns_UpdatePartyPtrs()

	If Title_GetTitleInfo($GC_E_TITLEID_NORN, "CurrentPoints") < 160000 Then
		AddOns_Out("[VAETTIR] Taking the Norn blessing")
		Vaettir_TalkTo(13318, -20826)
		Game_Dialog(0x84)
		Other_PingSleep(1000)
	EndIf

	Local $l_ai2_Left[13][2] = [[0, 0], [11375, -22761], [10925, -23466], [10917, -24311], [10280, -24620], _
		[9640, -23175], [7815, -23200], [7765, -22940], [8213, -22829], [8740, -22475], _
		[8880, -21384], [8684, -20833], [8982, -20576]]
	AddOns_Out("[VAETTIR] Aggro left")
	Farm_UseSkill($GC_I_VAETTIR_SHROUD)
	AddOns_MoveTo(12470, -22540)
	Farm_UseSkill($GC_I_VAETTIR_CHANNELING)
	For $i = 1 To UBound($l_ai2_Left) - 1
		Vaettir_MoveAggro($l_ai2_Left[$i][0], $l_ai2_Left[$i][1], 150, 150, $l_ai2_Left[$i - 1][0], $l_ai2_Left[$i - 1][1])
	Next
	AddOns_Out("[VAETTIR] Waiting for the left ball")
	Vaettir_WaitForSettle(15000)
	Vaettir_HosCurrentTarget()
	Vaettir_WaitForSettle(5000)
	Vaettir_WaitFor(2000)

	Local $l_ai2_Right[15][2] = [[0, 0], [10196, -20124], [9976, -18338], [11316, -18056], [10392, -17512], _
		[10114, -16948], [10729, -16273], [10505, -14750], [10815, -14790], [11090, -15345], _
		[11670, -15457], [12604, -15320], [12450, -14800], [12725, -14850], [12476, -16157]]
	AddOns_Out("[VAETTIR] Aggro right")
	For $i = 1 To UBound($l_ai2_Right) - 1
		Vaettir_MoveAggro($l_ai2_Right[$i][0], $l_ai2_Right[$i][1], 150, 150, $l_ai2_Right[$i - 1][0], $l_ai2_Right[$i - 1][1])
	Next
	AddOns_Out("[VAETTIR] Waiting for the right ball")
	Vaettir_WaitForSettle(15000)
	Vaettir_HosCurrentTarget()
	Vaettir_WaitForSettle(5000)
	Vaettir_WaitFor(2000)

	AddOns_Out("[VAETTIR] Blocking in the spot")
	Vaettir_MoveAggro(13070, -16911, 30, 30)
	Vaettir_MoveAggro(12938, -17081, 20, 20)
	Vaettir_WaitFor(500)
	Vaettir_MoveAggro(12790, -17201, 10, 10)
	Vaettir_WaitFor(300)
	Vaettir_MoveAggro(12747, -17220, 0, 10)
	Vaettir_WaitFor(300)
	Vaettir_MoveAggro(12703, -17239, 0, 10)
	Vaettir_WaitFor(500)
	Map_Move(12684, -17184, 0)
	Other_PingSleep(500)

	AddOns_Out("[VAETTIR] Killing")
	Vaettir_Kill()
	Other_PingSleep(1000)
	If Not AddOns_GetIsDead(-2) Then
		AddOns_Out("[VAETTIR] Looting")
		AddOns_UpdatePartyPtrs()
		PickUpLoot(2500)
	EndIf

	; Bags nearly full: go to the outpost; Vaettir_RunThere cleans the inventory before the next run.
	If AddOns_GetEmptyInventorySlotCount() <= $GC_I_FIBER_FREE_SLOTS_MIN Then
		AddOns_Out("[VAETTIR] Bags are full; travelling to Longeye's Ledge")
		HeartbeatTravel($GC_I_VAETTIR_OUTPOST)
		Return -1
	EndIf

	Local $l_i_Success = AddOns_GetIsDead(-2) ? 0 : 1
	AddOns_Out("[VAETTIR] Rezoning")
	Vaettir_MoveZoning(11905, -17561)
	Vaettir_MoveZoning(13413, -18452)
	Vaettir_MoveZoning(14231, -19585)
	Vaettir_MoveZoning(15305, -20400)

	Local $l_h_Deadlock = TimerInit()
	While AddOns_GetIsDead(-2)
		Sleep(1000)
		If Not IsAlive("Vaettir rezone") Then Return 0
		If Party_GetPartyContextInfo("IsDefeated") Or TimerDiff($l_h_Deadlock) > 30000 Then
			Sleep(2500)
			Vaettir_ResignAndReturn()
			Return $l_i_Success
		EndIf
	WEnd

	AddOns_MoveTo(15305, -20400)
	If Not Fiber_Zone(15950, -20600, $GC_I_VAETTIR_BJORA) Then Return $l_i_Success
	AddOns_MoveTo(-19771, 5547)
	Fiber_Zone(-20400, 5620, $GC_I_VAETTIR_JAGA)
	Return $l_i_Success
EndFunc

Func Vaettir_ResignAndReturn()
	Chat_SendChat("resign", "/")
	Local $l_h_Timer = TimerInit()
	Do
		Sleep(100)
	Until Party_GetPartyContextInfo("IsDefeated") Or TimerDiff($l_h_Timer) > 5000
	Other_PingSleep(1000)
	Map_ReturnToOutpost()
	Map_WaitMapLoading($GC_I_VAETTIR_OUTPOST)
EndFunc
#EndRegion Main

#Region Helpers
Func Vaettir_EffectLeft($a_i_SkillID)
	If Not AddOns_GetHasEffect($a_i_SkillID) Then Return 0
	Return Agent_GetAgentEffectInfo(-2, $a_i_SkillID, "TimeRemaining")
EndFunc

Func Vaettir_NearestEnemy()
	Return AddOns_GetNearestAgent_EnemyLiving_NoSM(-2)
EndFunc

Func Vaettir_NearestEnemyDistance()
	Local $l_p_Enemy = Vaettir_NearestEnemy()
	If $l_p_Enemy = 0 Then Return 10000
	Return AddOns_GetDistance($l_p_Enemy, -2)
EndFunc

Func Vaettir_TargetDistance()
	If Agent_GetCurrentTarget() = 0 Then Return 100000
	Return AddOns_GetDistance(-1, -2)
EndFunc

Func Vaettir_Stuck()
	If TimerDiff($g_h_VaettirStuck) < 3000 Then Return ; avoid spamming /stuck
	Chat_SendChat("stuck", "/")
	$g_h_VaettirStuck = TimerInit()
EndFunc

; Walk to an NPC near (x,y) and talk to it.
Func Vaettir_TalkTo($a_f_X, $a_f_Y)
	Local $l_p_NPC = AddOns_GetNearestAgent_NPCLiving(-2, -1, True, $a_f_X, $a_f_Y)
	If $l_p_NPC = 0 Then Return False
	Local $l_h_Timer = TimerInit(), $l_h_Resend = TimerInit()
	Agent_GoNPC($l_p_NPC)
	While AddOns_GetDistance($l_p_NPC, -2) > 250 And TimerDiff($l_h_Timer) < 15000
		Sleep(250)
		If TimerDiff($l_h_Resend) > 2000 Then
			Agent_GoNPC($l_p_NPC)
			$l_h_Resend = TimerInit()
		EndIf
	WEnd
	Agent_GoNPC($l_p_NPC)
	Other_PingSleep(500)
	Return True
EndFunc

; Heart of Shadow on the current target (or the nearest foe when the target is gone / too far).
Func Vaettir_HosCurrentTarget()
	Local $l_p_Target = Agent_GetAgentPtr(-1)
	If Agent_GetCurrentTarget() = 0 Or Vaettir_TargetDistance() > 1000 Then $l_p_Target = Vaettir_NearestEnemy()
	If $l_p_Target = 0 Then Return
	Agent_ChangeTarget($l_p_Target)
	Farm_UseSkill($GC_I_VAETTIR_HOS, $l_p_Target)
EndFunc

; Foe within 500 that is nearest to (x,y) (where we came from), for an escaping Heart of Shadow.
Func Vaettir_GetHosTarget($a_f_X, $a_f_Y)
	Local $l_ap_Foes = AddOns_GetAgentArray_EnemyLiving_NoSM(-2, 1250)
	Local $l_p_Best = 0, $l_f_Best = 100000000
	For $i = 1 To $l_ap_Foes[0]
		Local $l_f_Dist = AddOns_GetPseudoDistanceToXY($a_f_X, $a_f_Y, $l_ap_Foes[$i])
		If $l_f_Dist < $l_f_Best And AddOns_GetDistance($l_ap_Foes[$i], -2) < 500 Then
			$l_p_Best = $l_ap_Foes[$i]
			$l_f_Best = $l_f_Dist
		EndIf
	Next
	Return $l_p_Best
EndFunc

Func Vaettir_HosAway($a_f_HosX, $a_f_HosY)
	If $a_f_HosX = 0 And $a_f_HosY = 0 Then Return Farm_UseSkill($GC_I_VAETTIR_HOS, Vaettir_NearestEnemy())
	Local $l_p_Target = Vaettir_GetHosTarget($a_f_HosX, $a_f_HosY)
	If $l_p_Target = 0 Then $l_p_Target = Vaettir_NearestEnemy()
	Return Farm_UseSkill($GC_I_VAETTIR_HOS, $l_p_Target)
EndFunc

; gw-suite StayAlive: keep Shadow Form up, Shroud / Way of Perfection when low, Channeling for energy.
Func Vaettir_StayAlive()
	Local $l_f_HP = AddOns_GetHP(-2)
	Local $l_i_SF = Vaettir_EffectLeft($GC_I_SKILL_ID_SHADOW_FORM)
	If $l_i_SF > 3500 And $l_f_HP < 0.6 And Farm_IsRecharged($GC_I_VAETTIR_SHROUD) Then
		Farm_UseSkill($GC_I_VAETTIR_SHROUD)
		$l_i_SF = Vaettir_EffectLeft($GC_I_SKILL_ID_SHADOW_FORM)
	EndIf
	If $l_i_SF > 3500 And $l_f_HP < 0.6 And Farm_IsRecharged($GC_I_VAETTIR_WAYOFPERF) Then
		Farm_UseSkill($GC_I_VAETTIR_WAYOFPERF)
		$l_i_SF = Vaettir_EffectLeft($GC_I_SKILL_ID_SHADOW_FORM)
	EndIf
	If $l_i_SF > 3500 And Vaettir_EffectLeft($GC_I_SKILL_ID_CHANNELING) < 3000 Then
		Farm_UseSkill($GC_I_VAETTIR_CHANNELING)
		$l_i_SF = Vaettir_EffectLeft($GC_I_SKILL_ID_SHADOW_FORM)
	EndIf
	If $l_i_SF < 2500 Then
		Farm_UseSkill($GC_I_VAETTIR_PARADOX)
		Farm_UseSkill($GC_I_VAETTIR_SF)
	EndIf
EndFunc

; Shared stuck/deadlock handling for MoveAggro / MoveZoning: give up the run after the deadlock time.
Func Vaettir_GiveUp($a_h_Deadlock)
	If Vaettir_NearestEnemyDistance() < 1000 Then
		$a_h_Deadlock = TimerInit()
		Do ; let the foes finish us, so the party wipes and returns
			Other_PingSleep(500)
		Until AddOns_GetIsDead(-2) Or TimerDiff($a_h_Deadlock) > 60000 Or Not IsAlive("Vaettir give up")
	EndIf
	If Not AddOns_GetIsDead(-2) Then
		Chat_SendChat("resign", "/")
		Sleep(6000)
	EndIf
	Return False
EndFunc

; Move to (x,y) while staying alive vs the Vaettirs (gw-suite MoveAggro).
Func Vaettir_MoveAggro($a_f_X, $a_f_Y, $a_i_MoveRandom = 150, $a_i_Random = 150, $a_f_HosX = 0, $a_f_HosY = 0)
	If AddOns_GetIsDead(-2) Then Return False
	Local $l_i_Blocked = 0, $l_i_HosCount = 0, $l_b_AggressiveHos = False, $l_f_Angle = 0
	Local $l_h_Deadlock = TimerInit(), $l_h_Move = TimerInit()

	Map_Move($a_f_X, $a_f_Y, $a_i_MoveRandom)
	Fiber_SalvageOne()
	If Agent_GetCurrentTarget() = 0 Or Vaettir_TargetDistance() > 1000 Then Agent_ChangeTarget(Vaettir_NearestEnemy())

	Do
		Other_PingSleep(250)
		If AddOns_GetIsDead(-2) Or Not IsAlive("Vaettir_MoveAggro") Then Return False
		Vaettir_StayAlive()

		If TimerDiff($l_h_Deadlock) > 180000 Then Return Vaettir_GiveUp($l_h_Deadlock)

		If Not AddOns_GetIsMoving(-2) Then
			If $l_i_HosCount > 6 Then Return Vaettir_GiveUp($l_h_Deadlock)
			If TimerDiff($l_h_Deadlock) > 60000 Then Farm_UseSkill($GC_I_VAETTIR_HOS, -2)
			$l_i_Blocked += 1
			If $l_i_Blocked < 5 Then
				Map_Move($a_f_X, $a_f_Y, $a_i_MoveRandom)
			ElseIf $l_i_Blocked < 10 Then
				If Farm_IsRecharged($GC_I_VAETTIR_HOS) And Not $l_b_AggressiveHos Then
					Vaettir_HosAway($a_f_HosX, $a_f_HosY)
					$l_b_AggressiveHos = True
					$l_i_Blocked = 0
				Else
					$l_f_Angle += 40
					Map_Move(AddOns_GetX(-2) + 300 * Sin($l_f_Angle), AddOns_GetY(-2) + 300 * Cos($l_f_Angle))
					Other_PingSleep(500)
				EndIf
			ElseIf Farm_IsRecharged($GC_I_VAETTIR_HOS) Then
				If $l_i_HosCount < 2 Then
					Vaettir_HosAway($a_f_HosX, $a_f_HosY)
				Else
					Farm_UseSkill($GC_I_VAETTIR_HOS, -2)
				EndIf
				$l_i_Blocked = 0
				$l_i_HosCount += 1
			ElseIf TimerDiff($l_h_Move) > 1500 Then
				Map_Move($a_f_X, $a_f_Y, $a_i_MoveRandom)
				$l_h_Move = TimerInit()
			EndIf
		Else
			If $l_i_Blocked > 0 Then
				Vaettir_Stuck()
				$l_i_Blocked = 0
				$l_i_HosCount = 0
			EndIf
			If Vaettir_TargetDistance() > 900 Then ; target far: probably stuck, or it broke aggro
				Vaettir_Stuck()
				Other_PingSleep(50)
				If Vaettir_TargetDistance() > 900 Then Agent_ChangeTarget(Vaettir_NearestEnemy())
			EndIf
		EndIf
	Until AddOns_GetDistanceToXY($a_f_X, $a_f_Y) < ($a_i_Random * 1.5)
	Return True
EndFunc

; Move to (x,y) on the way out of Jaga (gw-suite MoveZoning).
Func Vaettir_MoveZoning($a_f_X, $a_f_Y, $a_i_MoveRandom = 150, $a_i_Random = 150)
	If AddOns_GetIsDead(-2) Then Return False
	Local $l_i_Blocked = 0, $l_i_HosCount = 0, $l_f_Angle = 0
	Local $l_h_Deadlock = TimerInit()

	Map_Move($a_f_X, $a_f_Y, $a_i_MoveRandom)
	Fiber_SalvageOne()
	If Agent_GetCurrentTarget() = 0 Or Vaettir_TargetDistance() > 1000 Then Agent_ChangeTarget(Vaettir_NearestEnemy())

	Do
		Other_PingSleep(500)
		If AddOns_GetIsDead(-2) Or Not IsAlive("Vaettir_MoveZoning") Then Return False
		If Agent_GetCurrentTarget() <> 0 And Vaettir_TargetDistance() < 1200 Then
			If Vaettir_EffectLeft($GC_I_SKILL_ID_SHADOW_FORM) < 2000 Then
				Farm_UseSkill($GC_I_VAETTIR_PARADOX)
				Farm_UseSkill($GC_I_VAETTIR_SF)
			EndIf
			If Not AddOns_GetHasEffect($GC_I_SKILL_ID_SHROUD_OF_DISTRESS) And AddOns_GetHP(-2) < 0.5 Then Farm_UseSkill($GC_I_VAETTIR_SHROUD)
		EndIf

		If TimerDiff($l_h_Deadlock) > 60000 Then Return Vaettir_GiveUp($l_h_Deadlock)

		If Not AddOns_GetIsMoving(-2) Then
			If $l_i_HosCount > 6 Then Return Vaettir_GiveUp($l_h_Deadlock)
			$l_i_Blocked += 1
			If $l_i_Blocked < 3 Then
				Map_Move($a_f_X, $a_f_Y, $a_i_MoveRandom)
			ElseIf $l_i_Blocked < 8 Then
				$l_f_Angle += 40
				Map_Move(AddOns_GetX(-2) + 300 * Sin($l_f_Angle), AddOns_GetY(-2) + 300 * Cos($l_f_Angle))
				Other_PingSleep(1000)
			ElseIf Farm_IsRecharged($GC_I_VAETTIR_HOS) Then
				If $l_i_HosCount < 2 Then
					Farm_UseSkill($GC_I_VAETTIR_HOS, Vaettir_NearestEnemy())
				Else
					Farm_UseSkill($GC_I_VAETTIR_HOS, -2)
				EndIf
				$l_i_Blocked = 0
				$l_i_HosCount += 1
			EndIf
		ElseIf $l_i_Blocked > 0 Then
			Vaettir_Stuck()
			$l_i_Blocked = 0
			$l_i_HosCount = 0
		EndIf
	Until AddOns_GetDistanceToXY($a_f_X, $a_f_Y) < $a_i_Random * 1.5
	Return True
EndFunc

; Run across Bjora Marches (gw-suite MoveRunning).
Func Vaettir_MoveRunning($a_f_X, $a_f_Y)
	If AddOns_GetIsDead(-2) Then Return False
	Map_Move($a_f_X, $a_f_Y)
	Fiber_SalvageOne()
	Do
		Sleep(Random(400, 600, 1))
		If AddOns_GetIsDead(-2) Or Not IsAlive("Vaettir_MoveRunning") Then Return False
		If Map_GetMapID() <> $GC_I_VAETTIR_BJORA Then Return False
		Local $l_f_HP = AddOns_GetHP(-2), $l_f_Energy = AddOns_GetCurrentEnergy(-2)
		Local $l_f_Distance = Vaettir_NearestEnemyDistance()
		If $l_f_Distance < 1300 And $l_f_Energy > 20 And Farm_IsRecharged($GC_I_VAETTIR_PARADOX) And Farm_IsRecharged($GC_I_VAETTIR_SF) Then
			Farm_UseSkill($GC_I_VAETTIR_PARADOX)
			Farm_UseSkill($GC_I_VAETTIR_SF)
		EndIf
		If $l_f_HP < 0.9 And $l_f_Energy > 10 And Farm_IsRecharged($GC_I_VAETTIR_SHROUD) Then Farm_UseSkill($GC_I_VAETTIR_SHROUD)
		If $l_f_HP < 0.5 And $l_f_Distance < 500 And $l_f_Energy > 5 And Farm_IsRecharged($GC_I_VAETTIR_HOS) Then Farm_UseSkill($GC_I_VAETTIR_HOS, Vaettir_NearestEnemy())
		If Not AddOns_GetIsMoving(-2) Then Map_Move($a_f_X, $a_f_Y)
	Until AddOns_GetDistanceToXY($a_f_X, $a_f_Y) < 250
	Return True
EndFunc

; Wait until every foe within 2000 that is in spellcast range is also adjacent (balled), or timeout.
Func Vaettir_WaitForSettle($a_i_Timeout = 15000)
	If AddOns_GetIsDead(-2) Then Return False
	Local $l_ap_Foes = AddOns_GetAgentArray_EnemyLiving_NoSM(-2, 2000)
	Local $l_h_Timer = TimerInit()
	While TimerDiff($l_h_Timer) < $a_i_Timeout
		Other_PingSleep(500)
		If AddOns_GetIsDead(-2) Or Not IsAlive("Vaettir_WaitForSettle") Then Return False
		Vaettir_StayAlive()
		Fiber_SalvageOne(True)
		Local $l_i_Adjacent = 0, $l_i_InCast = 0
		For $i = 1 To $l_ap_Foes[0]
			Local $l_f_Dist = AddOns_GetPseudoDistance($l_ap_Foes[$i], -2)
			If $l_f_Dist < 0 Then ContinueLoop
			If $l_f_Dist < $GC_I_VAETTIR_SPELLCAST_2 Then $l_i_InCast += 1
			If $l_f_Dist < $GC_I_VAETTIR_NEARBY_2 Then $l_i_Adjacent += 1
		Next
		If $l_i_InCast = $l_i_Adjacent Then Return True
	WEnd
	Return True
EndFunc

Func Vaettir_WaitFor($a_i_Ms)
	Local $l_h_Timer = TimerInit()
	Do
		Other_PingSleep(250)
		If AddOns_GetIsDead(-2) Or Not IsAlive("Vaettir_WaitFor") Then Return False
		Vaettir_StayAlive()
	Until TimerDiff($l_h_Timer) > $a_i_Ms
	Return True
EndFunc

; A good Wastrel's Demise target: alive, enchanted, not hexed, nearby.
Func Vaettir_GetGoodTarget(ByRef $a_ap_Foes)
	For $i = 1 To $a_ap_Foes[0]
		If AddOns_GetHP($a_ap_Foes[$i]) <= 0 Then ContinueLoop
		If Not AddOns_GetIsEnchanted($a_ap_Foes[$i]) Then ContinueLoop
		If Agent_GetAgentInfo($a_ap_Foes[$i], "IsHexed") Then ContinueLoop
		Local $l_f_Dist = AddOns_GetPseudoDistance($a_ap_Foes[$i], -2)
		If $l_f_Dist < 0 Or $l_f_Dist > $GC_I_VAETTIR_NEARBY_2 Then ContinueLoop
		Return $a_ap_Foes[$i]
	Next
	Return 0
EndFunc

; Wastrel's Demise (+ Arcane Echo) until the ball is dead (gw-suite Kill).
Func Vaettir_Kill()
	If AddOns_GetIsDead(-2) Then Return False
	Local $l_ap_Foes = AddOns_GetAgentArray_EnemyLiving_NoSM(-2, 2000)
	Local $l_p_Target = Vaettir_NearestEnemy()
	Local $l_h_Deadlock = TimerInit()
	While $l_p_Target <> 0 And Not AddOns_GetIsDead($l_p_Target)
		Other_PingSleep(100)
		If AddOns_GetIsDead(-2) Or Not IsAlive("Vaettir_Kill") Then Return False
		Vaettir_StayAlive()
		; Arcane Echo first, so the next Wastrel's Demise is copied
		If Skill_GetSkillbarInfo($GC_I_VAETTIR_ECHO, "SkillID") = $GC_I_SKILL_ID_ARCANE_ECHO And Vaettir_EffectLeft($GC_I_SKILL_ID_SHADOW_FORM) > 5500 Then
			If Farm_IsRecharged($GC_I_VAETTIR_WASTREL) And Farm_IsRecharged($GC_I_VAETTIR_ECHO) Then
				Farm_UseSkill($GC_I_VAETTIR_ECHO)
				Farm_UseSkill($GC_I_VAETTIR_WASTREL, Vaettir_GetGoodTarget($l_ap_Foes))
			EndIf
		EndIf
		Vaettir_StayAlive()
		If Farm_IsRecharged($GC_I_VAETTIR_WASTREL) Then Farm_UseSkill($GC_I_VAETTIR_WASTREL, Vaettir_GetGoodTarget($l_ap_Foes))
		Vaettir_StayAlive()
		; the echoed Wastrel's Demise
		If Farm_IsRecharged($GC_I_VAETTIR_ECHO) And Skill_GetSkillbarInfo($GC_I_VAETTIR_ECHO, "SkillID") = $GC_I_SKILL_ID_WASTRELS_DEMISE Then
			Farm_UseSkill($GC_I_VAETTIR_ECHO, Vaettir_GetGoodTarget($l_ap_Foes))
		EndIf
		; the target ran away: pick the nearest one, or stop when nothing is close
		Local $l_f_Dist = AddOns_GetPseudoDistance($l_p_Target, -2)
		If $l_f_Dist < 0 Or $l_f_Dist > $GC_I_VAETTIR_EARSHOT_2 Then
			$l_p_Target = Vaettir_NearestEnemy()
			If $l_p_Target = 0 Then ExitLoop
			$l_f_Dist = AddOns_GetPseudoDistance($l_p_Target, -2)
			If $l_f_Dist < 0 Or $l_f_Dist > $GC_I_VAETTIR_AREA_2 Then ExitLoop
		EndIf
		If TimerDiff($l_h_Deadlock) > 60000 Then ExitLoop
	WEnd
	If AddOns_GetNumberOfAgent_EnemyLiving_NoSM(-2, 1250) > 0 Then
		AddOns_Out("[VAETTIR] Some enemies are still alive")
		Vaettir_StayAlive()
	EndIf
	Return True
EndFunc
#EndRegion Helpers
