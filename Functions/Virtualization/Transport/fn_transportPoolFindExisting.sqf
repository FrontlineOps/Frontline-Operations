/*
 * Function: FLO_fnc_transportPoolFindExisting
 */

params [
    ["_requiredCapacity", 1, [0]],
    ["_nearPos", [0,0,0], [[]]],
    ["_side", east, [east]],
    ["_maxDistance", 5000, [0]],
    ["_requiredActivation", "ANY", [""]],
    ["_allowedGroupTypes", ["motorized", "mechanized"], [[]]],
    ["_requireTransportRole", false, [false]]
];

private _groups = FLO_virtualGroups get "_groups";
private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";

private _bestGroup = "";
private _bestPriority = 10;
private _bestDist = _maxDistance + 1;
private _bestCapacity = 0;

{
    private _groupId = _x;
    private _gData = _y;

    if (_groupId in _available || {_groupId in _active}) then { continue };
    if ((_gData get "side") != _side) then { continue };
    if (_requiredActivation != "ANY" && {(_gData get "isActive") != (_requiredActivation == "ACTIVE")}) then { continue };

    private _groupType = _gData get "groupType";
    if (count _allowedGroupTypes > 0 && {!(_groupType in _allowedGroupTypes)}) then { continue };
    if (_requireTransportRole && {!(_gData get "transportRole")}) then { continue };

    if (count ([_gData] call FLO_fnc_virtualizationGetTransportPassengers) > 0) then { continue };
    if ((_gData get "missionLock") != "") then { continue };

    private _commanderOrder = _gData get "commanderOrder";
    if (_commanderOrder != "" && {!(_commanderOrder in ["PATROL", "DEFEND", "", "TRANSPORT"])}) then { continue };

    private _capacity = [_gData] call FLO_fnc_transportGetGroupCapacity;
    if (_capacity < _requiredCapacity) then { continue };

    private _position = _gData get "position";
    private _dist = _position distance2D _nearPos;
    private _priority = if (_gData get "transportRole") then { 0 } else { 1 };
    if (_priority < _bestPriority || {_priority == _bestPriority && {_dist < _bestDist}}) then {
        _bestPriority = _priority;
        _bestDist = _dist;
        _bestGroup = _groupId;
        _bestCapacity = _capacity;
    };
} forEach _groups;

if (_bestGroup != "") then {
    ["TRANSPORT", 3, format ["Pool: Found existing vehicle group %1 (capacity: %2, dist: %3m)", _bestGroup, _bestCapacity, round _bestDist]] call FLO_fnc_log;
};

_bestGroup
