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
        ["armor", 32],
        ["helicopter", 24],
        ["air", 32],
        ["jet", 36],
        ["artillery", 42],
        ["static_aa", 64]
    ]],

    ["CHECK_INTERVAL", 60],
    ["BLUFOR_DETECT_RANGE", 2000],
    ["DISPATCH_MIN_INTERVAL", 30],
    ["DISPATCH_MAX_INTERVAL", 90],
    ["DISPATCH_BATCH_MIN", 12],
    ["DISPATCH_BATCH_MAX", 64],
    ["REINFORCEMENT_RECENT_TARGET_WINDOW", 300],
    ["REINFORCEMENT_BATCH_TARGET_PENALTY", 2400],
    ["REINFORCEMENT_INBOUND_TARGET_PENALTY", 1800],
    ["REINFORCEMENT_RECENT_TARGET_PENALTY", 1400],
    ["REINFORCEMENT_LAST_TARGET_PENALTY", 900],
    ["REINFORCEMENT_OBJECTIVE_SECURE_RATIO", 1.75],
    ["REINFORCEMENT_OBJECTIVE_PRESSURE_PER_GROUP", 10],
    ["REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MIN", 1],
    ["REINFORCEMENT_OBJECTIVE_INBOUND_CAP_MAX", 4],
    ["REINFORCEMENT_OBJECTIVE_BATCH_CAP_MAX", 2],
    ["REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_FORCE_RATIO", 0.65],
    ["REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_INBOUND_CAP", 1],
    ["REINFORCEMENT_DELIVERY_MIN_ENEMY_DISTANCE", 900],
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
            ["nextDispatchAt", _self get "_nextDispatchAt"]
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
