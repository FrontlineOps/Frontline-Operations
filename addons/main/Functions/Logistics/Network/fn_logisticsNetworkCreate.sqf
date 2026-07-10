params ["_network", ["_sideContext", sideUnknown], ["_savedState", false]];

if !(_sideContext in [east, west]) then {
    throw format ["Logistics network requires an explicit EAST/WEST side, got %1", _sideContext];
};
_network set ["_sideContext", _sideContext];
[_network, _sideContext] call FLO_fnc_logisticsNetworkSetManagedSide;
private _managedSideKey = _network get "_managedSideKey";

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

if (_savedState isEqualType createHashMap) then {
    if ("stats" in _savedState) then {
        private _savedStats = _savedState get "stats";
        if !(_savedStats isEqualType createHashMap) then {
            throw format ["Invalid saved logistics stats for %1", _network get "_managedSideKey"];
        };
        {
            if (_x in _savedStats) then { _stats set [_x, _savedStats get _x]; };
        } forEach (keys _stats);
    };

    if ("initialComposition" in _savedState) then { _network set ["_initialComposition", _savedState get "initialComposition"]; };
    if ("lastReinforcementTarget" in _savedState) then { _network set ["_lastReinforcementTarget", _savedState get "lastReinforcementTarget"]; };
    if ("reinforcementQueue" in _savedState) then { _network set ["_reinforcementQueue", +(_savedState get "reinforcementQueue")]; };
    if ("hqObjectiveId" in _savedState) then { _network set ["_hqObjectiveId", _savedState get "hqObjectiveId"]; };

    if ("nodes" in _savedState) then {
        private _savedNodes = _savedState get "nodes";
        if !(_savedNodes isEqualType createHashMap) then {
            throw format ["Invalid saved logistics nodes for %1", _network get "_managedSideKey"];
        };

        private _typeConfigMap = _network get "NODE_TYPE_CONFIG";
        private _restoredNodes = createHashMap;
        private _foreignNodeIds = [];
        {
            private _nodeId = _x;
            private _savedNode = _y;
            if !(_savedNode isEqualType createHashMap) then {
                throw format ["Invalid saved logistics node %1", _nodeId];
            };
            private _nodeSideKey = _savedNode get "sideKey";
            if !(_nodeSideKey isEqualType "" && {_nodeSideKey in ["WEST", "EAST"]}) then {
                throw format ["Invalid saved logistics node side for %1: %2", _nodeId, _nodeSideKey];
            };
            if (_nodeSideKey != _managedSideKey) then {
                _foreignNodeIds pushBack _nodeId;
                continue;
            };

            private _node = createHashMap;
            {
                _node set [_x, _savedNode get _x];
            } forEach (keys _savedNode);

            private _type = _node get "type";
            private _typeConfig = _typeConfigMap get _type;
            _typeConfig params ["_throughputMax", "_refillAmount", "_commanderSource", "_capabilities"];
            _node set ["throughputMax", _throughputMax];
            _node set ["throughput", ((_node get "throughput") max 0) min _throughputMax];
            _node set ["refillAmount", _refillAmount];
            _node set ["commanderSource", _commanderSource];
            _node set ["capabilities", +_capabilities];
            _node set ["position", +(_node get "position")];
            _node set ["baseNetId", ""];
            _restoredNodes set [_nodeId, _node];
        } forEach _savedNodes;
        _network set ["_nodes", _restoredNodes];

        if (_foreignNodeIds isNotEqualTo []) then {
            ["LOGISTICS", 2, format [
                "Repaired shared-node save contamination for %1 by removing %2 foreign nodes: %3",
                _managedSideKey,
                count _foreignNodeIds,
                _foreignNodeIds
            ]] call FLO_fnc_log;
        };

        _network set ["_hqNodeId", _savedState get "hqNodeId"];
        _network set ["_initialInfrastructureSeeded", _savedState get "initialInfrastructureSeeded"];
        _network set ["_lastNodeRefillAtDateNum", _savedState get "lastNodeRefillAtDateNum"];
    };

    if ("nextDispatchAt" in _savedState) then {
        private _savedNextDispatchAt = _savedState get "nextDispatchAt";
        private _maxDelay = _network get "DISPATCH_MAX_INTERVAL";
        if (_savedNextDispatchAt > time && {(_savedNextDispatchAt - time) <= _maxDelay}) then {
            _network set ["_nextDispatchAt", _savedNextDispatchAt];
        };
    };
};

_network set ["_stats", _stats];
_network set ["_lastSupplyNodeSignature", ""];
_network set ["_supplyChainDirty", true];
_network set ["_objectiveSideIndexDirty", true];
_network set ["_lastSupplyChainRefreshAt", -1];
_network set ["_lastUpdate", time];

if ((_network get "_nextDispatchAt") <= time) then {
    private _minInterval = _network get "DISPATCH_MIN_INTERVAL";
    private _maxInterval = _network get "DISPATCH_MAX_INTERVAL";
    _network set ["_nextDispatchAt", time + _minInterval + random (_maxInterval - _minInterval)];
};

{
    if ((_x getVariable ["FLO_BaseSide", sideUnknown]) isEqualTo (_network get "_managedSide")) then {
        [_network, _x] call FLO_fnc_logisticsNetworkRegisterBaseNode;
    };
} forEach FLO_CampaignBases;

[_network] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
[_network] call FLO_fnc_logisticsNetworkValidateNodeOwnership;
[_network] call FLO_fnc_logisticsNetworkStartMainLoop;
