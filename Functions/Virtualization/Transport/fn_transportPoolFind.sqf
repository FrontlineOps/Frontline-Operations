/*
 * Function: FLO_fnc_transportPoolFind
 */

params [
    ["_requiredCapacity", 1, [0]],
    ["_nearPos", [0,0,0], [[]]],
    ["_side", sideUnknown, [east]],
    ["_maxDistance", 3000, [0]],
    ["_requiredActivation", "ANY", [""]],
    ["_allowedGroupTypes", [], [[]]],
    ["_requireTransportRole", false, [false]]
];

private _groups = FLO_virtualGroups get "_groups";
private _available = FLO_TransportPool get "available";
private _bestGroup = "";
private _bestDist = _maxDistance + 1;

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if (isNil "_groupData") then { continue };
    private _entrySide = _groupData get "side";
    private _groupType = _groupData get "groupType";
    private _transportRole = _groupData get "transportRole";

    if (_side != sideUnknown && {_entrySide != _side}) then { continue };
    if (count _allowedGroupTypes > 0 && {!(_groupType in _allowedGroupTypes)}) then { continue };
    if (_requireTransportRole && {!_transportRole}) then { continue };
    if (_requiredActivation != "ANY") then {
        if ((_groupData get "isActive") != (_requiredActivation == "ACTIVE")) then { continue };
    };

    private _position = _groupData get "position";
    private _dist = _position distance2D _nearPos;
    if (_dist > _maxDistance || {_dist >= _bestDist}) then { continue };

    private _pickupCapacity = [_groupData] call FLO_fnc_transportGetPickupCapacity;
    if (_pickupCapacity < _requiredCapacity) then { continue };

    _bestDist = _dist;
    _bestGroup = _groupId;
} forEach _available;

if (_bestGroup != "") then {
    ["TRANSPORT", 3, format ["Pool: Found available transport %1 (dist: %2m)", _bestGroup, round _bestDist]] call FLO_fnc_log;
};

_bestGroup
