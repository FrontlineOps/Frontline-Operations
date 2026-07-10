params ["_network", ["_objectiveId", "", [""]]];

private _roleCache = _network get "_dispatchRoleCache";
if (_objectiveId in _roleCache) exitWith { _roleCache get _objectiveId };

[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
private _activeSources = _network get "_activeSupplyNodes";
private _role = createHashMapFromArray [
    ["depth", -1],
    ["routeMeters", 1e12],
    ["parentObjective", ""],
    ["deliveryCount", 0],
    ["isHQ", false],
    ["isActiveNode", false],
    ["activeLinkedObjectives", []],
    ["nodeId", ""],
    ["nodeType", ""],
    ["nodeState", ""]
];

if (_objectiveId in _routeInfo) then {
    private _route = _routeInfo get _objectiveId;
    _role set ["depth", _route get "depth"];
    _role set ["routeMeters", _route get "routeMeters"];
    _role set ["parentObjective", _route get "parentObjective"];
    _role set ["isHQ", _route get "isHQ"];

    if (_objectiveId in _activeSources) then {
        private _source = _activeSources get _objectiveId;
        _role set ["deliveryCount", _source get "deliveryCount"];
        _role set ["isActiveNode", true];
        _role set ["nodeId", _source get "nodeId"];
        _role set ["nodeType", _source get "nodeType"];
        _role set ["nodeState", _source get "state"];
    };

    if (_objectiveId in FLO_Objectives) then {
        _role set [
            "activeLinkedObjectives",
            ((FLO_Objectives get _objectiveId) get "linkedObjectives") select { _x in _activeSources }
        ];
    };
};

_roleCache set [_objectiveId, _role];
_role
