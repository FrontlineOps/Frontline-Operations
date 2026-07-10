/*
 * Initializes one explicit logistics network for each combatant side. The
 * objective graph provides routes; persisted HQ/DEPOT/FOB nodes provide
 * commander sources, while COP nodes provide limited player sustainment.
 */
if (!isServer) exitWith {};
if ((keys FLO_Logistics_Networks) isNotEqualTo []) exitWith {};

private _groupCosts = createHashMapFromArray [
    ["infantry", 300],
    ["motorized", 800],
    ["mechanized", 1600],
    ["mobile_aa", 1800],
    ["armor", 2400],
    ["helicopter", 2200],
    ["air", 3500],
    ["jet", 5000],
    ["artillery", 3000],
    ["static_aa", 2600]
];

private _nodeTypeConfig = createHashMapFromArray [
    ["HQ", [10000, 2500, true, ["gear", "recruits", "cars", "armor", "helis", "planes", "naval", "static", "logistics"]]],
    ["DEPOT", [6000, 800, true, ["gear", "recruits", "cars", "armor", "helis", "planes", "naval", "static", "logistics"]]],
    ["FOB", [4000, 400, true, ["gear", "recruits", "cars", "armor", "helis", "static", "logistics"]]],
    ["COP", [800, 100, false, ["gear", "recruits", "cars"]]]
];

private _logisticsClass = [
    ["#type", "LogisticsNetwork"],

    ["GROUP_COSTS", _groupCosts],
    ["GROUP_THROUGHPUT_COSTS", _groupCosts],
    ["NODE_TYPE_CONFIG", _nodeTypeConfig],
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
    ["SUPPLY_CHAIN_DEPTH_METERS", 1500],
    ["SUPPLY_CHAIN_SOFT_REFRESH_INTERVAL", 60],
    ["NODE_OBJECTIVE_LINK_RADIUS", 3000],
    ["NODE_DELIVERY_RADIUS", 20],
    ["NODE_REFILL_INTERVAL", 180],
    ["SHIPMENT_THROUGHPUT", 1500],
    ["DEPOT_COST", 1000],
    ["DEPOT_MIN_SPACING", 6000],
    ["DEPOT_REQUIRED_DELIVERIES", 2],
    ["DEPOT_AUTO_ESTABLISH_SECONDS", 600],
    ["TRANSPORT_RESERVE_REPLENISH_GROUND_PER_CHECK", 1],
    ["TRANSPORT_RESERVE_REPLENISH_AIR_PER_CHECK", 1],
    ["OBJECTIVE_CAPTURE_FORCE_GROWTH", 0],
    ["OBJECTIVE_CAPTURE_GROWTH_DELAY_SECONDS", 900],

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
    ["_nodes", createHashMap],
    ["_hqNodeId", ""],
    ["_hqObjectiveId", ""],
    ["_initialInfrastructureSeeded", false],
    ["_lastNodeRefillAtDateNum", -1],
    ["_supplyRouteInfo", createHashMap],
    ["_activeSupplyNodes", createHashMap],
    ["_lastSupplyNodeSignature", ""],
    ["_supplyChainDirty", true],
    ["_objectiveSideIndexDirty", true],
    ["_lastSupplyChainRefreshAt", -1],
    ["_managedObjectiveIds", []],
    ["_enemyObjectiveIds", []],
    ["_targetPicture", createHashMap],
    ["_spawnRoadCache", createHashMap],
    ["_dispatchRoleCache", createHashMap],
    ["_dispatchBranchCache", createHashMap],
    ["_dispatchEnemyDistanceCache", createHashMap],
    ["_dispatchSourceableCache", createHashMap],
    ["_dispatchDeliveryObjectiveCache", createHashMap],

    ["#create", { ([_self] + _this) call FLO_fnc_logisticsNetworkCreate }],
    ["_setManagedSide", { ([_self] + _this) call FLO_fnc_logisticsNetworkSetManagedSide }],
    ["_refreshManagedSide", { [_self] call FLO_fnc_logisticsNetworkRefreshManagedSide }],
    ["_getManagedResourceObject", { FLO_SideResources get (_self get "_managedSideKey") }],
    ["_objectiveHasStaticAA", { ([_self] + _this) call FLO_fnc_logisticsNetworkObjectiveHasStaticAA }],
    ["_objectiveIsCollapsePressure", { ([_self] + _this) call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure }],
    ["_getRearAATargets", { [_self] call FLO_fnc_logisticsNetworkGetRearAATargets }],
    ["_captureInitialComposition", { [_self] call FLO_fnc_logisticsNetworkGetComposition }],
    ["_getCurrentComposition", { [_self] call FLO_fnc_logisticsNetworkGetComposition }],
    ["_applyObjectiveCaptureGrowth", { ([_self] + _this) call FLO_fnc_logisticsNetworkApplyObjectiveCaptureGrowth }],
    ["_processPendingCaptureGrowth", { [_self] call FLO_fnc_logisticsNetworkProcessPendingCaptureGrowth }],
    ["_pickBestTarget", { ([_self] + _this) call FLO_fnc_logisticsNetworkPickBestTarget }],
    ["_pickHQObjective", { [_self] call FLO_fnc_logisticsNetworkPickHQObjective }],
    ["_refreshSupplyChain", { [_self] call FLO_fnc_logisticsNetworkRefreshSupplyChain }],
    ["_ensureSupplyChainFresh", { ([_self] + _this) call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh }],
    ["_markSupplyChainDirty", { ([_self] + _this) call FLO_fnc_logisticsNetworkMarkSupplyChainDirty }],
    ["_refreshObjectiveSideIndex", { [_self] call FLO_fnc_logisticsNetworkRefreshObjectiveSideIndex }],
    ["_describeObjectiveSupplyRole", { ([_self] + _this) call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole }],
    ["_buildTargetPicture", { ([_self] + _this) call FLO_fnc_logisticsNetworkBuildTargetPicture }],
    ["_getCachedSpawnPosition", { ([_self] + _this) call FLO_fnc_logisticsNetworkGetCachedSpawnPosition }],
    ["_buildInboundObjectiveCounts", { [_self] call FLO_fnc_logisticsNetworkBuildInboundObjectiveCounts }],
    ["_buildRecentDispatchCounts", { [_self] call FLO_fnc_logisticsNetworkBuildRecentDispatchCounts }],
    ["_canDispatchToObjective", { ([_self] + _this) call FLO_fnc_logisticsNetworkCanDispatchToObjective }],
    ["_pickDeliveryObjective", { ([_self] + _this) call FLO_fnc_logisticsNetworkPickDeliveryObjective }],
    ["_pickSpawnSourceObjective", { ([_self] + _this) call FLO_fnc_logisticsNetworkPickSpawnSourceObjective }],
    ["_findSupplySourceObjective", { ([_self] + _this) call FLO_fnc_logisticsNetworkFindSupplySourceObjective }],
    ["_findSpawnPosition", { ([_self] + _this) call FLO_fnc_logisticsNetworkFindSpawnPosition }],
    ["_findReinforcementTargets", { [_self] call FLO_fnc_logisticsNetworkFindReinforcementTargets }],
    ["_createReplacement", { ([_self] + _this) call FLO_fnc_logisticsNetworkCreateReplacement }],
    ["_recordReplacement", { ([_self] + _this) call FLO_fnc_logisticsNetworkRecordReplacement }],
    ["_recordTargetDispatch", { ([_self] + _this) call FLO_fnc_logisticsNetworkRecordTargetDispatch }],
    ["_replenishTransportReserves", { [_self] call FLO_fnc_logisticsNetworkReplenishTransportReserves }],
    ["_recordDelivery", { ([_self] + _this) call FLO_fnc_logisticsNetworkRecordDelivery }],
    ["_startMainLoop", { [_self] call FLO_fnc_logisticsNetworkStartMainLoop }],
    ["_checkAndReplace", { [_self] call FLO_fnc_logisticsNetworkCheckAndReplace }],
    ["getStats", { _self get "_stats" }],
    ["getSideSnapshot", { [_self] call FLO_fnc_logisticsNetworkGetSideSnapshot }],
    ["forceCheck", { [_self] call FLO_fnc_logisticsNetworkCheckAndReplace }],
    ["setEnabled", {
        params ["_enabled"];
        _self set ["_enabled", _enabled];
        ["LOGISTICS", 3, format ["Logistics network %1", ["disabled", "enabled"] select _enabled]] call FLO_fnc_log;
    }],
    ["serialize", { [_self] call FLO_fnc_logisticsNetworkSerialize }]
];

private _savedBySide = createHashMap;
if (!isNil "FLO_SavedGameData" && {"logisticsNetworkBySide" in FLO_SavedGameData}) then {
    _savedBySide = FLO_SavedGameData get "logisticsNetworkBySide";
    if !(_savedBySide isEqualType createHashMap) then {
        throw format ["Invalid saved logisticsNetworkBySide payload: %1", typeName _savedBySide];
    };
};

FLO_Logistics_Networks = createHashMap;
{
    private _side = _x;
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    private _savedPayload = false;
    if (_sideKey in _savedBySide) then { _savedPayload = _savedBySide get _sideKey; };
    private _network = createHashMapObject [_logisticsClass, [_side, _savedPayload]];
    _network set ["OBJECTIVE_CAPTURE_FORCE_GROWTH", (([_side, "forceGrowth"] call FLO_fnc_gtnGetSideCommanderHandle) get "value")];
    FLO_Logistics_Networks set [_sideKey, _network];
} forEach [east, west];

["LOGISTICS", 2, "Initialized explicit WEST/EAST logistics networks"] call FLO_fnc_log;
