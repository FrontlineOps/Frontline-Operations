/*
 * Function: FLO_fnc_transportSyncActivePassengerGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Reconciles one active passenger group against the actual cargo occupancy of
 *   its active carrier. Partial or fully broken mounted states are repaired by
 *   forcing a coherent detach.
 *
 * Arguments:
 *   0: Passenger Group ID <STRING>
 *   1: Passenger Group Data <HASHMAP>
 *   2: Carrier Group ID <STRING>
 *   3: Carrier Vehicles <ARRAY>
 *   4: Carrier Group Data <HASHMAP> - Optional
 *
 * Return Value:
 *   BOOL - True when the passenger group was examined
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_passengerData", createHashMap, [createHashMap]],
    ["_transportGroupId", "", [""]],
    ["_transportVehicles", [], [[]]],
    ["_transportData", createHashMap, [createHashMap]]
];

if (_passengerGroupId == "" || {_transportGroupId == ""}) exitWith { false };
if !(_passengerData get "isActive") exitWith { false };

private _realGroup = _passengerData get "realGroup";
if (isNull _realGroup) exitWith { false };

private _aliveUnits = units _realGroup select { alive _x };
if (count _aliveUnits == 0) exitWith { false };

private _mountedCount = {
    private _veh = vehicle _x;
    _veh != _x && { _veh in _transportVehicles }
} count _aliveUnits;

if (_mountedCount == count _aliveUnits) exitWith {
    if (([_passengerData] call FLO_fnc_virtualizationGetMountedTransport) != _transportGroupId) then {
        [_passengerData, _transportGroupId] call FLO_fnc_virtualizationSetMountedIn;
    };
    true
};

private _unloadCommandIssued = false;
if (count (keys _transportData) > 0) then {
    _unloadCommandIssued = _transportData get "transportUnloadCommandIssued";
};

if (_unloadCommandIssued) exitWith {
    if (_mountedCount == 0 && {([_passengerData] call FLO_fnc_virtualizationGetMountedTransport) != ""}) then {
        [_passengerData] call FLO_fnc_virtualizationClearMountedIn;
    };
    true
};

if (_mountedCount == 0) then {
    ["TRANSPORT", 2, format [
        "Active passenger %1 is no longer mounted in carrier %2 - detaching",
        _passengerGroupId,
        _transportGroupId
    ]] call FLO_fnc_log;
} else {
    ["TRANSPORT", 2, format [
        "Active passenger %1 is partially mounted in carrier %2 (%3/%4) - forcing coherent detach",
        _passengerGroupId,
        _transportGroupId,
        _mountedCount,
        count _aliveUnits
    ]] call FLO_fnc_log;
};

[_passengerGroupId, random 360] call FLO_fnc_transportDetach;
[_passengerGroupId, "ACTIVE_TRANSPORT_SYNC"] call FLO_fnc_transportApplyPostDismountWaypoint;

true
