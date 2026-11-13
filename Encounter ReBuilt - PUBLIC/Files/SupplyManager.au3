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
Func Supply_ManualRequestPending()
    Return FileExists(Supply_RequestPath())
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
; Keep character platinum usable for the next transaction, moving it to/from storage.
; Guild Wars limits carried gold to 100,000g and storage to 1,000,000g.
Func Supply_BalanceGold($required=0)
    Local Const $LC_I_CHARACTER_GOLD_CAP=100000
    Local Const $LC_I_STORAGE_GOLD_CAP=1000000
    Local Const $LC_I_DEPOSIT_THRESHOLD=75000
    If $required<0 Or $required>$LC_I_CHARACTER_GOLD_CAP Then
        AddOns_Out("[SUPPLY] Gold balance request is outside the 0-100,000g inventory limit")
        Return False
    EndIf
    Local $gold=Item_GetInventoryInfo("GoldCharacter")
    Local $bank=Item_GetInventoryInfo("GoldStorage")
    If $gold<$required Then
        Local $withdraw=$required-$gold
        If $withdraw>$bank Then $withdraw=$bank
        If $withdraw>$LC_I_CHARACTER_GOLD_CAP-$gold Then $withdraw=$LC_I_CHARACTER_GOLD_CAP-$gold
        If $withdraw<=0 Then
            AddOns_Out("[SUPPLY] Not enough platinum: need "&$required&"g, have "&$gold&"g in inventory and "&$bank&"g in storage")
            Return False
        EndIf
        Item_WithdrawGold($withdraw)
        Sleep(500)
        $gold=Item_GetInventoryInfo("GoldCharacter")
        $bank=Item_GetInventoryInfo("GoldStorage")
        If $gold<$required Then
            AddOns_Out("[SUPPLY] Could not withdraw enough platinum; inventory has "&$gold&"g, required "&$required&"g")
            Return False
        EndIf
    ElseIf $required=0 And $gold>=$LC_I_DEPOSIT_THRESHOLD And $bank<$LC_I_STORAGE_GOLD_CAP Then
        Item_DepositGold()
        Sleep(500)
        $gold=Item_GetInventoryInfo("GoldCharacter")
        $bank=Item_GetInventoryInfo("GoldStorage")
        If $gold>=$LC_I_DEPOSIT_THRESHOLD And $bank>=$LC_I_STORAGE_GOLD_CAP Then
            AddOns_Out("[SUPPLY] Storage is full; cannot clear carried platinum for further sales")
            Return False
        EndIf
    EndIf
    Return Item_GetInventoryInfo("GoldCharacter")>=$required
EndFunc
Func Supply_BuyMats($item)
    Local $models[5]=[$GC_I_MODELID_BONES,$GC_I_MODELID_PLANT_FIBRES,$GC_I_MODELID_DUST,$GC_I_MODELID_FEATHERS,$GC_I_MODELID_IRON]
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

    ; Common materials at a Guild Wars material trader are sold only in lots of 10.
    ; Round the requested amount up to whole lots (e.g. 25 -> 30).
    Local Const $LC_I_TRADER_LOT=10
    For $i=0 To 4
        Local $current=Supply_Count($models[$i])
        Local $missing=$need[$i]-$current
        If $missing<=0 Then ContinueLoop
        If Not Supply_Talk("Shad") Then Return False

        Local $lots=Ceiling($missing/$LC_I_TRADER_LOT)
        AddOns_Out("[SUPPLY] Buying "&($lots*$LC_I_TRADER_LOT)&" of material model "&$models[$i]&" in "&$lots&" trader lot(s) of 10")
        For $batch=1 To $lots
            ; One trader transaction buys one 10-material lot. Quote it first so
            ; the character carries the actual live price instead of an arbitrary reserve.
            Local $quote=Supply_QuoteBuy($models[$i])
            If $quote<=0 Then
                AddOns_Out("[SUPPLY] No valid live trader quote for model "&$models[$i]&"; quote item ID "&Memory_Read($g_i_TraderCostID,"dword")&", carried gold "&Item_GetInventoryInfo("GoldCharacter")&"g")
                Return False
            EndIf
            If Not Supply_BalanceGold($quote) Then
                AddOns_Out("[SUPPLY] Cannot afford quoted 10-unit lot for model "&$models[$i]&": quote "&$quote&"g, carried gold "&Item_GetInventoryInfo("GoldCharacter")&"g, bank gold "&Item_GetInventoryInfo("GoldStorage")&"g")
                Return False
            EndIf

            Local $before=Supply_Count($models[$i])
            ; Common materials are purchased in 10-unit quantities at the trader.
            If Not Merchant_BuyItem($models[$i],$LC_I_TRADER_LOT,True) Then
                AddOns_Out("[SUPPLY] Trader purchase rejected for model "&$models[$i]&" (10-unit lot); quote "&$quote&"g, carried gold "&Item_GetInventoryInfo("GoldCharacter")&"g, bank gold "&Item_GetInventoryInfo("GoldStorage")&"g, free slots "&AddOns_GetEmptyInventorySlotCount()&", quote item ID "&Memory_Read($g_i_TraderCostID,"dword")&".")
                Return False
            EndIf
            AddOns_Out("[SUPPLY] Submitted trader purchase for model "&$models[$i]&" at "&$quote&"g per 10-unit lot")
            Local $wait=TimerInit()
            Do
                Sleep(100)
            Until Supply_Count($models[$i])>=$before+$LC_I_TRADER_LOT Or TimerDiff($wait)>5000
            Local $after=Supply_Count($models[$i])
            If $after<$before+$LC_I_TRADER_LOT Then
                AddOns_Out("[SUPPLY] Trader purchase was not confirmed for model "&$models[$i]&"; expected +"&$LC_I_TRADER_LOT&", observed +"&($after-$before))
                Return False
            EndIf
            If Not Supply_BalanceGold() Then Return False
        Next

        Local $remaining=$need[$i]-Supply_Count($models[$i])
        If $remaining>0 Then
            AddOns_Out("[SUPPLY] Material purchase incomplete for model "&$models[$i]&"; still missing "&$remaining)
            Return False
        EndIf
    Next
    Return True
EndFunc
Func Supply_Craft($item)
    If AddOns_GetEmptyInventorySlotCount()<=1 Then
        AddOns_Out("[SUPPLY] Cannot craft "&$item&": fewer than 2 free inventory slots")
        Return False
    EndIf
    If Not Supply_BuyMats($item) Then
        AddOns_Out("[SUPPLY] Cannot craft "&$item&": required materials could not be prepared")
        Return False
    EndIf
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
            $recipe[1][0]=$GC_I_MODELID_PLANT_FIBRES
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
    If Not Supply_Talk($npc) Then
        AddOns_Out("[SUPPLY] Crafter unavailable for "&$item&": "&$npc)
        Return False
    EndIf
    If Not Supply_BalanceGold(250) Then
        AddOns_Out("[SUPPLY] Cannot craft "&$item&": 250g crafting fee is unavailable in carried platinum")
        Return False
    EndIf
    Local $before=Supply_Stock($item)
    If Not Merchant_CraftItem($model,250,$recipe,1) Then
        AddOns_Out("[SUPPLY] Craft request failed for "&$item&"; check carried platinum and recipe materials")
        Return False
    EndIf
    Sleep(1000)
    If Not Supply_BalanceGold() Then Return False
    Local $after=Supply_Stock($item)
    If $after<=$before Then
        AddOns_Out("[SUPPLY] Craft did not produce "&$item&"; inventory count did not increase")
        Return False
    EndIf
    AddOns_Out("[SUPPLY] Crafted "&$item&" (stock "&$before&" -> "&$after&")")
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
            If Not Supply_BalanceGold() Then Return False
            Local $beforeEctos=Supply_Count($GC_I_MODELID_GLOB_OF_ECTOPLASM)
            If Not Merchant_SellItem($id,1,True) Then
                AddOns_Out("[SUPPLY] Ecto sale request failed; carried platinum was balanced before selling")
                Return False
            EndIf
            Sleep(350)
            If Supply_Count($GC_I_MODELID_GLOB_OF_ECTOPLASM)>=$beforeEctos Then
                AddOns_Out("[SUPPLY] Ecto sale was not confirmed; stopping to avoid a false success")
                Return False
            EndIf
            If Not Supply_BalanceGold() Then Return False
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
    If Memory_Read($g_i_TraderCostID,"dword")<>$id Then Return 0
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
    Local $gold=Item_GetInventoryInfo("GoldCharacter")
    Local $slots=AddOns_GetEmptyInventorySlotCount()
    If Not Supply_BalanceGold(250) Then
        AddOns_Out("[SUPPLY] Production skipped: unable to prepare the 250g crafting fee from carried or bank platinum")
        Return False
    EndIf
    If $slots<=1 Then
        AddOns_Out("[SUPPLY] Production skipped: only "&$slots&" free inventory slots; at least 2 are required")
        Return False
    EndIf
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
    If $passes=0 Then
        AddOns_Out("[SUPPLY] No items were crafted; routine is reporting failure")
        Return False
    EndIf
    AddOns_Out("[SUPPLY] Production finished: "&$passes&" craft(s) completed")
    Return True
EndFunc
Func Supply_Run($manual)
    If $g_b_SupplyBusy Then Return False
    $g_b_SupplyBusy=True
    Local $oldState=$g_i_BotState
    Local $l_b_SupplySuccess=True
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
    
    If $manual Then
        Local $min=Number(IniRead(Supply_ConfigPath(),"Supply","MinimumEctoSellPrice","0"))
        If $profile<>"Full Conset" Or Supply_ManualConsetOK() Then
            If Supply_SellEctos($min) Then
                If Not Supply_Produce($profile) Then $l_b_SupplySuccess=False
            Else
                $l_b_SupplySuccess=False
                AddOns_Out("[SUPPLY] Routine stopped: required merchant interaction failed")
            EndIf
        Else
            $l_b_SupplySuccess=False
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
            If Not Supply_Produce($profile) Then $l_b_SupplySuccess=False
        Else
            $l_b_SupplySuccess=False
            AddOns_Out("[SUPPLY] Automatic production skipped: bank gold "&$bank&"g is below threshold "&$threshold&"g")
        EndIf
    EndIf
    If $l_b_SupplySuccess Then
        AddOns_Out("[SUPPLY] Routine complete")
    Else
        AddOns_Out("[SUPPLY] Routine ended with errors; see messages above")
    EndIf
    If $oldState=$GC_I_BOTSTATE_RUN Then $g_i_BotState=$GC_I_BOTSTATE_RUN
    $g_b_SupplyBusy=False
    Return $l_b_SupplySuccess
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
