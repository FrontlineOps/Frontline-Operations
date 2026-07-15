/*
 * Function: FLO_fnc_transportPoolRelease
 */

params [["_groupId", "", [""]]];

if (_groupId == "") exitWith { false };

private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";

if !(_groupId in _active) exitWith { false };

private _data = _active get _groupId;
private _groupData = [_groupId] call FLO_fnc_transportGetTrackedGroup;
private _passengerIds = +([_groupData] call FLO_fnc_virtualizationGetTransportPassengers);
if (_passengerIds isNotEqualTo []) then {
    private _message = format [
        "Cannot release transport %1 with passengers %2",
        _groupId,
        _passengerIds
    ];
    ["TRANSPORT", 1, _message] call FLO_fnc_log;
    throw _message;
};

[_groupId] call FLO_fnc_transportClearInsertState;

if !(_groupData get "transportRole") exitWith {
    _active deleteAt _groupId;
    ["TRANSPORT", 3, format [
        "Pool: Released organic fallback carrier %1 without adding it to dedicated reserve availability",
        _groupId
    ]] call FLO_fnc_log;
    true
};

if !([_groupId, _groupData] call FLO_fnc_transportReturnCarrierToReserve) exitWith { false };

_active deleteAt _groupId;

_available set [_groupId, [
    _data select 0,
    _groupData get "position",
    _groupData get "groupType",
    _groupData get "transportRole",
    _groupData get "side"
]];

["TRANSPORT", 3, format ["Pool: Released transport %1 back to available", _groupId]] call FLO_fnc_log;
true
