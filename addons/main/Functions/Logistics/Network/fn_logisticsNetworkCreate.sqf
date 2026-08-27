params ["_network", ["_sideContext", sideUnknown], ["_savedState", false]];

if !(_sideContext in [east, west]) then {
    throw format ["Logistics network requires an explicit EAST/WEST side, got %1", _sideContext];
};
_network set ["_sideContext", _sideContext];
[_network, _sideContext] call FLO_fnc_logisticsNetworkSetManagedSide;
private _managedSideKey = _network get "_managedSideKey";
private _dispatchDelay = -1;

// HashMapObject class values are shared references unless each instance owns
// fresh mutable state explicitly.
_network set ["_reinforcementQueue", []];
_network set ["_recentReinforcementDispatches", []];
_network set ["_nodes", createHashMap];
_network set ["_supplyRouteInfo", createHashMap];
_network set ["_activeSupplyNodes", createHashMap];
_network set ["_managedObjectiveIds", []];
_network set ["_enemyObjectiveIds", []];
_network set ["_targetPicture", createHashMap];
_network set ["_spawnRoadCache", createHashMap];
_network set ["_dispatchRoleCache", createHashMap];
_network set ["_dispatchBranchCache", createHashMap];
_network set ["_dispatchEnemyDistanceCache", createHashMap];
_network set ["_dispatchSourceableCache", createHashMap];
_network set ["_dispatchDeliveryObjectiveCache", createHashMap];

private _stats = createHashMapFromArray [
    ["totalReplacements", 0],
    ["resourcesSpent", 0],
    ["byType", createHashMap],
    ["captureGrowthAppliedGroups", 0],
    ["captureGrowthEvents", 0],
    ["reinforcementDeliveries", 0],
    ["supplyShipments", 0]
];

if (_savedState isNotEqualTo false) then {
    if !(_savedState isEqualType createHashMap) then {
        throw format ["Invalid saved logistics state for %1: %2", _managedSideKey, typeName _savedState];
    };
    private _requiredStateFields = [
        "initialComposition",
        "stats",
        "lastReinforcementTarget",
        "reinforcementQueue",
        "nextDispatchAt",
        "nodes",
        "hqNodeId",
        "hqObjectiveId",
        "initialInfrastructureSeeded",
        "lastNodeRefillAtDateNum"
    ];
    private _missingStateFields = _requiredStateFields select { !(_x in _savedState) };
    if (_missingStateFields isNotEqualTo []) then {
        throw format ["Saved %1 logistics state is missing fields %2", _managedSideKey, _missingStateFields];
    };
    private _savedStats = _savedState get "stats";
    if !(_savedStats isEqualType createHashMap) then {
        throw format ["Invalid saved logistics stats for %1", _managedSideKey];
    };
    private _missingStatFields = (keys _stats) select { !(_x in _savedStats) };
    if (_missingStatFields isNotEqualTo []) then {
        throw format ["Saved %1 logistics stats are missing fields %2", _managedSideKey, _missingStatFields];
    };
    _stats = createHashMap;
    {
        _stats set [_x, _y];
    } forEach _savedStats;

    private _initialComposition = _savedState get "initialComposition";
    private _lastReinforcementTarget = _savedState get "lastReinforcementTarget";
    private _reinforcementQueue = _savedState get "reinforcementQueue";
    private _hqObjectiveId = _savedState get "hqObjectiveId";
    if !(_initialComposition isEqualType createHashMap) then {
        throw format ["Invalid saved %1 initial composition", _managedSideKey];
    };
    if !(_lastReinforcementTarget isEqualType "" && {_reinforcementQueue isEqualType []} && {_hqObjectiveId isEqualType ""}) then {
        throw format ["Invalid saved %1 logistics routing state", _managedSideKey];
    };
    _network set ["_initialComposition", _initialComposition];
    _network set ["_lastReinforcementTarget", _lastReinforcementTarget];
    _network set ["_reinforcementQueue", +_reinforcementQueue];
    _network set ["_hqObjectiveId", _hqObjectiveId];

    private _savedNodes = _savedState get "nodes";
    if !(_savedNodes isEqualType createHashMap) then {
        throw format ["Invalid saved logistics nodes for %1", _managedSideKey];
    };

    private _requiredNodeFields = [
        "id", "sideKey", "type", "anchorKind", "anchorId", "objectiveId", "position", "state",
        "throughput", "deliveryCount", "lastPlayerDeliveryAmount", "lastPlayerDeliveryAtDateNum",
        "lastPlayerContributorName", "requiredDeliveries", "establishAtDateNum", "baseNetId", "upstreamNodeId"
    ];
    private _typeConfigMap = _network get "NODE_TYPE_CONFIG";
    private _validNodeStates = ["CONNECTED", "STRAINED", "ISOLATED", "DISABLED", "ESTABLISHING"];
    private _restoredNodes = createHashMap;
    {
        private _nodeId = _x;
        private _savedNode = _y;
        if !(_nodeId isEqualType "" && {_nodeId != ""} && {_savedNode isEqualType createHashMap}) then {
            throw format ["Invalid saved %1 logistics node %2", _managedSideKey, _nodeId];
        };
        private _missingNodeFields = _requiredNodeFields select { !(_x in _savedNode) };
        if (_missingNodeFields isNotEqualTo []) then {
            throw format ["Saved %1 logistics node %2 is missing fields %3", _managedSideKey, _nodeId, _missingNodeFields];
        };
        if ((_savedNode get "id") != _nodeId || {(_savedNode get "sideKey") != _managedSideKey}) then {
            throw format ["Saved %1 logistics node %2 has inconsistent identity", _managedSideKey, _nodeId];
        };

        private _type = _savedNode get "type";
        private _typeConfig = _typeConfigMap get _type;
        if !(_typeConfig isEqualType [] && {(count _typeConfig) == 4}) then {
            throw format ["Saved %1 logistics node %2 has invalid type %3", _managedSideKey, _nodeId, _type];
        };
        _typeConfig params ["_throughputMax", "_refillAmount", "_commanderSource", "_capabilities"];
        private _throughput = _savedNode get "throughput";
        if !(_throughput isEqualType 0 && {_throughput >= 0} && {_throughput <= _throughputMax}) then {
            throw format ["Saved %1 logistics node %2 has invalid throughput %3", _managedSideKey, _nodeId, _throughput];
        };
        private _savedState = _savedNode get "state";
        if !(_savedState in _validNodeStates) then {
            throw format ["Saved %1 logistics node %2 has invalid state %3", _managedSideKey, _nodeId, _savedState];
        };
        if (_savedState == "ESTABLISHING") then {
            if (_type != "DEPOT" || {(_savedNode get "requiredDeliveries") != (_network get "DEPOT_REQUIRED_DELIVERIES")}) then {
                throw format ["Saved %1 logistics node %2 has invalid establishment state", _managedSideKey, _nodeId];
            };
        };

        private _node = createHashMap;
        {
            _node set [_x, _y];
        } forEach _savedNode;
        _node set ["position", +(_savedNode get "position")];
        _node set ["throughputMax", _throughputMax];
        _node set ["refillAmount", _refillAmount];
        _node set ["commanderSource", _commanderSource];
        _node set ["capabilities", +_capabilities];
        _restoredNodes set [_nodeId, _node];
    } forEach _savedNodes;
    _network set ["_nodes", _restoredNodes];

    private _hqNodeId = _savedState get "hqNodeId";
    private _initialInfrastructureSeeded = _savedState get "initialInfrastructureSeeded";
    private _lastNodeRefillAtDateNum = _savedState get "lastNodeRefillAtDateNum";
    if !(_hqNodeId isEqualType "" && {_initialInfrastructureSeeded isEqualType false} && {_lastNodeRefillAtDateNum isEqualType 0}) then {
        throw format ["Invalid saved %1 logistics infrastructure state", _managedSideKey];
    };
    _network set ["_hqNodeId", _hqNodeId];
    _network set ["_initialInfrastructureSeeded", _initialInfrastructureSeeded];
    _network set ["_lastNodeRefillAtDateNum", _lastNodeRefillAtDateNum];

    private _savedNextDispatchAt = _savedState get "nextDispatchAt";
    if !(_savedNextDispatchAt isEqualType 0 && {_savedNextDispatchAt >= 0}) then {
        throw format ["Invalid saved %1 logistics dispatch deadline %2", _managedSideKey, _savedNextDispatchAt];
    };
    private _maxDelay = _network get "DISPATCH_MAX_INTERVAL";
    if (_savedNextDispatchAt > time && {(_savedNextDispatchAt - time) <= _maxDelay}) then {
        _dispatchDelay = _savedNextDispatchAt - time;
    };
};

_network set ["_stats", _stats];
_network set ["_lastSupplyNodeSignature", ""];
_network set ["_supplyChainDirty", true];
_network set ["_objectiveSideIndexDirty", true];
_network set ["_lastSupplyChainRefreshAt", -1];
_network set ["_lastUpdate", time];
_network set ["_nextDepotPlanningAtTick", diag_tickTime];

if (_dispatchDelay < 0) then {
    private _minInterval = _network get "DISPATCH_MIN_INTERVAL";
    private _maxInterval = _network get "DISPATCH_MAX_INTERVAL";
    _dispatchDelay = _minInterval + random (_maxInterval - _minInterval);
};
_network set ["_nextDispatchAtTick", diag_tickTime + _dispatchDelay];
_network set ["_nextDispatchAt", time + _dispatchDelay];

{
    if ((_x getVariable ["FLO_BaseSide", sideUnknown]) isEqualTo (_network get "_managedSide")) then {
        [_network, _x] call FLO_fnc_logisticsNetworkRegisterBaseNode;
    };
} forEach FLO_CampaignBases;

[_network] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
[_network] call FLO_fnc_logisticsNetworkValidateNodeOwnership;
[_network] call FLO_fnc_logisticsNetworkStartMainLoop;
