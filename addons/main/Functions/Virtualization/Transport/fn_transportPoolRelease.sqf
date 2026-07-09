/*
 * Function: FLO_fnc_transportPoolRelease
 */

params [["_groupId", "", [""]]];

if (_groupId == "") exitWith { false };

private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";

if !(_groupId in _active) exitWith { false };

private _data = _active get _groupId;
_active deleteAt _groupId;

private _groupData = [_groupId] call FLO_fnc_transportGetTrackedGroup;
if !(_groupData get "transportRole") exitWith {
    ["TRANSPORT", 3, format [
        "Pool: Released organic fallback carrier %1 without adding it to dedicated reserve availability",
        _groupId
    ]] call FLO_fnc_log;
    true
};

_available set [_groupId, [
    _data select 0,
    _groupData get "position",
    _groupData get "groupType",
    _groupData get "transportRole",
    _groupData get "side"
]];

[_groupId, _groupData] call FLO_fnc_transportReturnCarrierToReserve;

["TRANSPORT", 3, format ["Pool: Released transport %1 back to available", _groupId]] call FLO_fnc_log;
true
