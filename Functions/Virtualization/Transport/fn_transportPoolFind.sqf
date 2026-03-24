/*
 * Function: FLO_fnc_transportPoolFind
 */

params [
    ["_requiredCapacity", 1, [0]],
    ["_nearPos", [0,0,0], [[]]],
    ["_maxDistance", 3000, [0]]
];

private _available = FLO_TransportPool get "available";
private _bestGroup = "";
private _bestDist = _maxDistance + 1;

{
    private _groupId = _x;
    _y params ["_capacity", "_position"];

    if (_capacity < _requiredCapacity) then { continue };

    private _dist = _position distance2D _nearPos;
    if (_dist < _bestDist) then {
        _bestDist = _dist;
        _bestGroup = _groupId;
    };
} forEach _available;

if (_bestGroup != "") then {
    ["TRANSPORT", 3, format ["Pool: Found available transport %1 (dist: %2m)", _bestGroup, round _bestDist]] call FLO_fnc_log;
};

_bestGroup
