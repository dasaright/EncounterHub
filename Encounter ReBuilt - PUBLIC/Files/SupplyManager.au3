#include-once
Global $g_i_SupplyQuoteModel = 0, $g_i_SupplyQuoteID = 0
; Minimum time between trader transactions: ~6 per second.
Global Const $GC_I_SUPPLY_TRADE_INTERVAL_MS = 165
Global $g_h_SupplyLastTrade = 0
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
; Known Embark Beach NPC positions (same coordinates used by gw-suite and BotsHub).
; Name decoding is asynchronous and can time out, so these positions are used to
; walk to the NPC first and as a fallback when the name lookup comes back empty.
Func Supply_NPCCoords($name, ByRef $x, ByRef $y)
    Switch $name
        Case "Shad" ; basic material trader
            $x=2997
            $y=-2271
        Case "Argus" ; rare material trader
            $x=2928
            $y=-2452
        Case "Kwat" ; Essence of Celerity
            $x=3666
            $y=90
        Case "Alcus Nailbiter" ; Armor of Salvation and Scrolls of Resurrection
            $x=3743
            $y=-106
        Case "Eyja" ; Grail of Might
            $x=3414
            $y=644
        Case Else
            Return False
    EndSwitch
    Return True
EndFunc
Func Supply_NPCByName($name)
    Local $agents = Agent_GetAgentArray()
    For $i = 1 To $agents[0]
        Local $p = $agents[$i]
        If Not Agent_GetAgentInfo($p,"IsLivingType") Then ContinueLoop
        If StringInStr(Agent_GetAgentInfo($p,"Name"),$name)>0 Then Return $p
    Next
    Return 0
EndFunc
Func Supply_NPCNearXY($x, $y, $maxRange=600)
    Local $agents = Agent_GetAgentArray()
    Local $best=0, $bestDist=$maxRange
    For $i = 1 To $agents[0]
        Local $p = $agents[$i]
        If Not Agent_GetAgentInfo($p,"IsLivingType") Then ContinueLoop
        If Agent_GetAgentInfo($p,"Allegiance")<>$GC_I_ALLEGIANCE_NPC Then ContinueLoop ; NPCs only, never players
        If Agent_GetAgentInfo($p,"IsDead") Then ContinueLoop
        Local $d=Agent_GetDistanceToXY($x,$y,$p)
        If $d<$bestDist Then
            $best=$p
            $bestDist=$d
        EndIf
    Next
    Return $best
EndFunc
Func Supply_NPC($name)
    Local $x=0,$y=0
    Local $hasCoords=Supply_NPCCoords($name,$x,$y)
    ; Retry the name lookup: a decode that times out returns an empty name.
    For $attempt=1 To 3
        Local $p=Supply_NPCByName($name)
        If $p<>0 Then Return $p
        If $hasCoords Then
            $p=Supply_NPCNearXY($x,$y)
            If $p<>0 Then
                AddOns_Out("[SUPPLY] Using NPC at the known position of "&$name&" (name lookup unavailable)")
                Return $p
            EndIf
        EndIf
        Sleep(500)
    Next
    Return 0
EndFunc
; Movement packets walk in a straight line, so Embark Beach obstacles must be
; avoided with waypoints (the same route gw-suite uses): central start point
; (2000,250), then the trader corner (2619,-1986) or the crafter area.
Func Supply_Approach($name, ByRef $ax, ByRef $ay)
    Switch $name
        Case "Shad", "Argus"
            $ax=2619
            $ay=-1986
        Case "Kwat"
            $ax=3550
            $ay=60
        Case "Alcus Nailbiter"
            $ax=3605
            $ay=-50
        Case "Eyja"
            $ax=3405
            $ay=450
        Case Else
            Return False
    EndSwitch
    Return True
EndFunc
; Walk from wherever the character spawned in Embark Beach to the central start point
; (2000,250), using the per-spawn routes from gw-suite's MoveToStartingPointEmbark.
; The nearest known spawn is used, since the character may have moved a little.
Func Supply_MoveToCentre()
    ; spawnX, spawnY, then up to two waypoints (0,0 = unused)
    Local $routes[11][6]=[ _
        [3385,444,0,0,0,0], _
        [325,-2533,-116,-1084,750,-215], _
        [1055,-3165,-116,-1084,750,-215], _
        [-1370,967,-960,301,0,0], _
        [-1739,144,-960,301,0,0], _
        [2469,2001,0,0,0,0], _
        [-3335,116,-2364,618,0,0], _
        [-2998,-1288,-1486,453,0,0], _
        [-2792,2626,-1486,453,0,0], _
        [726,3769,1171,1694,0,0], _
        [1166,2568,1171,1694,0,0]]
    If Agent_GetDistanceToXY(2000,250)<400 Then Return True
    Local $best=-1,$bestDist=1600
    For $r=0 To 10
        Local $d=Agent_GetDistanceToXY($routes[$r][0],$routes[$r][1])
        If $d<$bestDist Then
            $best=$r
            $bestDist=$d
        EndIf
    Next
    If $best>=0 Then
        For $w=2 To 4 Step 2
            If $routes[$best][$w]=0 And $routes[$best][$w+1]=0 Then ContinueLoop
            AddOns_MoveTo($routes[$best][$w],$routes[$best][$w+1],"",50)
        Next
    EndIf
    AddOns_MoveTo(2000,250,"",50)
    Return Agent_GetDistanceToXY(2000,250)<400
EndFunc
Func Supply_WalkTo($name)
    Local $x=0,$y=0,$ax=0,$ay=0
    If Not Supply_NPCCoords($name,$x,$y) Then Return
    If Agent_GetDistanceToXY($x,$y)<=300 Then Return
    Supply_Approach($name,$ax,$ay)
    ; Leave the current area through its own waypoint first (standing at an NPC,
    ; the straight line to the next area is blocked), then go to the target area.
    ; If that leg fails, route through the central start point and try again.
    If Agent_GetDistanceToXY(2619,-1986)<700 Then
        AddOns_MoveTo(2619,-1986,"",30) ; trader corner exit
    ElseIf Agent_GetDistanceToXY(3550,60)<800 Then
        AddOns_MoveTo(3550,60,"",30) ; crafter area exit
    Else
        ; Fresh from the spawn point: follow that spawn's route through the central start point.
        Supply_MoveToCentre()
    EndIf
    If Agent_GetDistanceToXY($ax,$ay)>200 And Not AddOns_MoveTo($ax,$ay,"",30) Then
        AddOns_MoveTo(2000,250,"",50)
        AddOns_MoveTo($ax,$ay,"",30)
    EndIf
EndFunc
Func Supply_Talk($name)
    ; Walk near the NPC first so it is in range and loaded before searching.
    Supply_WalkTo($name)
    Local $p = Supply_NPC($name)
    If $p=0 Then
        AddOns_Out("[SUPPLY] NPC not found: "&$name)
        Return False
    EndIf
    ; Agent_GoNPC only starts the walk; keep re-sending it until the character arrives.
    Local $timer=TimerInit(),$resend=TimerInit()
    Agent_GoNPC($p)
    While Agent_GetDistance($p)>250 And TimerDiff($timer)<20000
        Sleep(250)
        If TimerDiff($resend)>2000 Then
            Agent_GoNPC($p)
            $resend=TimerInit()
        EndIf
    WEnd
    If Agent_GetDistance($p)>250 Then
        AddOns_Out("[SUPPLY] Could not reach NPC: "&$name&" (player at "&Round(Agent_GetAgentInfo(-2,"X"))&","&Round(Agent_GetAgentInfo(-2,"Y"))&", "&Round(Agent_GetDistance($p))&" away)")
        Return False
    EndIf
    Agent_GoNPC($p)
    Sleep(1000)
    Return True
EndFunc
Func Supply_Count($model)
    Return AddOns_GetInventoryItemCountbyModelID($model,True)
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
Func Supply_QuoteSell($itemID, $timeoutMs=3000)
    ; Wait for a NEW quote: the last quote may already be for this same item (e.g. the
    ; Full Conset price check), so matching the item ID alone can return a stale price.
    Local $old=Memory_Read($g_i_TraderQuoteID)
    DllStructSetData($g_d_RequestQuoteSell,2,$itemID)
    Core_Enqueue($g_p_RequestQuoteSell,8)
    Local $timer=TimerInit()
    Do
        Sleep(10)
    Until Memory_Read($g_i_TraderQuoteID)<>$old Or TimerDiff($timer)>$timeoutMs
    If Memory_Read($g_i_TraderQuoteID)=$old Then Return 0
    If Memory_Read($g_i_TraderCostID,"dword")<>$itemID Then Return 0
    Return Memory_Read($g_f_TraderCostValue,"dword")
EndFunc
; Sell ectos to the rare material trader while the live quote stays at or above
; $minimum: ~3 sales per second, carried gold kept around 20k by depositing as it
; goes, and sales verified in bulk (every 10) instead of one by one.
Func Supply_SellEctos($minimum)
    Local $model=$GC_I_MODELID_GLOB_OF_ECTOPLASM
    If Supply_Count($model)=0 Then Return True
    If Not Supply_Talk("Argus") Then Return False
    Local $items=Item_GetInventoryArray()
    Local $start=Supply_Count($model),$sold=0,$earned=0,$stopReason=""
    For $i=0 To UBound($items,$UBOUND_ROWS)-1
        If $items[$i][$GC_I_INVENTORY_MODELID]<>$model Then ContinueLoop
        Local $id=$items[$i][$GC_I_INVENTORY_ITEMID],$qty=$items[$i][$GC_I_INVENTORY_QUANTITY]
        For $j=1 To $qty
            Local $price=Supply_QuoteSell($id)
            If $price<=0 Then
                If Not Supply_Talk("Argus") Then Return False
                $price=Supply_QuoteSell($id)
            EndIf
            If $price<=0 Then
                $stopReason="no live quote"
                ExitLoop 2
            EndIf
            If $price<$minimum Then
                $stopReason="quote "&$price&"g is below the "&$minimum&"g minimum"
                ExitLoop 2
            EndIf
            ; Never let a sale push carried gold over the 100k cap.
            If Item_GetInventoryInfo("GoldCharacter")+$price>100000 Then Supply_KeepGold()
            If Item_GetInventoryInfo("GoldCharacter")+$price>100000 Then
                $stopReason="carried gold "&Item_GetInventoryInfo("GoldCharacter")&"g cannot be deposited (bank "&Item_GetInventoryInfo("GoldStorage")&"g of 1,000,000g)"
                ExitLoop 2
            EndIf
            Supply_PaceTrade()
            Core_Enqueue($g_p_TraderSell,4)
            $sold+=1
            $earned+=$price
            If Mod($sold,10)=0 Then
                Supply_KeepGold()
                If Not Supply_WaitGone($model,$start-($sold-6),2000) Then
                    $stopReason="sales are not going through (sent "&$sold&", sold "&($start-Supply_Count($model))&")"
                    ExitLoop 2
                EndIf
            EndIf
        Next
    Next
    Supply_WaitGone($model,$start-$sold,3000)
    Supply_KeepGold()
    Local $confirmed=$start-Supply_Count($model)
    If $sold>0 Then AddOns_Out("[SUPPLY] Sold "&$confirmed&" ecto(s) for about "&$earned&"g"&($stopReason<>"" ? "; stopped: "&$stopReason : ""))
    If $sold=0 And $stopReason<>"" Then AddOns_Out("[SUPPLY] No ectos sold: "&$stopReason)
    If $confirmed<$sold-6 Then
        AddOns_Out("[SUPPLY] Ecto sales not confirmed (sent "&$sold&", sold "&$confirmed&"); stopping")
        Return False
    EndIf
    Return True
EndFunc
; Wait until at most $expected of $model are carried (items leaving the bags).
Func Supply_WaitGone($model, $expected, $timeoutMs)
    Local $t=TimerInit()
    While Supply_Count($model)>$expected And TimerDiff($t)<$timeoutMs
        Sleep(50)
    WEnd
    Return Supply_Count($model)<=$expected
EndFunc
; Trader stock is not in the regular merchant item list, and the trader's item
; changes after each purchase. Like GwAu3's Merchant_BuyItem, find the trader's
; item in the global item array (matching model, not in a bag, not on the ground).
; Newest IDs are tried first because older entries can be stale.
Func Supply_TraderItemIDs($model)
    Local $items=Item_GetItemArray()
    Local $ids[1]=[0]
    For $i=$items[0] To 1 Step -1
        Local $p=$items[$i]
        If Memory_Read($p+0x2C,"dword")<>$model Then ContinueLoop
        If Memory_Read($p+0xC,"ptr")<>0 Then ContinueLoop ; in a player bag
        If Memory_Read($p+0x4,"dword")<>0 Then ContinueLoop ; on the ground
        $ids[0]+=1
        ReDim $ids[$ids[0]+1]
        $ids[$ids[0]]=Item_ItemID($p)
    Next
    Return $ids
EndFunc
; Returns the live price of one trader transaction (one 10-unit lot for common
; materials) and leaves that quote active so Supply_TraderBuy() executes it.
Func Supply_QuoteBuy($model)
    ; The trader item ID is cached so each lot does not rescan the whole item array;
    ; the cache is refreshed whenever a quote for it fails.
    If $model=$g_i_SupplyQuoteModel And $g_i_SupplyQuoteID<>0 Then
        Local $cached=Supply_QuoteItem($g_i_SupplyQuoteID,500)
        If $cached>0 Then Return $cached
    EndIf
    Local $ids=Supply_TraderItemIDs($model)
    For $n=1 To $ids[0]
        If $n>3 Then ExitLoop
        Local $value=Supply_QuoteItem($ids[$n])
        If $value>0 Then
            $g_i_SupplyQuoteModel=$model
            $g_i_SupplyQuoteID=$ids[$n]
            Return $value
        EndIf
    Next
    $g_i_SupplyQuoteID=0
    Return 0
EndFunc
Func Supply_QuoteItem($id, $timeoutMs=3000)
    Local $old=Memory_Read($g_i_TraderQuoteID)
    DllStructSetData($g_d_RequestQuote,2,$id)
    Core_Enqueue($g_p_RequestQuote,8)
    Local $timer=TimerInit()
    Do
        Sleep(10)
    Until Memory_Read($g_i_TraderQuoteID)<>$old Or TimerDiff($timer)>$timeoutMs
    If Memory_Read($g_i_TraderQuoteID)=$old Then Return 0
    If Memory_Read($g_i_TraderCostID,"dword")<>$id Then Return 0
    Return Memory_Read($g_f_TraderCostValue,"dword")
EndFunc
; Executes exactly one trader transaction for the quote currently held.
; Hold the next trader transaction until the pacing interval has passed.
Func Supply_PaceTrade()
    If $g_h_SupplyLastTrade<>0 Then
        While TimerDiff($g_h_SupplyLastTrade)<$GC_I_SUPPLY_TRADE_INTERVAL_MS
            Sleep(5)
        WEnd
    EndIf
    $g_h_SupplyLastTrade=TimerInit()
EndFunc
Func Supply_TraderBuy()
    ; Core_Enqueue has no return value; success is confirmed by the inventory count.
    Core_Enqueue($g_p_TraderBuy,4)
    Return True
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
    If $ectoID=0 Then
        AddOns_Out("[SUPPLY] No ectos to sell; crafting Full Conset from carried and bank gold")
        Return True
    EndIf
    If Not Supply_Talk("Argus") Then Return False
    Local $ecto=Supply_QuoteSell($ectoID)
    Local $cost=10*$dust+5*$feathers+5*$bones+10*$iron+750
    AddOns_Out("[SUPPLY] Full Conset estimate "&$cost&"g vs ecto "&$ecto&"g")
    Return $ecto>0 And $cost<=($ecto*0.8)
EndFunc
; ---------------------------------------------------------------------------------------------
; Bulk supply production
;   1. Plan    - quote every needed material at Shad, work out how many units the total gold
;                (carried + bank) can afford at current prices, target 80% of that so rising
;                prices during the purchase are absorbed, then cap by inventory + storage space.
;   2. Buy     - buy every 10-unit lot for the whole plan in one visit to Shad, moving full
;                material stacks into storage whenever the bags fill up.
;   3. Craft   - walk to each crafter once and craft in batches, withdrawing materials from
;                storage between batches.
; ---------------------------------------------------------------------------------------------
Global Const $GC_I_SUPPLY_TRADER_LOT = 10
Global Const $GC_I_SUPPLY_STACK = 250
Global Const $GC_I_SUPPLY_CRAFT_FEE = 250
Global Const $GC_F_SUPPLY_TARGET_SHARE = 0.8
Global Const $GC_I_SUPPLY_MAX_UNITS = 1000

Func Supply_MatModel($i)
    Switch $i
        Case 0
            Return $GC_I_MODELID_BONES
        Case 1
            Return $GC_I_MODELID_PLANT_FIBRES
        Case 2
            Return $GC_I_MODELID_DUST
        Case 3
            Return $GC_I_MODELID_FEATHERS
        Case 4
            Return $GC_I_MODELID_IRON
    EndSwitch
    Return 0
EndFunc
Func Supply_MatName($i)
    Local $names[5]=["bones","plant fibres","dust","feathers","iron"]
    Return $names[$i]
EndFunc
; Recipe for one crafted item: output model, crafter, per-item material needs (index 0-4)
; and the largest quantity to request in one craft.
Func Supply_Recipe($item, ByRef $model, ByRef $npc, ByRef $need, ByRef $batch)
    Local $n[5]=[0,0,0,0,0]
    Switch $item
        Case "Essence of Celerity"
            $model=$GC_I_MODELID_ESSENCE_OF_CELERITY
            $npc="Kwat"
            $n[2]=50
            $n[3]=50
            $batch=5
        Case "Res Scrolls"
            $model=$GC_I_SUPPLY_RES_SCROLL
            $npc="Alcus Nailbiter" ; also crafts Scrolls of Resurrection
            $n[0]=25
            $n[1]=25
            $batch=10
        Case "Grail of Might"
            $model=$GC_I_MODELID_GRAIL_OF_MIGHT
            $npc="Eyja"
            $n[2]=50
            $n[4]=50
            $batch=5
        Case "Armor of Salvation"
            $model=$GC_I_MODELID_ARMOR_OF_SALVATION
            $npc="Alcus Nailbiter"
            $n[0]=50
            $n[4]=50
            $batch=5
        Case Else
            Return False
    EndSwitch
    $need=$n
    Return True
EndFunc
; Items produced per planned unit (a Full Conset unit is one of each consumable).
Func Supply_ProfileItems($profile)
    If $profile="Full Conset" Then
        Local $set[3]=["Essence of Celerity","Grail of Might","Armor of Salvation"]
        Return $set
    EndIf
    Local $one[1]=[$profile]
    Return $one
EndFunc
; Materials the crafters can use (main bags only, as Merchant_CraftItem requires).
Func Supply_BagCount($model)
    Return AddOns_GetInventoryItemCountbyModelID($model,False)
EndFunc
; Materials available for this routine: main bags + regular storage panes.
Func Supply_MatOwned($i)
    Local $model=Supply_MatModel($i)
    Return Supply_BagCount($model)+AddOns_GetStorageItemCountbyModelID($model,False)
EndFunc
; Gold needed to buy the missing materials for $units plus the crafting fees.
Func Supply_PlanCost($units, ByRef $perUnit, ByRef $owned, ByRef $lotPrice, $itemsPerUnit)
    Local $cost=$GC_I_SUPPLY_CRAFT_FEE*$units*$itemsPerUnit
    For $i=0 To 4
        If $perUnit[$i]=0 Then ContinueLoop
        Local $missing=$perUnit[$i]*$units-$owned[$i]
        If $missing>0 Then $cost+=Ceiling($missing/$GC_I_SUPPLY_TRADER_LOT)*$lotPrice[$i]
    Next
    Return $cost
EndFunc
; New 250-stacks needed to hold the missing materials for $units.
Func Supply_PlanSlots($units, ByRef $perUnit, ByRef $owned)
    Local $slots=0
    For $i=0 To 4
        If $perUnit[$i]=0 Then ContinueLoop
        Local $missing=$perUnit[$i]*$units-$owned[$i]
        If $missing>0 Then $slots+=Ceiling(Ceiling($missing/$GC_I_SUPPLY_TRADER_LOT)*$GC_I_SUPPLY_TRADER_LOT/$GC_I_SUPPLY_STACK)
    Next
    Return $slots
EndFunc
; Move full stacks of the given materials into storage to free bag space.
Func Supply_StashMats(ByRef $perUnit)
    Local $before=AddOns_GetEmptyInventorySlotCount()
    For $i=0 To 4
        If $perUnit[$i]=0 Then ContinueLoop
        AddOns_DepositItemsToStorage(Supply_MatModel($i),-1,1,True,False)
    Next
    Sleep(300)
    Local $after=AddOns_GetEmptyInventorySlotCount()
    If $after>$before Then AddOns_Out("[SUPPLY] Moved full material stacks to storage ("&($after-$before)&" bag slot(s) freed)")
    Return $after>$before
EndFunc
; Buy one 10-unit lot of material $i at Shad. Returns the price paid, 0 to stop buying.
; Keep carried gold around $target (like gw-suite's MinMaxGold): top up from the bank
; when it drops below $low or below $need, deposit the excess above $high. One
; storage transfer packet; the trader window stays open.
Func Supply_KeepGold($need=0, $target=20000, $low=10000, $high=30000)
    Local $gold=Item_GetInventoryInfo("GoldCharacter")
    If $gold<$low Or $gold<$need Then
        Local $want=$target
        If $want<$need Then $want=$need
        If $want>100000 Then $want=100000
        If $want>$gold And Item_GetInventoryInfo("GoldStorage")>0 Then
            Item_WithdrawGold($want-$gold)
            Local $t=TimerInit()
            Do
                Sleep(20)
            Until Item_GetInventoryInfo("GoldCharacter")<>$gold Or TimerDiff($t)>1500
        EndIf
    ElseIf $gold>$high And $need<=$target Then
        Item_DepositGold($gold-$target)
        ; Wait for the transfer to apply, otherwise the caller still sees the old amount.
        Local $td=TimerInit()
        Do
            Sleep(20)
        Until Item_GetInventoryInfo("GoldCharacter")<>$gold Or TimerDiff($td)>1500
    EndIf
    Return Item_GetInventoryInfo("GoldCharacter")>=$need
EndFunc
; Quote and buy one 10-unit lot of material $i without waiting for it to arrive
; (arrival is checked in bulk by the caller). Returns the price, 0 to stop buying.
Func Supply_BuyLot($i, $goldFloor)
    Local $model=Supply_MatModel($i)
    Local $quote=Supply_QuoteBuy($model)
    If $quote<=0 Then
        ; The trader window can close; reopen once and retry.
        If Not Supply_Talk("Shad") Then Return 0
        $quote=Supply_QuoteBuy($model)
    EndIf
    If $quote<=0 Then
        AddOns_Out("[SUPPLY] Shad has no quote for "&Supply_MatName($i)&" (out of stock?); stopping purchases and crafting what is complete")
        Return 0
    EndIf
    ; Keep enough total gold for the remaining crafting fees.
    If Item_GetInventoryInfo("GoldCharacter")+Item_GetInventoryInfo("GoldStorage")-$quote<$goldFloor Then
        AddOns_Out("[SUPPLY] Stopping purchases: "&Supply_MatName($i)&" now costs "&$quote&"g per 10; remaining gold is kept for the "&$goldFloor&"g of crafting fees")
        Return 0
    EndIf
    If Not Supply_KeepGold($quote) Then
        AddOns_Out("[SUPPLY] Stopping purchases: cannot carry "&$quote&"g for the next lot of "&Supply_MatName($i))
        Return 0
    EndIf
    Supply_PaceTrade()
    Supply_TraderBuy()
    Return $quote
EndFunc
; Craft up to $count of $item at its crafter, in batches. Returns the number crafted.
; Wait until at least $expected of $model are carried. Returns True when they are.
Func Supply_WaitArrival($model, $expected, $timeoutMs)
    Local $t=TimerInit()
    While Supply_Count($model)<$expected And TimerDiff($t)<$timeoutMs
        Sleep(50)
    WEnd
    Return Supply_Count($model)>=$expected
EndFunc
Func Supply_CraftBulk($item, $count)
    Local $model=0,$npc="",$need[5],$batch=1
    If $count<=0 Or Not Supply_Recipe($item,$model,$npc,$need,$batch) Then Return 0
    Local $recipe[2][2],$r=0
    For $i=0 To 4
        If $need[$i]=0 Then ContinueLoop
        $recipe[$r][0]=Supply_MatModel($i)
        $recipe[$r][1]=$need[$i]
        $r+=1
    Next
    If Not Supply_Talk($npc) Then
        AddOns_Out("[SUPPLY] Crafter unavailable for "&$item&": "&$npc)
        Return 0
    EndIf
    Local $made=0,$startStock=Supply_Stock($item)
    While $made<$count
        Local $want=$count-$made
        If $want>$batch Then $want=$batch
        ; Bring this batch's materials from storage into the bags.
        Local $moved=False
        For $i=0 To 4
            If $need[$i]=0 Then ContinueLoop
            Local $short=$need[$i]*$want-Supply_BagCount(Supply_MatModel($i))
            If $short>0 And AddOns_GetStorageItemCountbyModelID(Supply_MatModel($i),False)>0 Then
                AddOns_WithdrawItemsFromStorage(Supply_MatModel($i),-1,$short)
                $moved=True
            EndIf
        Next
        If $moved Then Sleep(300)
        ; Craft only what the bags can cover.
        Local $k=$want
        For $i=0 To 4
            If $need[$i]=0 Then ContinueLoop
            Local $fit=Floor(Supply_BagCount(Supply_MatModel($i))/$need[$i])
            If $fit<$k Then $k=$fit
        Next
        If $k<=0 Then
            AddOns_Out("[SUPPLY] Out of materials for "&$item&" after "&$made&" craft(s)")
            ExitLoop
        EndIf
        If AddOns_GetEmptyInventorySlotCount()<1 Then
            AddOns_Out("[SUPPLY] No free bag slot for crafted "&$item&"; stopping after "&$made&" craft(s)")
            ExitLoop
        EndIf
        Local $goldBefore=Item_GetInventoryInfo("GoldCharacter")
        If Not Supply_KeepGold($GC_I_SUPPLY_CRAFT_FEE*$k) Then
            AddOns_Out("[SUPPLY] Cannot carry the "&($GC_I_SUPPLY_CRAFT_FEE*$k)&"g crafting fee for "&$k&" "&$item&"; stopping after "&$made&" craft(s)")
            ExitLoop
        EndIf
        ; Storage transfers can close the crafter window; reopen it before crafting.
        If $moved Or Item_GetInventoryInfo("GoldCharacter")<>$goldBefore Then
            If Not Supply_Talk($npc) Then ExitLoop
        EndIf
        Local $before=Supply_Stock($item)
        If Not Merchant_CraftItem($model,$GC_I_SUPPLY_CRAFT_FEE,$recipe,$k) Then
            AddOns_Out("[SUPPLY] Craft request for "&$k&" "&$item&" was refused; stopping after "&$made&" craft(s)")
            ExitLoop
        EndIf
        Local $wait=TimerInit()
        Do
            Sleep(150)
        Until Supply_Stock($item)>=$before+$k Or TimerDiff($wait)>5000
        Local $got=Supply_Stock($item)-$before
        If $got<=0 Then
            AddOns_Out("[SUPPLY] Craft of "&$item&" did not produce anything; stopping after "&$made&" craft(s)")
            ExitLoop
        EndIf
        $made+=$got
    WEnd
    If $made>0 Then AddOns_Out("[SUPPLY] Crafted "&$made&" "&$item&" (stock "&$startStock&" -> "&Supply_Stock($item)&")")
    Return $made
EndFunc
Func Supply_Produce($profile)
    Local $items=Supply_ProfileItems($profile)
    Local $itemsPerUnit=UBound($items)
    Local $perUnit[5]=[0,0,0,0,0]
    For $it=0 To $itemsPerUnit-1
        Local $model=0,$npc="",$need[5],$batch=1
        If Not Supply_Recipe($items[$it],$model,$npc,$need,$batch) Then
            AddOns_Out("[SUPPLY] Unknown supply profile item: "&$items[$it])
            Return False
        EndIf
        For $i=0 To 4
            $perUnit[$i]+=$need[$i]
        Next
    Next

    ; 1. Plan from live prices and total gold.
    If Not Supply_Talk("Shad") Then Return False
    Local $lotPrice[5]=[0,0,0,0,0],$owned[5]=[0,0,0,0,0],$outOfStock=False
    For $i=0 To 4
        If $perUnit[$i]=0 Then ContinueLoop
        $owned[$i]=Supply_MatOwned($i)
        $lotPrice[$i]=Supply_QuoteBuy(Supply_MatModel($i))
        If $lotPrice[$i]<=0 Then
            If Not Supply_Talk("Shad") Then Return False
            $lotPrice[$i]=Supply_QuoteBuy(Supply_MatModel($i))
        EndIf
        If $lotPrice[$i]<=0 Then
            ; Out of stock: plan only from materials already owned (price treated as unaffordable).
            AddOns_Out("[SUPPLY] Shad has no quote for "&Supply_MatName($i)&" (out of stock?); crafting only from materials already owned")
            $lotPrice[$i]=1000000000
            $outOfStock=True
        EndIf
    Next
    Local $budget=Item_GetInventoryInfo("GoldCharacter")+Item_GetInventoryInfo("GoldStorage")
    Local $afford=0
    While $afford<$GC_I_SUPPLY_MAX_UNITS And Supply_PlanCost($afford+1,$perUnit,$owned,$lotPrice,$itemsPerUnit)<=$budget
        $afford+=1
    WEnd
    ; Target 80% of what is affordable, so prices rising during the purchase are absorbed.
    ; When a material is out of stock, just use everything the owned materials cover.
    Local $units=Floor($afford*$GC_F_SUPPLY_TARGET_SHARE)
    If $outOfStock Then $units=$afford
    ; Space: free bag slots (keeping one per crafted item type plus one spare) and free storage slots.
    Local $space=AddOns_GetEmptyInventorySlotCount()-($itemsPerUnit+1)+AddOns_GetEmptyStorageSlotCount()
    Local $byGold=$units
    While $units>0 And Supply_PlanSlots($units,$perUnit,$owned)>$space
        $units-=1
    WEnd
    Local $priceText=""
    For $i=0 To 4
        If $perUnit[$i]>0 Then $priceText&=Supply_MatName($i)&" "&$lotPrice[$i]&"g/10, "
    Next
    AddOns_Out("[SUPPLY] Prices: "&StringTrimRight($priceText,2)&"; gold "&$budget&"g affords "&$afford&" "&$profile&", targeting 80% = "&$byGold&($units<$byGold ? " (space limits it to "&$units&")" : ""))
    If $units<=0 Then
        AddOns_Out("[SUPPLY] Production skipped: nothing affordable within the 80% target and available space")
        Return False
    EndIf
    If AddOns_GetEmptyInventorySlotCount()<=$itemsPerUnit Then
        AddOns_Out("[SUPPLY] Production skipped: at least "&($itemsPerUnit+1)&" free bag slots are needed")
        Return False
    EndIf

    ; 2. Buy in rounds of one item at a time, rotating through the profile's items
    ;    (e.g. Celerity: dust+feathers, Grail: dust+iron, Armor: bones+iron), so the
    ;    finished sets stay even. Before every lot the remaining gold (carried + bank)
    ;    must still cover the 250g crafting fee for every item bought so far plus the
    ;    one in progress. If the trader runs out of a material, buying stops and only
    ;    the items whose materials are complete are crafted.
    Local $owned0[5],$alloc[5],$boughtLots[5],$start[5]
    For $i=0 To 4
        $owned0[$i]=Supply_MatOwned($i)
        $alloc[$i]=0
        $boughtLots[$i]=0
        $start[$i]=Supply_Count(Supply_MatModel($i))
    Next
    Local $done[$itemsPerUnit]
    For $it=0 To $itemsPerUnit-1
        $done[$it]=0
    Next
    Local $completed=0,$spent=0,$lots=0,$stopped=False
    AddOns_Out("[SUPPLY] Buying materials for "&$units&" "&$profile&", one item at a time")
    For $u=1 To $units
        For $it=0 To $itemsPerUnit-1
            Local $rModel=0,$rNpc="",$rNeed[5],$rBatch=1
            Supply_Recipe($items[$it],$rModel,$rNpc,$rNeed,$rBatch)
            For $i=0 To 4
                If $rNeed[$i]=0 Then ContinueLoop
                Local $required=$alloc[$i]+$rNeed[$i]-$owned0[$i]-$boughtLots[$i]*$GC_I_SUPPLY_TRADER_LOT
                Local $lotsNow=0
                If $required>0 Then $lotsNow=Ceiling($required/$GC_I_SUPPLY_TRADER_LOT)
                For $n=1 To $lotsNow
                    If AddOns_GetEmptyInventorySlotCount()<=$itemsPerUnit+1 Then
                        Local $beforeStash[5]
                        For $m=0 To 4
                            $beforeStash[$m]=Supply_Count(Supply_MatModel($m))
                        Next
                        If Not Supply_StashMats($perUnit) Or Not Supply_Talk("Shad") Then
                            AddOns_Out("[SUPPLY] Stopping purchases: bags and storage are full")
                            $stopped=True
                            ExitLoop
                        EndIf
                        ; Stashed materials leave the bags; re-base the arrival checks.
                        For $m=0 To 4
                            $start[$m]-=$beforeStash[$m]-Supply_Count(Supply_MatModel($m))
                        Next
                    EndIf
                    Local $paid=Supply_BuyLot($i,$GC_I_SUPPLY_CRAFT_FEE*($completed+1))
                    If $paid<=0 Then
                        $stopped=True
                        ExitLoop
                    EndIf
                    $boughtLots[$i]+=1
                    $spent+=$paid
                    $lots+=1
                    ; Every 10 lots, make sure purchases are actually arriving.
                    If Mod($lots,10)=0 Then
                        For $m=0 To 4
                            If $boughtLots[$m]=0 Then ContinueLoop
                            If Not Supply_WaitArrival(Supply_MatModel($m),$start[$m]+($boughtLots[$m]-6)*$GC_I_SUPPLY_TRADER_LOT,2000) Then
                                AddOns_Out("[SUPPLY] Stopping purchases: "&Supply_MatName($m)&" lots are not arriving")
                                $stopped=True
                                ExitLoop 2
                            EndIf
                        Next
                    EndIf
                Next
                If $stopped Then ExitLoop
            Next
            If $stopped Then ExitLoop
            ; This item's materials are complete.
            For $i=0 To 4
                $alloc[$i]+=$rNeed[$i]
            Next
            $done[$it]+=1
            $completed+=1
        Next
        If $stopped Then ExitLoop
        If Mod($u,25)=0 Then AddOns_Out("[SUPPLY] Materials bought for "&$u&"/"&$units&" "&$profile)
    Next
    For $m=0 To 4
        If $boughtLots[$m]>0 Then Supply_WaitArrival(Supply_MatModel($m),$start[$m]+$boughtLots[$m]*$GC_I_SUPPLY_TRADER_LOT,3000)
    Next
    Supply_KeepGold()
    AddOns_Out("[SUPPLY] Bought "&$lots&" lot(s) for "&$spent&"g; materials complete for "&$completed&" item(s)"&($stopped ? " (stopped early)" : ""))
    If $completed=0 Then
        AddOns_Out("[SUPPLY] No items were crafted; not enough materials for one item")
        Return False
    EndIf

    ; 3. One trip per crafter, crafting exactly the items whose materials were completed.
    Local $total=0
    For $it=0 To $itemsPerUnit-1
        $total+=Supply_CraftBulk($items[$it],$done[$it])
    Next
    If $total=0 Then
        AddOns_Out("[SUPPLY] No items were crafted; routine is reporting failure")
        Return False
    EndIf
    AddOns_Out("[SUPPLY] Production finished: "&$total&" item(s) crafted")
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
    Sleep(1000)
    Local $profileSection="Character:"&Supply_CharacterName()
    Local $profile=IniRead(Supply_ConfigPath(),$profileSection,$manual ? "ManualProfile" : "AutomaticProfile","Full Conset")
    
    If $manual Then
        Local $min=Number(IniRead(Supply_ConfigPath(),"Supply","MinimumEctoSellPrice","0"))
        If $profile<>"Full Conset" Or Supply_ManualConsetOK() Then
            If Supply_SellEctos($min) Then
                If Not Supply_Produce($profile) Then $l_b_SupplySuccess=False
                ; Sales can be blocked when carried and bank gold are both full; buying
                ; materials frees room, so try the remaining ectos once more.
                If Supply_Count($GC_I_MODELID_GLOB_OF_ECTOPLASM)>0 Then Supply_SellEctos($min)
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
            Supply_KeepGold()
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
