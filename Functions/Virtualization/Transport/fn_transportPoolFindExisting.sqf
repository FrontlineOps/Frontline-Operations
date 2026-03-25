/*
 * Function: FLO_fnc_transportPoolFindExisting
 */

params [
    ["_requiredCapacity", 1, [0]],
    ["_nearPos", [0,0,0], [[]]],
    ["_side", east, [east]],
    ["_maxDistance", 5000, [0]]
];

private _groups = FLO_virtualGroups get "_groups";
private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";

private _bestGroup = "";
private _bestDist = _maxDistance + 1;
private _bestCapacity = 0;

{
    private _groupId = _x;
    private _gData = _y;

    if (_groupId in _available || {_groupId in _active}) then { continue };
    if ((_gData get "side") != _side) then { continue };

    private _groupType = _gData get "groupType";
    if !(_groupType in ["motorized", "mechanized"]) then { continue };

    if (count ([_gData] call FLO_fnc_virtualizationGetTransportPassengers) > 0) then { continue };
    if ((_gData get "missionLock") != "") then { continue };

    private _commanderOrder = _gData get "commanderOrder";
    if (_commanderOrder != "" && {!(_commanderOrder in ["PATROL", "DEFEND", ""])}) then { continue };

    private _capacity = [_gData] call FLO_fnc_transportGetGroupCapacity;
    if (_capacity < _requiredCapacity) then { continue };

    private _position = _gData get "position";
    private _dist = _position distance2D _nearPos;
    if (_dist < _bestDist) then {
        _bestDist = _dist;
        _bestGroup = _groupId;
        _bestCapacity = _capacity;
    };
} forEach _groups;

if (_bestGroup != "") then {
    ["TRANSPORT", 3, format ["Pool: Found existing vehicle group %1 (capacity: %2, dist: %3m)", _bestGroup, _bestCapacity, round _bestDist]] call FLO_fnc_log;
};

_bestGroup
