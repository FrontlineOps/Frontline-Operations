params ["_network"];

if (_network get "_initialInfrastructureSeeded") exitWith { "" };
private _nodes = _network get "_nodes";
private _hasDepot = false;
{
    if ((_y get "type") == "DEPOT") exitWith { _hasDepot = true; };
} forEach _nodes;
if (_hasDepot) exitWith {
    _network set ["_initialInfrastructureSeeded", true];
    ""
};

private _enemySide = _network get "_enemySide";
private _routeInfo = _network get "_supplyRouteInfo";
private _hqObjectiveId = _network get "_hqObjectiveId";
private _bestObjectiveId = "";
private _bestScore = -1e12;

{
    private _objectiveId = _x;
    if (_objectiveId == _hqObjectiveId || {!(_objectiveId in _routeInfo)}) then { continue };
    private _objective = FLO_Objectives get _objectiveId;
    private _frontline = false;
    {
        if (((FLO_Objectives get _x) get "owner") isEqualTo _enemySide) exitWith { _frontline = true; };
    } forEach (_objective get "linkedObjectives");
    if (!_frontline) then { continue };

    private _routeMeters = (_routeInfo get _objectiveId) get "routeMeters";
    private _score = _routeMeters + ((_objective get "priority") * 100);
    if (_score > _bestScore) then {
        _bestScore = _score;
        _bestObjectiveId = _objectiveId;
    };
} forEach (_network get "_managedObjectiveIds");

if (_bestObjectiveId == "") then { _bestObjectiveId = _hqObjectiveId; };
if (_bestObjectiveId != "" && {_bestObjectiveId != _hqObjectiveId}) then {
    private _nodeId = format ["NODE_%1_DEPOT_%2", _network get "_managedSideKey", _bestObjectiveId];
    private _position = (FLO_Objectives get _bestObjectiveId) get "position";
    [_network, _nodeId, "DEPOT", "OBJECTIVE", _bestObjectiveId, _position, _bestObjectiveId, false, -1] call FLO_fnc_logisticsNetworkCreateNode;
    ["LOGISTICS", 2, format ["Seeded initial %1 depot at %2", _network get "_managedSideKey", _bestObjectiveId]] call FLO_fnc_log;
};

_network set ["_initialInfrastructureSeeded", true];
_bestObjectiveId
