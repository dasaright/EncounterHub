#include-once
Global Const $GC_I_SUPPLY_EMBARK = 857
Global Const $GC_I_SUPPLY_RES_SCROLL = 26501
Global $g_b_SupplyBusy = False
Func Supply_ConfigPath()
    Return @ScriptDir & "\Config\supply.ini"
EndFunc
Func Supply_CharacterName()
    Return GUI_StripCharacterEnum(GUICtrlRead($g_i_CtrlID_Combo_CharInput))
EndFunc
Func Supply_CharacterFileKey()
    Return StringRegExpReplace(Supply_CharacterName(), "[^A-Za-z0-9 _-]", "_")
EndFunc
Func Supply_RequestPath()
    Return @ScriptDir & "\Config\supply.manual." & Supply_CharacterFileKey() & ".request"
EndFunc
Func Supply_RunningPath()
    Return @ScriptDir & "\Config\supply.manual." & Supply_CharacterFileKey() & ".running"
EndFunc
Func Supply_NPC($name)
    Local $agents = Agent_GetAgentArray()
    For $i = 1 To $agents[0]
        Local $p = $agents[$i]
        If Agent_GetAgentInfo($p,"IsLivingType") And StringInStr(Agent_GetAgentInfo($p,"Name"),$name)>0 Then Return $p
    Next
    Return 0
EndFunc
Func Supply_Talk($name)
    Local $p = Supply_NPC($name)
    If $p=0 Then
        AddOns_Out("[SUPPLY] NPC not found: "&$name)
        Return False
    EndIf
    Agent_GoNPC($p)
    Sleep(1200)
    Return True
EndFunc
Func Supply_Count($model)
    Return AddOns_GetInventoryItemCountbyModelID($model,True)
EndFunc
Func Supply_BuyMats($item)
    Local $models[5]=[$GC_I_MODELID_BONES,$GC_I_MODELID_PLANT_FIBERS,$GC_I_MODELID_DUST,$GC_I_MODELID_FEATHERS,$GC_I_MODELID_IRON]
    Local $need[5]
    Switch $item
        Case "Essence of Celerity"
            $need[2]=50
            $need[3]=50
        Case "Res Scrolls"
            $need[0]=25
            $need[1]=25
        Case "Grail of Might"
            $need[2]=50
            $need[4]=50
        Case "Armor of Salvation"
            $need[0]=50
            $need[4]=50
    EndSwitch
    For $i=0 To 4
        Local $missing=$need[$i]-Supply_Count($models[$i])
        If $missing<=0 Then ContinueLoop
        If Not Supply_Talk("Shad") Then Return False
        If Not Merchant_BuyItem($models[$i],Ceiling($missing/10),True) Then Return False
        Sleep(300)
    Next
    Return True
EndFunc
Func Supply_Craft($item)
    If AddOns_GetEmptyInventorySlotCount()<=1 Or Not Supply_BuyMats($item) Then Return False
    Local $model=0,$npc="", $recipe[2][2]
    Switch $item
        Case "Essence of Celerity"
            $model=$GC_I_MODELID_ESSENCE_OF_CELERITY
            $npc="Kwat"
            $recipe[0][0]=$GC_I_MODELID_DUST
            $recipe[0][1]=50
            $recipe[1][0]=$GC_I_MODELID_FEATHERS
            $recipe[1][1]=50
        Case "Res Scrolls"
            $model=$GC_I_SUPPLY_RES_SCROLL
            $npc="Edwin"
            $recipe[0][0]=$GC_I_MODELID_BONES
            $recipe[0][1]=25
            $recipe[1][0]=$GC_I_MODELID_PLANT_FIBERS
            $recipe[1][1]=25
        Case "Grail of Might"
            $model=$GC_I_MODELID_GRAIL_OF_MIGHT
            $npc="Eyja"
            $recipe[0][0]=$GC_I_MODELID_DUST
            $recipe[0][1]=50
            $recipe[1][0]=$GC_I_MODELID_IRON
            $recipe[1][1]=50
        Case "Armor of Salvation"
            $model=$GC_I_MODELID_ARMOR_OF_SALVATION
            $npc="Alcus Nailbiter"
            $recipe[0][0]=$GC_I_MODELID_BONES
            $recipe[0][1]=50
            $recipe[1][0]=$GC_I_MODELID_IRON
            $recipe[1][1]=50
    EndSwitch
    If Not Supply_Talk($npc) Then Return False
    If Not Merchant_CraftItem($model,250,$recipe,1) Then Return False
    Sleep(700)
    AddOns_Out("[SUPPLY] Crafted "&$item)
    Return True
EndFunc
Func Supply_Stock($item)
    Switch $item
        Case "Essence of Celerity"
            Return Supply_Count($GC_I_MODELID_ESSENCE_OF_CELERITY)
        Case "Grail of Might"
            Return Supply_Count($GC_I_MODELID_GRAIL_OF_MIGHT)
        Case "Armor of Salvation"
            Return Supply_Count($GC_I_MODELID_ARMOR_OF_SALVATION)
        Case "Res Scrolls"
            Return Supply_Count($GC_I_SUPPLY_RES_SCROLL)
    EndSwitch
    Return 0
EndFunc
Func Supply_QuoteSell($itemID)
    DllStructSetData($g_d_RequestQuoteSell,2,$itemID)
    Core_Enqueue($g_p_RequestQuoteSell,8)
    Local $timer=TimerInit()
    Do
        Sleep(50)
    Until Memory_Read($g_i_TraderCostID,"dword")=$itemID Or TimerDiff($timer)>5000
    If TimerDiff($timer)>5000 Then Return 0
    Return Memory_Read($g_f_TraderCostValue,"dword")
EndFunc
Func Supply_SellEctos($minimum)
    If Not Supply_Talk("Argus") Then Return False
    Local $items=Item_GetInventoryArray()
    For $i=0 To UBound($items,$UBOUND_ROWS)-1
        If $items[$i][$GC_I_INVENTORY_MODELID]<>$GC_I_MODELID_GLOB_OF_ECTOPLASM Then ContinueLoop
        Local $id=$items[$i][$GC_I_INVENTORY_ITEMID],$qty=$items[$i][$GC_I_INVENTORY_QUANTITY]
        For $j=1 To $qty
            Local $price=Supply_QuoteSell($id)
            If $price<$minimum Or $price<=0 Then
                AddOns_Out("[SUPPLY] Ecto sale stopped at quote "&$price&"g (minimum "&$minimum&"g)")
                Return True
            EndIf
            Merchant_SellItem($id,1,True)
            Sleep(300)
        Next
    Next
    Return True
EndFunc
Func Supply_QuoteBuy($model)
    Local $ptr=Merchant_GetMerchantItemPtr($model)
    If $ptr=0 Then Return 0
    Local $id=Memory_Read($ptr),$old=Memory_Read($g_i_TraderQuoteID)
    DllStructSetData($g_d_RequestQuote,2,$id)
    Core_Enqueue($g_p_RequestQuote,8)
    Local $timer=TimerInit()
    Do
        Sleep(50)
    Until Memory_Read($g_i_TraderQuoteID)<>$old Or TimerDiff($timer)>5000
    If TimerDiff($timer)>5000 Then Return 0
    Return Memory_Read($g_f_TraderCostValue,"dword")
EndFunc
Func Supply_ManualConsetOK()
    If Not Supply_Talk("Shad") Then Return False
    Local $dust=Supply_QuoteBuy($GC_I_MODELID_DUST),$feathers=Supply_QuoteBuy($GC_I_MODELID_FEATHERS)
    Local $bones=Supply_QuoteBuy($GC_I_MODELID_BONES),$iron=Supply_QuoteBuy($GC_I_MODELID_IRON)
    If $dust<=0 Or $feathers<=0 Or $bones<=0 Or $iron<=0 Then Return False
    Local $items=Item_GetInventoryArray(),$ectoID=0
    For $i=0 To UBound($items,$UBOUND_ROWS)-1
        If $items[$i][$GC_I_INVENTORY_MODELID]=$GC_I_MODELID_GLOB_OF_ECTOPLASM Then
            $ectoID=$items[$i][$GC_I_INVENTORY_ITEMID]
            ExitLoop
        EndIf
    Next
    If $ectoID=0 Or Not Supply_Talk("Argus") Then Return False
    Local $ecto=Supply_QuoteSell($ectoID)
    Local $cost=10*$dust+5*$feathers+5*$bones+10*$iron+750
    AddOns_Out("[SUPPLY] Full Conset estimate "&$cost&"g vs ecto "&$ecto&"g")
    Return $ecto>0 And $cost<=($ecto*0.8)
EndFunc
Func Supply_Produce($profile)
    Local $passes=0
    While Item_GetInventoryInfo("GoldCharacter")>=250 And AddOns_GetEmptyInventorySlotCount()>1
        Local $item=$profile
        If $profile="Full Conset" Then
            Local $e=Supply_Stock("Essence of Celerity"),$g=Supply_Stock("Grail of Might"),$a=Supply_Stock("Armor of Salvation")
            If $e<=$g And $e<=$a Then
                $item="Essence of Celerity"
            ElseIf $g<=$a Then
                $item="Grail of Might"
            Else
                $item="Armor of Salvation"
            EndIf
        EndIf
        If Not Supply_Craft($item) Then ExitLoop
        $passes+=1
        If $passes>=100 Then ExitLoop
    WEnd
EndFunc
Func Supply_Run($manual)
    If $g_b_SupplyBusy Then Return False
    $g_b_SupplyBusy=True
    Local $oldState=$g_i_BotState
    ; Skip normal pause cleanup; the next Quest18 run will travel back to Kaineng.
    $g_i_BotState=$GC_I_BOTSTATE_IDLE
    AddOns_Out("[SUPPLY] Travelling to Embark Beach (American district)")
    If Not Map_TravelTo($GC_I_SUPPLY_EMBARK,0,0,0,True) Then
        If $oldState=$GC_I_BOTSTATE_RUN Then $g_i_BotState=$GC_I_BOTSTATE_RUN
        $g_b_SupplyBusy=False
        Return False
    EndIf
    AddOns_Out("[SUPPLY] Approaching Foreman the Crier to reach the central NPC area")
    If Not Supply_Talk("Foreman the Crier") Then
        AddOns_Out("[SUPPLY] Routine stopped: could not reach Foreman the Crier")
        If $oldState=$GC_I_BOTSTATE_RUN Then $g_i_BotState=$GC_I_BOTSTATE_RUN
        $g_b_SupplyBusy=False
        Return False
    EndIf
    Sleep(1000)
    Local $profileSection="Character:"&Supply_CharacterName()
    Local $profile=IniRead(Supply_ConfigPath(),$profileSection,$manual ? "ManualProfile" : "AutomaticProfile","Full Conset")
    Local $success=True
    If $manual Then
        Local $min=Number(IniRead(Supply_ConfigPath(),"Supply","MinimumEctoSellPrice","0"))
        If $profile<>"Full Conset" Or Supply_ManualConsetOK() Then
            If Supply_SellEctos($min) Then
                Supply_Produce($profile)
            Else
                $success=False
                AddOns_Out("[SUPPLY] Routine stopped: required merchant interaction failed")
            EndIf
        Else
            $success=False
            AddOns_Out("[SUPPLY] Routine stopped: Full Conset price check failed or required NPC was unavailable")
        EndIf
    Else
        Local $threshold=Number(IniRead(Supply_ConfigPath(),"Supply","BankGoldThreshold","800000"))
        Local $bank=Item_GetInventoryInfo("GoldStorage")
        If $bank>=$threshold Then
            Local $withdraw=100000-Item_GetInventoryInfo("GoldCharacter")
            If $withdraw>$bank Then $withdraw=$bank
            If $withdraw>0 Then Item_WithdrawGold($withdraw)
            Sleep(500)
            Supply_Produce($profile)
        EndIf
    EndIf
    If $success Then
        AddOns_Out("[SUPPLY] Routine complete")
    Else
        AddOns_Out("[SUPPLY] Routine ended with errors; see messages above")
    EndIf
    If $oldState=$GC_I_BOTSTATE_RUN Then $g_i_BotState=$GC_I_BOTSTATE_RUN
    $g_b_SupplyBusy=False
    Return $success
EndFunc
Func Supply_CheckManualRequest()
    If $g_b_SupplyBusy Then Return False
    Local $request=Supply_RequestPath(),$running=Supply_RunningPath()
    If Not FileExists($request) Then Return False
    ; Atomic rename lets the Hub know the routine has started and prevents duplicate pickup.
    If Not FileMove($request,$running,1) Then Return False
    Supply_Run(True)
    FileDelete($running)
    Return True
EndFunc
Func Supply_CheckRequests()
    If $g_b_SupplyBusy Then Return
    If Supply_CheckManualRequest() Then Return
    If StringLower(IniRead(Supply_ConfigPath(),"Supply","AutomaticEnabled","false"))="true" _
    And Item_GetInventoryInfo("GoldStorage")>=Number(IniRead(Supply_ConfigPath(),"Supply","BankGoldThreshold","800000")) Then Supply_Run(False)
EndFunc
