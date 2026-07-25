/*
 * Rebuilds route reachability only when topology is dirty, then refreshes node
 * state and commander sources from explicit connected HQ/DEPOT/FOB nodes.
 */
params ["_network"];

private _t0 = diag_tickTime;
private _managedSide = _network get "_managedSide";
private _previousSignature = _network get "_lastSupplyNodeSignature";
private _routeInfo = _network get "_supplyRouteInfo";
private _topologyDirty = (_network get "_objectiveSideIndexDirty")
    || {(_network get "_lastSupplyChainRefreshAt") < 0}
    || {(keys _routeInfo) isEqualTo []};

if (_network get "_objectiveSideIndexDirty") then {
    [_network] call FLO_fnc_logisticsNetworkRefreshObjectiveSideIndex;
    _network set ["_objectiveSideIndexDirty", false];
};

private _nodes = _network get "_nodes";
private _hqNodeId = _network get "_hqNodeId";
private _hqObjectiveId = _network get "_hqObjectiveId";

if (_topologyDirty) then {
    _hqObjectiveId = [_network] call FLO_fnc_logisticsNetworkPickHQObjective;
    _hqNodeId = [_network, _hqObjectiveId] call FLO_fnc_logisticsNetworkAnchorHQ;
    _network set ["_hqObjectiveId", _hqObjectiveId];

    _routeInfo = createHashMap;
    if (_hqObjectiveId != "" && {_hqObjectiveId in (_network get "_managedObjectiveIds")}) then {
        _routeInfo set [_hqObjectiveId, createHashMapFromArray [
            ["depth", 0],
            ["routeMeters", 0],
            ["parentObjective", ""],
            ["isHQ", true]
        ]];

        private _frontier = [[_hqObjectiveId, 0]];
        private _frontierIndex = 0;
        private _depthMeters = _network get "SUPPLY_CHAIN_DEPTH_METERS";

        while {_frontierIndex < count _frontier} do {
            private _entry = _frontier select _frontierIndex;
            _frontierIndex = _frontierIndex + 1;
            _entry params ["_currentObjectiveId", "_routeMeters"];
            private _currentObjective = FLO_Objectives get _currentObjectiveId;
            private _currentPosition = _currentObjective get "position";

            {
                private _linkedObjectiveId = _x;
                if !(_linkedObjectiveId in FLO_Objectives) then { continue };
                private _linkedObjective = FLO_Objectives get _linkedObjectiveId;
                if ((_linkedObjective get "owner") isNotEqualTo _managedSide) then { continue };
                if !([_linkedObjectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) then { continue };

                private _newRouteMeters = _routeMeters + (_currentPosition distance2D (_linkedObjective get "position"));
                private _isBetterRoute = true;
                if (_linkedObjectiveId in _routeInfo) then {
                    _isBetterRoute = _newRouteMeters < ((_routeInfo get _linkedObjectiveId) get "routeMeters");
                };
                if (!_isBetterRoute) then { continue };

                _routeInfo set [_linkedObjectiveId, createHashMapFromArray [
                    ["depth", ceil (_newRouteMeters / _depthMeters)],
                    ["routeMeters", _newRouteMeters],
                    ["parentObjective", _currentObjectiveId],
                    ["isHQ", false]
                ]];
                _frontier pushBack [_linkedObjectiveId, _newRouteMeters];
            } forEach (_currentObjective get "linkedObjectives");
        };
    };
    _network set ["_supplyRouteInfo", _routeInfo];
};

[_network] call FLO_fnc_logisticsNetworkSeedInitialDepot;

private _activeSources = createHashMap;
private _now = call FLO_fnc_operationalDateNumber;
{
    private _node = _y;
    private _nodeType = _node get "type";
    private _anchorKind = _node get "anchorKind";
    private _position = _node get "position";
    private _objectiveId = _node get "objectiveId";
    private _baseAlive = true;

    if (_anchorKind == "BASE") then {
        private _base = objectFromNetId (_node get "baseNetId");
        _baseAlive = !isNull _base && {alive _base};
        if (_baseAlive) then {
            _position = getPosATL _base;
            _node set ["position", +_position];
            _objectiveId = [_network, _position, _objectiveId] call FLO_fnc_logisticsNetworkResolveNodeObjective;
            _node set ["objectiveId", _objectiveId];
        };
    };

    private _objectiveValid = _objectiveId != ""
        && {_objectiveId in FLO_Objectives}
        && {((FLO_Objectives get _objectiveId) get "owner") isEqualTo _managedSide}
        && {[_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated};
    private _routeConnected = _objectiveValid && {_objectiveId in _routeInfo};

    if (!_baseAlive || {!_objectiveValid && {_anchorKind == "OBJECTIVE" || {_nodeType == "HQ"}}}) then {
        _node set ["state", "DISABLED"];
        _node set ["upstreamNodeId", ""];
        continue;
    };
    if (!_routeConnected) then {
        _node set ["state", "ISOLATED"];
        _node set ["upstreamNodeId", ""];
        continue;
    };

    private _stillEstablishing = (_node get "requiredDeliveries") > (_node get "deliveryCount");
    if (_stillEstablishing) then {
        private _deadlineReached = ([_now, _node get "establishAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;
        if (_deadlineReached) then {
            _node set ["deliveryCount", _node get "requiredDeliveries"];
            _node set ["throughput", (_node get "throughput") max (((_node get "refillAmount") * 2) min (_node get "throughputMax"))];
            _stillEstablishing = false;
            ["LOGISTICS", 3, format ["Autonomous rear-echelon delivery activated node %1", _x]] call FLO_fnc_log;
        };
    };
    if (_stillEstablishing) then {
        _node set ["state", "ESTABLISHING"];
        _node set ["upstreamNodeId", ""];
        continue;
    };

    private _objective = FLO_Objectives get _objectiveId;
    private _throughputRatio = (_node get "throughput") / (_node get "throughputMax");
    private _strained = (_objective get "contested") || {_objective get "underAttack"} || {_throughputRatio <= 0.25};
    _node set ["state", ["CONNECTED", "STRAINED"] select _strained];

    if (_node get "commanderSource" && {(_node get "throughput") > 0}) then {
        private _routeNode = _routeInfo get _objectiveId;
        private _candidate = createHashMapFromArray [
            ["nodeId", _x],
            ["nodeType", _nodeType],
            ["state", _node get "state"],
            ["throughput", _node get "throughput"],
            ["depth", _routeNode get "depth"],
            ["routeMeters", _routeNode get "routeMeters"],
            ["parentObjective", _routeNode get "parentObjective"],
            ["deliveryCount", _node get "deliveryCount"],
            ["isHQ", _nodeType == "HQ"]
        ];

        if !(_objectiveId in _activeSources) then {
            _activeSources set [_objectiveId, _candidate];
        } else {
            if ((_node get "throughput") > ((_activeSources get _objectiveId) get "throughput")) then {
                _activeSources set [_objectiveId, _candidate];
            };
        };
    };
} forEach _nodes;

{
    private _nodeId = _x;
    private _node = _y;
    if !((_node get "state") in ["CONNECTED", "STRAINED", "ESTABLISHING"]) then { continue };
    if (_nodeId == _hqNodeId) then { continue };

    private _objectiveId = _node get "objectiveId";
    private _upstreamNodeId = "";
    if (_objectiveId in _routeInfo) then {
        private _cursor = (_routeInfo get _objectiveId) get "parentObjective";
        while {_cursor != "" && {_upstreamNodeId == ""}} do {
            if (_cursor in _activeSources) then {
                _upstreamNodeId = (_activeSources get _cursor) get "nodeId";
            } else {
                _cursor = if (_cursor in _routeInfo) then { (_routeInfo get _cursor) get "parentObjective" } else { "" };
            };
        };
    };
    if (_upstreamNodeId == "" && {_hqNodeId != ""}) then { _upstreamNodeId = _hqNodeId; };
    _node set ["upstreamNodeId", _upstreamNodeId];
} forEach _nodes;

_network set ["_activeSupplyNodes", _activeSources];
_network set ["_supplyChainDirty", false];
_network set ["_lastSupplyChainRefreshAt", diag_tickTime];

private _signatureParts = [];
{
    _signatureParts pushBack format ["%1:%2:%3", _x, _y get "state", floor ((_y get "throughput") / 100)];
} forEach _nodes;
_signatureParts sort true;
private _signature = format ["%1|%2", _hqObjectiveId, _signatureParts joinString ","];
if (_signature != _previousSignature) then {
    _network set ["_lastSupplyNodeSignature", _signature];
    [
        "FLO_Logistics_SupplyChainChanged",
        [_managedSide, _hqObjectiveId, keys _activeSources, _signature]
    ] call CBA_fnc_localEvent;
};

private _elapsedMs = (diag_tickTime - _t0) * 1000;
if (_elapsedMs > 10) then {
    diag_log format [
        "[FLO][PERF] Logistics route refresh %1 topology=%2 processed %3 objectives and %4 nodes in %5 ms",
        _network get "_managedSideKey",
        _topologyDirty,
        count (keys _routeInfo),
        count (keys _nodes),
        _elapsedMs
    ];
};

_activeSources
