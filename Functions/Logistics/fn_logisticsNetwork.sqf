/*
 * Function: FLO_fnc_logisticsNetwork
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes side-scoped logistics network objects for EAST and WEST.
 *   The network maintains replacement queues, dispatch cadence, and
 *   reinforcement state while delegating operational logic to registered
 *   helper functions under Functions\Logistics\Network.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 */

if (!isServer) exitWith {};

if (!isNil "FLO_Logistics_Networks" && {FLO_Logistics_Networks isEqualType createHashMap} && {count (keys FLO_Logistics_Networks) > 0}) exitWith {};

FLO_Logistics_Networks = createHashMap;
private _groupsPerObjectiveCapture = FLO_GTN_ForceGrowthHandle get "value";

private _logisticsClass = [
    ["#type", "LogisticsNetwork"],

    ["GROUP_COSTS", createHashMapFromArray [
        ["infantry", 6],
        ["motorized", 12],
        ["mechanized", 24],
        ["mobile_aa", 28],
        ["armor", 32],
        ["helicopter", 24],
        ["air", 32],
        ["jet", 36],
        ["artillery", 42],
        ["static_aa", 64]
    ]],

    ["CHECK_INTERVAL", 15],
    ["BLUFOR_DETECT_RANGE", 2000],
    ["DISPATCH_MIN_INTERVAL", 30],
    ["DISPATCH_MAX_INTERVAL", 90],
    ["DISPATCH_BATCH_MIN", 12],
    ["DISPATCH_BATCH_MAX", 64],
    ["DISPATCH_TIME_BUDGET_MS", 200],
    ["DISPATCH_BACKLOG_RETRY_INTERVAL", 15],
    ["REINFORCEMENT_RECENT_TARGET_WINDOW", 300],
    ["REINFORCEMENT_OBJECTIVE_SECURE_RATIO", 1.75],
    ["REINFORCEMENT_OBJECTIVE_PRESSURE_PER_GROUP", 10],
    ["REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MIN", 1],
    ["REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MAX", 4],
    ["REINFORCEMENT_OBJECTIVE_BATCH_CAP_MAX", 2],
    ["REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_FORCE_RATIO", 0.65],
    ["REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_INBOUND_CAP", 1],
    ["REINFORCEMENT_DELIVERY_MIN_ENEMY_DISTANCE", 900],
    ["SUPPLY_CHAIN_MAX_HOP_ROUTE_METERS", 14000],
    ["SUPPLY_ADVANCE_OBJECTIVE_INBOUND_CAP", 2],
    ["SUPPLY_ADVANCE_OBJECTIVE_BATCH_CAP", 1],
    ["SUPPLY_NODE_MIN_DELIVERIES", 2],
    ["SUPPLY_NODE_PROMOTION_DELIVERY_COUNT", 4],
    ["SUPPLY_NODE_MIN_ACTIVE_FRIENDLY_COUNT", 6],
    ["SUPPLY_NODE_RESET_FRIENDLY_COUNT", 2],
    ["TRANSPORT_RESERVE_REPLENISH_GROUND_PER_CHECK", 1],
    ["TRANSPORT_RESERVE_REPLENISH_AIR_PER_CHECK", 1],
    ["OBJECTIVE_CAPTURE_FORCE_GROWTH", _groupsPerObjectiveCapture],

    ["_initialComposition", nil],
    ["_lastUpdate", 0],
    ["_stats", nil],
    ["_enabled", true],
    ["_lastReinforcementTarget", ""],
    ["_recentReinforcementDispatches", []],
    ["_sideContext", sideUnknown],
    ["_managedSide", east],
    ["_managedSideKey", "EAST"],
    ["_enemySide", west],
    ["_reinforcementQueue", []],
    ["_nextDispatchAt", 0],
    ["_loopStarted", false],
    ["_loopPfhId", -1],
    ["_hqObjectiveId", ""],
    ["_supplyNodeDeliveries", createHashMap],
    ["_supplyRouteInfo", createHashMap],
    ["_activeSupplyNodes", createHashMap],
    ["_lastSupplyNodeSignature", ""],
    ["_spawnRoadCache", createHashMap],
    ["_dispatchRoleCache", createHashMap],
    ["_dispatchBranchCache", createHashMap],
    ["_dispatchEnemyDistanceCache", createHashMap],
    ["_dispatchSourceableCache", createHashMap],
    ["_dispatchDeliveryObjectiveCache", createHashMap],

    ["#create", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkCreate;
    }],

    ["_setManagedSide", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkSetManagedSide;
    }],

    ["_refreshManagedSide", {
        [_self] call FLO_fnc_logisticsNetworkRefreshManagedSide;
    }],

    ["_getManagedResourceObject", {
        FLO_SideResources get (_self get "_managedSideKey")
    }],

    ["_objectiveHasStaticAA", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkObjectiveHasStaticAA;
    }],

    ["_objectiveIsCollapsePressure", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure;
    }],

    ["_getRearAATargets", {
        [_self] call FLO_fnc_logisticsNetworkGetRearAATargets;
    }],

    ["_captureInitialComposition", {
        [_self] call FLO_fnc_logisticsNetworkGetComposition;
    }],

    ["_getCurrentComposition", {
        [_self] call FLO_fnc_logisticsNetworkGetComposition;
    }],

    ["_applyObjectiveCaptureGrowth", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkApplyObjectiveCaptureGrowth;
    }],

    ["_pickBestTarget", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkPickBestTarget;
    }],

    ["_pickHQObjective", {
        [_self] call FLO_fnc_logisticsNetworkPickHQObjective;
    }],

    ["_refreshSupplyChain", {
        [_self] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
    }],

    ["_describeObjectiveSupplyRole", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    }],

    ["_findSupplyAdvanceObjectives", {
        [_self] call FLO_fnc_logisticsNetworkFindSupplyAdvanceObjectives;
    }],

    ["_getCachedSpawnPosition", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkGetCachedSpawnPosition;
    }],

    ["_buildInboundObjectiveCounts", {
        [_self] call FLO_fnc_logisticsNetworkBuildInboundObjectiveCounts;
    }],

    ["_buildRecentDispatchCounts", {
        [_self] call FLO_fnc_logisticsNetworkBuildRecentDispatchCounts;
    }],

    ["_canDispatchToObjective", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkCanDispatchToObjective;
    }],

    ["_pickDeliveryObjective", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkPickDeliveryObjective;
    }],

    ["_pickSpawnSourceObjective", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkPickSpawnSourceObjective;
    }],

    ["_findSupplySourceObjective", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
    }],

    ["_findSpawnPosition", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkFindSpawnPosition;
    }],

    ["_findReinforcementTargets", {
        [_self] call FLO_fnc_logisticsNetworkFindReinforcementTargets;
    }],

    ["_createReplacement", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkCreateReplacement;
    }],

    ["_recordReplacement", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkRecordReplacement;
    }],

    ["_recordTargetDispatch", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkRecordTargetDispatch;
    }],

    ["_replenishTransportReserves", {
        [_self] call FLO_fnc_logisticsNetworkReplenishTransportReserves;
    }],

    ["_recordDelivery", {
        ([_self] + _this) call FLO_fnc_logisticsNetworkRecordDelivery;
    }],

    ["_startMainLoop", {
        [_self] call FLO_fnc_logisticsNetworkStartMainLoop;
    }],

    ["_checkAndReplace", {
        [_self] call FLO_fnc_logisticsNetworkCheckAndReplace;
    }],

    ["getStats", {
        _self get "_stats"
    }],

    ["forceCheck", {
        [_self] call FLO_fnc_logisticsNetworkCheckAndReplace;
    }],

    ["setEnabled", {
        params ["_enabled"];
        _self set ["_enabled", _enabled];
        ["LOGISTICS", 3, format ["Logistics network %1", if (_enabled) then { "enabled" } else { "disabled" }]] call FLO_fnc_log;
    }],

    ["serialize", {
        createHashMapFromArray [
            ["initialComposition", _self get "_initialComposition"],
            ["stats", _self get "_stats"],
            ["lastReinforcementTarget", _self get "_lastReinforcementTarget"],
            ["reinforcementQueue", _self get "_reinforcementQueue"],
            ["nextDispatchAt", _self get "_nextDispatchAt"],
            ["hqObjectiveId", _self get "_hqObjectiveId"],
            ["supplyNodeDeliveries", _self get "_supplyNodeDeliveries"]
        ]
    }]
];

private _savedBySide = createHashMap;
if (!isNil "FLO_SavedGameData" && {FLO_SavedGameData isEqualType createHashMap}) then {
    private _savedMap = FLO_SavedGameData getOrDefault ["logisticsNetworkBySide", createHashMap];
    if (_savedMap isEqualType createHashMap) then {
        _savedBySide = _savedMap;
    };
};

{
    private _side = _x;
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    private _savedPayload = _savedBySide getOrDefault [_sideKey, false];
    private _net = createHashMapObject [_logisticsClass, [_side, _savedPayload]];
    FLO_Logistics_Networks set [_sideKey, _net];
} forEach [east, west];

["LOGISTICS", 2, "Logistics Networks initialized for EAST/WEST contexts"] call FLO_fnc_log;
