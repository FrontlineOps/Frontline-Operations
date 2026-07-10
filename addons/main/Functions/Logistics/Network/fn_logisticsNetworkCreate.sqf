params ["_network", ["_sideContext", sideUnknown], ["_savedState", false]];

if !(_sideContext in [east, west]) then {
    throw format ["Logistics network requires an explicit EAST/WEST side, got %1", _sideContext];
};
_network set ["_sideContext", _sideContext];
[_network, _sideContext] call FLO_fnc_logisticsNetworkSetManagedSide;

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
    if ("reinforcementQueue" in _savedState) then { _network set ["_reinforcementQueue", _savedState get "reinforcementQueue"]; };
    if ("hqObjectiveId" in _savedState) then { _network set ["_hqObjectiveId", _savedState get "hqObjectiveId"]; };

    if ("nodes" in _savedState) then {
        private _savedNodes = _savedState get "nodes";
        if !(_savedNodes isEqualType createHashMap) then {
            throw format ["Invalid saved logistics nodes for %1", _network get "_managedSideKey"];
        };

        private _typeConfigMap = _network get "NODE_TYPE_CONFIG";
        {
            private _node = _y;
            if !(_node isEqualType createHashMap) then {
                throw format ["Invalid saved logistics node %1", _x];
            };
            private _type = _node get "type";
            private _typeConfig = _typeConfigMap get _type;
            _typeConfig params ["_throughputMax", "_refillAmount", "_commanderSource", "_capabilities"];
            _node set ["throughputMax", _throughputMax];
            _node set ["throughput", ((_node get "throughput") max 0) min _throughputMax];
            _node set ["refillAmount", _refillAmount];
            _node set ["commanderSource", _commanderSource];
            _node set ["capabilities", +_capabilities];
            _node set ["baseNetId", ""];
            _savedNodes set [_x, _node];
        } forEach _savedNodes;
        _network set ["_nodes", _savedNodes];

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
_network set ["_recentReinforcementDispatches", []];
_network set ["_supplyRouteInfo", createHashMap];
_network set ["_activeSupplyNodes", createHashMap];
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
[_network] call FLO_fnc_logisticsNetworkStartMainLoop;
