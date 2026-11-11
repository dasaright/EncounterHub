#include-once

; #INCLUDES# ====================================================================================================================
; Note: All native AutoIt includes are covered by GwAu3/API/_GwAu3.au3 which should always be included in the main script.
;       The same applies to GwAu3 API-specific includes. Other includes containing script-specific files are covered 
;       by _EncounterRebuilt.au3.
;
; #include "AddOns.au3"
;
; #include "../../../API/_GwAu3.au3"
; ===============================================================================================================================

; #GLOBALS - ROUTES# ============================================================================================================
; Map containing all defined routes
Global $g_m_RouteTable[]
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_AddRouteToMap
; Description....: Creates or updates a route spec for a given map and type.
;                  Ensures the keys "Path", "Preludes", and "Zones" exist on the route entry.
; Syntax.........: Pathing_AddRouteToMap ( $a_i_MapID, $a_s_Type, $a_af2_Path )
; Parameters.....: $a_i_MapID - Integer : Target map ID.
;                  $a_s_Type  - String  : Logical route type (e.g., "Merchant").
;                  $a_af2_Path - Nx2    : Backbone path as [ [x,y], ... ].
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - "Preludes" is a jagged array of Nx2 segments; "Zones" is Ex4 bounding boxes [minX,minY,maxX,maxY].
;                  - Overwrites the existing "Path" for this (map,type); other keys are preserved.
; Related........: Pathing_AddPreludeToRoute, Pathing_RouteEnterAndFollow, MapExists
; ===============================================================================================================================
Func Pathing_AddRouteToMap($a_i_MapID, $a_s_Type, $a_af2_Path)
    Local $l_m_TypeRoutes[]
    If MapExists($g_m_RouteTable, $a_i_MapID) Then $l_m_TypeRoutes = $g_m_RouteTable[$a_i_MapID]

    Local $l_m_RouteSpec[]
    If MapExists($l_m_TypeRoutes, $a_s_Type) Then $l_m_RouteSpec = $l_m_TypeRoutes[$a_s_Type]

    $l_m_RouteSpec["Path"] = $a_af2_Path

    If Not MapExists($l_m_RouteSpec, "Preludes") Then
        Local $l_a_JagPreludes[0] ; jagged array of Nx2 arrays
        $l_m_RouteSpec["Preludes"] = $l_a_JagPreludes
    EndIf
    If Not MapExists($l_m_RouteSpec, "Zones") Then
        Local $l_af2_Zones[0][4]  ; Ex4: [minX,minY,maxX,maxY]
        $l_m_RouteSpec["Zones"] = $l_af2_Zones
    EndIf

    $l_m_TypeRoutes[$a_s_Type] = $l_m_RouteSpec
    $g_m_RouteTable[$a_i_MapID] = $l_m_TypeRoutes
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_AddPreludeToRoute
; Description....: Appends a prelude (mini-path) and its trigger zone to an existing route,
;                  normalizing the zone to [minX,minY,maxX,maxY].
; Syntax.........: Pathing_AddPreludeToRoute ( $a_i_MapID, $a_s_Type, $a_af2_Prelude, _
;                  $a_f_X1, $a_f_Y1, $a_f_X2, $a_f_Y2 )
; Parameters.....: $a_i_MapID    - Integer : Target map ID.
;                  $a_s_Type     - String  : Existing route type key.
;                  $a_af2_Prelude - Nx2    : Prelude path [ [x,y], ... ].
;                  $a_f_X1..$a_f_Y2 - Float: Two opposite zone corners (any order).
; Return values..: Success - None (procedure)
;                  Failure - 0 with @error set to:
;                            1 -> Map entry not found
;                            2 -> Route type not found
; Author.........: KleuTSchi
; Remarks........: - Prelude is appended; its zone is appended at the same index in "Zones".
; Related........: Pathing_AddRouteToMap, MapExists
; ===============================================================================================================================
Func Pathing_AddPreludeToRoute($a_i_MapID, $a_s_Type, $a_af2_Prelude, $a_f_X1, $a_f_Y1, $a_f_X2, $a_f_Y2)
    If Not MapExists($g_m_RouteTable, $a_i_MapID) Then Return SetError(1,0,0)
    Local $l_m_TypeRoutes = $g_m_RouteTable[$a_i_MapID]
    If Not MapExists($l_m_TypeRoutes, $a_s_Type) Then Return SetError(2,0,0)

    Local $l_m_RouteSpec = $l_m_TypeRoutes[$a_s_Type]

    Local $l_a_Preludes = $l_m_RouteSpec["Preludes"]
    Local $l_i_CountPre = UBound($l_a_Preludes)
    ReDim $l_a_Preludes[$l_i_CountPre + 1]
    $l_a_Preludes[$l_i_CountPre] = $a_af2_Prelude
    $l_m_RouteSpec["Preludes"] = $l_a_Preludes

    Local $l_f_MinX = ($a_f_X1 < $a_f_X2) ? $a_f_X1 : $a_f_X2
    Local $l_f_MaxX = ($a_f_X1 > $a_f_X2) ? $a_f_X1 : $a_f_X2
    Local $l_f_MinY = ($a_f_Y1 < $a_f_Y2) ? $a_f_Y1 : $a_f_Y2
    Local $l_f_MaxY = ($a_f_Y1 > $a_f_Y2) ? $a_f_Y1 : $a_f_Y2

    Local $l_af2_Zones = $l_m_RouteSpec["Zones"]
    Local $l_i_CountZones = UBound($l_af2_Zones)
    ReDim $l_af2_Zones[$l_i_CountZones + 1][4]
    $l_af2_Zones[$l_i_CountZones][0] = $l_f_MinX
    $l_af2_Zones[$l_i_CountZones][1] = $l_f_MinY
    $l_af2_Zones[$l_i_CountZones][2] = $l_f_MaxX
    $l_af2_Zones[$l_i_CountZones][3] = $l_f_MaxY
    $l_m_RouteSpec["Zones"] = $l_af2_Zones

    $l_m_TypeRoutes[$a_s_Type] = $l_m_RouteSpec
    $g_m_RouteTable[$a_i_MapID] = $l_m_TypeRoutes
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GetNearestPathIndex
; Description....: Finds the index in a path whose point is nearest to an anchor position,
;                  using squared pseudo distance.
; Syntax.........: Pathing_GetNearestPathIndex ( $a_af2_Path, $a_f_AnchorX, $a_f_AnchorY )
; Parameters.....: $a_af2_Path - Nx2 : Path points [ [x,y], ... ].
;                  $a_f_AnchorX - Float : Anchor X.
;                  $a_f_AnchorY - Float : Anchor Y.
; Return values..: Integer - Index in [0..UBound($a_af2_Path)-1].
; Author.........: KleuTSchi
; Remarks........: - Uses AddOns_ComputePseudoDistance() for performance (no sqrt).
; Related........: AddOns_ComputePseudoDistance, UBound
; ===============================================================================================================================
Func Pathing_GetNearestPathIndex($a_af2_Path, $a_f_AnchorX, $a_f_AnchorY)
    Local $l_i_Idx = 0, $l_f_NearestDistanceSq = 0x7FFFFFFF
    For $i = 0 To UBound($a_af2_Path) - 1
        Local $l_f_DistanceSq = AddOns_ComputePseudoDistance($a_f_AnchorX, $a_f_AnchorY, $a_af2_Path[$i][0], $a_af2_Path[$i][1])
        If $l_f_DistanceSq < $l_f_NearestDistanceSq Then
            $l_f_NearestDistanceSq = $l_f_DistanceSq
            $l_i_Idx = $i
        EndIf
    Next
    Return $l_i_Idx
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_RouteEnterAndFollow
; Description....: Selects a prelude based on the player’s current zone (if any), executes it,
;                  then joins and follows the backbone path to its end. Falls back to direct join.
; Syntax.........: Pathing_RouteEnterAndFollow ( $a_i_MapID, $a_s_Type )
; Parameters.....: $a_i_MapID - Integer : Map ID containing the route.
;                  $a_s_Type  - String  : Route type key (e.g., "Herald").
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Map routes not found
;                            2 -> Route type not found
;                            3 -> Backbone path empty
;                            4 -> Player position unavailable
; Author.........: KleuTSchi
; Remarks........: - Zone check is inclusive on bounds; if multiple zones match, first hit wins.
;                  - Final move’s return is propagated as the function result.
; Related........: AddOns_GetXY_, AddOns_MoveTo, Pathing_GetNearestPathIndex, MapExists
; ===============================================================================================================================
Func Pathing_RouteEnterAndFollow($a_i_MapID, $a_s_Type)
    If Not MapExists($g_m_RouteTable, $a_i_MapID) Then Return SetError(1, 0, False)
    Local $l_m_TypeRoutes = $g_m_RouteTable[$a_i_MapID]
    If Not MapExists($l_m_TypeRoutes, $a_s_Type) Then Return SetError(2, 0, False)

    Local $l_m_RouteSpec = $l_m_TypeRoutes[$a_s_Type]
    Local $l_af2_Path = $l_m_RouteSpec["Path"]
    Local $l_a_Preludes = $l_m_RouteSpec["Preludes"]
    Local $l_af2_Zones = $l_m_RouteSpec["Zones"]

    Local $l_i_Rows = UBound($l_af2_Path)
    If $l_i_Rows = 0 Then Return SetError(3, 0, False)

    Local $l_i_PathLast = $l_i_Rows - 1

    Local $l_af_Pos = AddOns_GetXY_()
    If @error Or $l_af_Pos = 0 Then Return SetError(4, 0, False)

    Local $l_f_PosX = $l_af_Pos[0], $l_f_PosY = $l_af_Pos[1]

    Local $l_i_Chosen = -1
    For $i = 0 To UBound($l_af2_Zones) - 1
        If $l_f_PosX >= $l_af2_Zones[$i][0] And $l_f_PosX <= $l_af2_Zones[$i][2] And _
           $l_f_PosY >= $l_af2_Zones[$i][1] And $l_f_PosY <= $l_af2_Zones[$i][3] Then
            $l_i_Chosen = $i
            ExitLoop
        EndIf
    Next

    If $l_i_Chosen <> -1 Then
        Local $l_af2_Prelude = $l_a_Preludes[$l_i_Chosen]
        Local $l_i_PreludeLast = UBound($l_af2_Prelude) - 1

        For $p = 0 To $l_i_PreludeLast
            AddOns_MoveTo($l_af2_Prelude[$p][0], $l_af2_Prelude[$p][1])
        Next

        Local $l_i_Join = Pathing_GetNearestPathIndex($l_af2_Path, $l_af2_Prelude[$l_i_PreludeLast][0], $l_af2_Prelude[$l_i_PreludeLast][1])
        For $k = $l_i_Join To $l_i_PathLast
            If $k = $l_i_PathLast Then 
                Return AddOns_MoveTo($l_af2_Path[$k][0], $l_af2_Path[$k][1])
            Else
                AddOns_MoveTo($l_af2_Path[$k][0], $l_af2_Path[$k][1])
            EndIf
        Next
    EndIf

    Local $l_i_JoinDirect = Pathing_GetNearestPathIndex($l_af2_Path, $l_f_PosX, $l_f_PosY)
    For $k = $l_i_JoinDirect To $l_i_PathLast
        If $k = $l_i_PathLast Then 
            Return AddOns_MoveTo($l_af2_Path[$k][0], $l_af2_Path[$k][1])
        Else
            AddOns_MoveTo($l_af2_Path[$k][0], $l_af2_Path[$k][1])
        EndIf
    Next
    
    Return False
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_AddKainengRoutes
; Description....: Registers all Kaineng Center routes, their preludes, and zones.
; Syntax.........: Pathing_AddKainengRoutes ( )
; Parameters.....: None
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Flat arrays are converted to Nx2 with AddOns_ConvertFlatTo2DArray().
; Related........: AddOns_ConvertFlatTo2DArray, Pathing_AddPreludeToRoute, Pathing_AddRouteToMap
; ===============================================================================================================================
Func Pathing_AddKainengRoutes()
	Local $l_ai_FlatKainengCenter_RareMatTrader = [1495, -1195]
	Local $l_ai_FlatKainengCenter_Merchant = [1533, -1939]
	Local $l_ai_FlatKainengCenter_MerchantPreludeNorth = [1756, -1851]
	Local $l_ai_FlatKainengCenter_MerchantPreludeRareMatTrader= [1756, -1342, 1756, -1851]
	Local $l_ai_FlatKainengCenter_Chest = [2108,-2111, 1027, -3889, 1646, -4407]
	Local $l_ai_FlatKainengCenter_Herald = [2230, -1237]
	Local $l_ai_FlatKainengCenter_HeraldPreludeWest = [1495, -1195]
	Local $l_ai_FlatKainengCenter_HeraldPreludeMerchant = [1722, -1860]
	Local $l_ai_FlatKainengCenter_HeraldPreludeExchangeIGRO = [3666, -1067, 2972, -699]
	Local $l_ai_FlatKainengCenter_HeraldPreludeChest = [1027, -3889, 2354, -3503]
	Local $l_ai_FlatKainengCenter_ExchangeMC = [1864, -679]
	Local $l_ai_FlatKainengCenter_ExchangeMCPreludeWest = [1698, -902]
	Local $l_ai_FlatKainengCenter_ExchangeMCPreludeMerchant = [1722, -1860]
	Local $l_ai_FlatKainengCenter_ExchangeIGRO = [2972, -699, 3666, -1067, 4946, -1269]
	Pathing_AddRouteToMap($GC_I_MAP_ID_KAINENG_CENTER, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_KAINENG_CENTER, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_Merchant))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_MerchantPreludeNorth), 2220, 150, 3120, 1050)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_MerchantPreludeRareMatTrader), 1345, -1345, 1645, -1045)
	Pathing_AddRouteToMap($GC_I_MAP_ID_KAINENG_CENTER, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_KAINENG_CENTER, "Herald", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_Herald))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "Herald", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_HeraldPreludeWest), -1400, -1950, -500, -1050)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "Herald", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_HeraldPreludeMerchant), 1383, -2089, 1683, -1789)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "Herald", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_HeraldPreludeExchangeIGRO), 4796, -1419, 5096, -1119)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "Herald", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_HeraldPreludeChest), 1496, -4557, 1796, -4257)
	Pathing_AddRouteToMap($GC_I_MAP_ID_KAINENG_CENTER, "ExchangeMC", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_ExchangeMC))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "ExchangeMC", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_ExchangeMCPreludeWest), -1400, -1950, -500, -1050)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_KAINENG_CENTER, "ExchangeMC", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_ExchangeMCPreludeMerchant), 1383, -2089, 1683, -1789)
	Pathing_AddRouteToMap($GC_I_MAP_ID_KAINENG_CENTER, "ExchangeIGRO", AddOns_ConvertFlatTo2DArray($l_ai_FlatKainengCenter_ExchangeIGRO))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_AddGuildhallRoutes
; Description....: Registers route specs (backbones and preludes) for supported Guild Halls.
; Syntax.........: Pathing_AddGuildhallRoutes ( )
; Parameters.....: None
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Each hall defines trader, merchant, chest, and trade-spot routes as available.
; Related........: AddOns_ConvertFlatTo2DArray, Pathing_AddPreludeToRoute, Pathing_AddRouteToMap
; ===============================================================================================================================
Func Pathing_AddGuildhallRoutes()
	Local $l_ai_FlatGH_WarriorsIsle_RareMatTrader = [3625, 6014, 3883, 6014]
	Local $l_ai_FlatGH_WarriorsIsle_Merchant = [5523, 9052]
	Local $l_ai_FlatGH_WarriorsIsle_MerchantPreludeRareMatTrader= [3625, 6014]
	Local $l_ai_FlatGH_WarriorsIsle_Chest = [4229, 6918]
	Local $l_ai_FlatGH_WarriorsIsle_AutoTrade = [3840,7297]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WARRIORS_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WarriorsIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WARRIORS_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WarriorsIsle_Merchant))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_WARRIORS_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WarriorsIsle_MerchantPreludeRareMatTrader), 3733, 5864, 4033, 6164)
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WARRIORS_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WarriorsIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WARRIORS_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WarriorsIsle_AutoTrade))

	Local $l_ai_FlatGH_HuntersIsle_RareMatTrader = [4873, 8071, 3058, 6682]
	Local $l_ai_FlatGH_HuntersIsle_Merchant = [4168, 6307]
	Local $l_ai_FlatGH_HuntersIsle_Chest = [4662, 6590, 5087, 7413, 4937, 7563, 4747, 7496]
	Local $l_ai_FlatGH_HuntersIsle_AutoTrade = [4291, 7960]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_HUNTERS_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_HuntersIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_HUNTERS_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_HuntersIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_HUNTERS_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_HuntersIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_HUNTERS_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_HuntersIsle_AutoTrade))

	Local $l_ai_FlatGH_WizardsIsle_RareMatTrader = [3422, 9819]
	Local $l_ai_FlatGH_WizardsIsle_Merchant = [3588, 8993]
	Local $l_ai_FlatGH_WizardsIsle_Chest = [4780, 9749]
	Local $l_ai_FlatGH_WizardsIsle_AutoTrade = [5120, 9038]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WIZARDS_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WizardsIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WIZARDS_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WizardsIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WIZARDS_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WizardsIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_WIZARDS_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_WizardsIsle_AutoTrade))

	Local $l_ai_FlatGH_BurningIsle_RareMatTrader = [-2282, -18]
	Local $l_ai_FlatGH_BurningIsle_Merchant = [-2635, 1109]
	Local $l_ai_FlatGH_BurningIsle_Chest = [-4846, -2089, -5384, -2508]
	Local $l_ai_FlatGH_BurningIsle_AutoTrade = [-4549, -2569]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_BURNING_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_BurningIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_BURNING_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_BurningIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_BURNING_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_BurningIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_BURNING_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_BurningIsle_AutoTrade))

	Local $l_ai_FlatGH_FrozenIsle_RareMatTrader = [-1116, 3108]
	Local $l_ai_FlatGH_FrozenIsle_Merchant = [70, 3108, -214, 164]
	Local $l_ai_FlatGH_FrozenIsle_Chest = [-162, 3769]
	Local $l_ai_FlatGH_FrozenIsle_AutoTrade = [0, 4259]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_FROZEN_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_FrozenIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_FROZEN_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_FrozenIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_FROZEN_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_FrozenIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_FROZEN_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_FrozenIsle_AutoTrade))

	Local $l_ai_FlatGH_NomadsIsle_RareMatTrader = [3115, 4059, 392, 3589]
	Local $l_ai_FlatGH_NomadsIsle_Merchant = [5044, 4663]
	Local $l_ai_FlatGH_NomadsIsle_Chest = [4630, 4604]
	Local $l_ai_FlatGH_NomadsIsle_AutoTrade = [4465, 3997]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_NOMADS_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_NomadsIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_NOMADS_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_NomadsIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_NOMADS_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_NomadsIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_NOMADS_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_NomadsIsle_AutoTrade))

	Local $l_ai_FlatGH_DruidsIsle_RareMatTrader = [-1906, 4638, -1400, 4175, -1101, 4531]
	Local $l_ai_FlatGH_DruidsIsle_Merchant = [-2037, 3084]
	Local $l_ai_FlatGH_DruidsIsle_Chest = [-1911, 5482]
	Local $l_ai_FlatGH_DruidsIsle_AutoTrade = [-2300, 5885]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_DRUIDS_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_DruidsIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_DRUIDS_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_DruidsIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_DRUIDS_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_DruidsIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_DRUIDS_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_DruidsIsle_AutoTrade))

	Local $l_ai_FlatGH_IsleOfTheDead_RareMatTrader = [-3498, -1604]
	Local $l_ai_FlatGH_IsleOfTheDead_Merchant = [-4061, -1179]
	Local $l_ai_FlatGH_IsleOfTheDead_Chest = [-4603, -1531]
	Local $l_ai_FlatGH_IsleOfTheDead_AutoTrade = [-4799, -2160]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_THE_DEAD, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfTheDead_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_THE_DEAD, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfTheDead_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_THE_DEAD, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfTheDead_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_THE_DEAD, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfTheDead_AutoTrade))

	Local $l_ai_FlatGH_IsleOfWeepingStone_RareMatTrader = [-1640, 8912]
	Local $l_ai_FlatGH_IsleOfWeepingStone_Merchant = [-3977, 6794]
	Local $l_ai_FlatGH_IsleOfWeepingStone_Chest = [-1713, 7289]
	Local $l_ai_FlatGH_IsleOfWeepingStone_AutoTrade = [-990, 7330]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WEEPING_STONE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWeepingStone_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WEEPING_STONE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWeepingStone_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WEEPING_STONE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWeepingStone_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WEEPING_STONE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWeepingStone_AutoTrade))

	Local $l_ai_FlatGH_IsleOfJade_RareMatTrader = [6532, 2039]
	Local $l_ai_FlatGH_IsleOfJade_Merchant = [10190, 3199]
	Local $l_ai_FlatGH_IsleOfJade_Chest = [8652, 2732]
	Local $l_ai_FlatGH_IsleOfJade_AutoTrade = [8320, 3265]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_JADE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfJade_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_JADE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfJade_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_JADE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfJade_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_JADE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfJade_AutoTrade))

	Local $l_ai_FlatGH_ImperialIsle_RareMatTrader = [217, 11687]
	Local $l_ai_FlatGH_ImperialIsle_Merchant = [1891, 11609]
	Local $l_ai_FlatGH_ImperialIsle_Chest = [2283, 13211]
	Local $l_ai_FlatGH_ImperialIsle_AutoTrade = [1344, 12862]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_IMPERIAL_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_ImperialIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_IMPERIAL_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_ImperialIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_IMPERIAL_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_ImperialIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_IMPERIAL_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_ImperialIsle_AutoTrade))

	Local $l_ai_FlatGH_IsleOfMeditation_RareMatTrader = [467, 9714]
	Local $l_ai_FlatGH_IsleOfMeditation_Merchant = [-2197, 8099]
	Local $l_ai_FlatGH_IsleOfMeditation_Chest = [-732, 7688]
	Local $l_ai_FlatGH_IsleOfMeditation_AutoTrade = [-192, 7680]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_MEDITATION, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfMeditation_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_MEDITATION, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfMeditation_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_MEDITATION, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfMeditation_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_MEDITATION, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfMeditation_AutoTrade))

	Local $l_ai_FlatGH_Uncharted_RareMatTrader = [2525, -2304]
	Local $l_ai_FlatGH_Uncharted_Merchant = [1623, -2830]
	Local $l_ai_FlatGH_Uncharted_GeneralPreludeNorthSouth = [5002, -3750]
	Local $l_ai_FlatGH_Uncharted_Chest = [4508, -4477]
	Local $l_ai_FlatGH_Uncharted_AutoTrade = [5175, -3975]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_RareMatTrader))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_GeneralPreludeNorthSouth), 6261, -3574, 6561, -3274)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_GeneralPreludeNorthSouth), 6224, -4653, 6524, -4353)
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_Merchant))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_GeneralPreludeNorthSouth), 6261, -3574, 6561, -3274)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_GeneralPreludeNorthSouth), 6224, -4653, 6524, -4353)
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_UNCHARTED_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_Uncharted_AutoTrade))

	Local $l_ai_FlatGH_IsleOfWurms_RareMatTrader = [6468, 3119]
	Local $l_ai_FlatGH_IsleOfWurms_Merchant = [8218, 3498]
	Local $l_ai_FlatGH_IsleOfWurms_Chest = [8650, 3662]
	Local $l_ai_FlatGH_IsleOfWurms_AutoTrade = [8250, 2981]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WURMS, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWurms_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WURMS, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWurms_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WURMS, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWurms_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_WURMS, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfWurms_AutoTrade))

	Local $l_ai_FlatGH_CorruptedIsle_RareMatTrader = [-4368, 5534, -4618, 4811, -5554, 3942]
	Local $l_ai_FlatGH_CorruptedIsle_Merchant = [-4618, 4811, -4644, 5521]
	Local $l_ai_FlatGH_CorruptedIsle_Chest = [-4946, 6028]
	Local $l_ai_FlatGH_CorruptedIsle_AutoTrade = [-4035, 6562]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_CORRUPTED_ISLE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_CorruptedIsle_RareMatTrader))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_CORRUPTED_ISLE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_CorruptedIsle_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_CORRUPTED_ISLE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_CorruptedIsle_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_CORRUPTED_ISLE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_CorruptedIsle_AutoTrade))

	Local $l_ai_FlatGH_IsleOfSolitude_RareMatTrader = [3503, 3597, 3815, 4445]
	Local $l_ai_FlatGH_IsleOfSolitude_RareMatTraderPreludeEast = [4417, 2976]
	Local $l_ai_FlatGH_IsleOfSolitude_RareMatTraderPreludeWest = [2592, 3262]
	Local $l_ai_FlatGH_IsleOfSolitude_Merchant = [2970, 1652]
	Local $l_ai_FlatGH_IsleOfSolitude_Chest = [4490, 3059]
	Local $l_ai_FlatGH_IsleOfSolitude_AutoTrade = [4127, 3648]
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_SOLITUDE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfSolitude_RareMatTrader))
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_SOLITUDE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfSolitude_RareMatTraderPreludeEast), 4462, 2867, 4762, 3167)
	Pathing_AddPreludeToRoute($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_SOLITUDE, "RareMaterialTrader", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfSolitude_RareMatTraderPreludeWest), 2332, 3145, 2632, 3445)
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_SOLITUDE, "Merchant", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfSolitude_Merchant))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_SOLITUDE, "Chest", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfSolitude_Chest))
	Pathing_AddRouteToMap($GC_I_MAP_ID_GUILD_HALL_ISLE_OF_SOLITUDE, "TradeSpot", AddOns_ConvertFlatTo2DArray($l_ai_FlatGH_IsleOfSolitude_AutoTrade))
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_CreateRouteTable
; Description....: Populates the global route table for towns and guild halls.
; Syntax.........: Pathing_CreateRouteTable ( )
; Parameters.....: None
; Return values..: None (procedure)
; Author.........: KleuTSchi
; Remarks........: - Call once during initialization; idempotent if definitions are static.
; Related........: Pathing_AddGuildhallRoutes, Pathing_AddKainengRoutes
; ===============================================================================================================================
Func Pathing_CreateRouteTable()
    Pathing_AddKainengRoutes()
    Pathing_AddGuildhallRoutes()
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoHerald
; Description....: Routes to the Herald, interacts, and yields briefly.
; Syntax.........: Pathing_GoHerald ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to Herald failed
; Author.........: KleuTSchi
; Remarks........: - Intended for use with Herald of Purity in Kaineng Center; relies on nearest living NPC.
; Related........: AddOns_GetNearestAgent_NPCLiving, AddOns_Out, Agent_GoNPC, Other_PingSleep, Pathing_RouteEnterAndFollow     
; ===============================================================================================================================
Func Pathing_GoHerald($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "Herald") Then
		AddOns_Out("[ERR] Failed to reach Herald of Purity (Q18)")
		Return SetError(1, 0, False)
	EndIf
	Agent_GoNPC(AddOns_GetNearestAgent_NPCLiving())
	Other_PingSleep(500)
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoExchangeMC
; Description....: Routes to the MC exchange NPC, interacts, and yields briefly.
; Syntax.........: Pathing_GoExchangeMC ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to MC exchange failed
; Author.........: KleuTSchi
; Remarks........: - Intended for use with Ran Ti in Kaineng Center; relies on nearest living NPC.
; Related........: AddOns_GetNearestAgent_NPCLiving, AddOns_Out, Agent_GoNPC, Other_PingSleep, Pathing_RouteEnterAndFollow
; ===============================================================================================================================
Func Pathing_GoExchangeMC($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "ExchangeMC") Then
		AddOns_Out("[ERR] Failed to reach Ran Ti (MC)")
		Return SetError(1, 0, False)
	EndIf
	Agent_GoNPC(AddOns_GetNearestAgent_NPCLiving())
	Other_PingSleep(500)
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoExchangeIGRO
; Description....: Routes to the IGRO exchange NPC, interacts, and yields briefly.
; Syntax.........: Pathing_GoExchangeIGRO ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to IGRO exchange failed
; Author.........: KleuTSchi
; Remarks........: - Intended for use with Zan Lei in Kaineng Center; relies on nearest living NPC.
; Related........: AddOns_GetNearestAgent_NPCLiving, AddOns_Out, Agent_GoNPC, Other_PingSleep, _
;                  Pathing_RouteEnterAndFollow
; ===============================================================================================================================
Func Pathing_GoExchangeIGRO($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "ExchangeIGRO") Then 
		AddOns_Out("[ERR] Failed to reach Zan Lei (IGRO)")
		Return SetError(1, 0, False)
	EndIf
	Agent_GoNPC(AddOns_GetNearestAgent_NPCLiving())
	Other_PingSleep(500)
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoMerchant
; Description....: Routes to the Merchant, interacts, and yields briefly.
; Syntax.........: Pathing_GoMerchant ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to Merchant failed
; Author.........: KleuTSchi
; Remarks........: None
; Related........: AddOns_GetNearestAgent_NPCLiving, AddOns_Out, Agent_GoNPC, Other_PingSleep, Pathing_RouteEnterAndFollow
; ===============================================================================================================================
Func Pathing_GoMerchant($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "Merchant") Then
		AddOns_Out("[ERR] Failed to reach Merchant")
		Return SetError(1, 0, False)
	EndIf
	Agent_GoNPC(AddOns_GetNearestAgent_NPCLiving())
	Other_PingSleep(500)
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoRareMaterialTrader
; Description....: Routes to the Rare Material Trader, interacts, and yields briefly.
; Syntax.........: Pathing_GoRareMaterialTrader ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to Rare Material Trader failed
; Author.........: KleuTSchi
; Remarks........: None
; Related........: AddOns_GetNearestAgent_NPCLiving, AddOns_Out, Agent_GoNPC, Other_PingSleep, Pathing_RouteEnterAndFollow
; ===============================================================================================================================
Func Pathing_GoRareMaterialTrader($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "RareMaterialTrader") Then
		AddOns_Out("[ERR] Failed to reach Rare Material Trader")
		Return SetError(1, 0, False)
	EndIf
	Agent_GoNPC(AddOns_GetNearestAgent_NPCLiving())
	Other_PingSleep(500)
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoChest
; Description....: Routes to the Chest, interacts, and yields briefly.
; Syntax.........: Pathing_GoChest ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to Chest failed
; Author.........: KleuTSchi
; Remarks........: - Chest access needs to be unlocked
; Related........: AddOns_GetNearestAgent_NPCLiving, AddOns_Out, Agent_GoNPC, Other_PingSleep, Pathing_RouteEnterAndFollow
; ===============================================================================================================================
Func Pathing_GoChest($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "Chest") Then
		AddOns_Out("[ERR] Failed to reach Chest")
		Return SetError(1, 0, False)
	EndIf
	Agent_GoNPC(AddOns_GetNearestAgent_NPCLiving())
	Other_PingSleep(500)
	Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: Pathing_GoTradeSpot
; Description....: Routes to the designated trading spot.
; Syntax.........: Pathing_GoTradeSpot ( $a_i_MapID )
; Parameters.....: $a_i_MapID - Integer : Current map ID to route within.
; Return values..: Success - True
;                  Failure - False with @error set to:
;                            1 -> Route to trade spot failed
; Author.........: KleuTSchi
; Remarks........: - Intended for use with AutoTrade()
; Related........: AddOns_Out, Pathing_RouteEnterAndFollow
; ===============================================================================================================================
Func Pathing_GoTradeSpot($a_i_MapID)
	If Not Pathing_RouteEnterAndFollow($a_i_MapID, "TradeSpot") Then
		AddOns_Out("[ERR] Failed to reach assigned Trade Spot")
		Return SetError(1, 0, False)
	EndIf
	Return True
EndFunc