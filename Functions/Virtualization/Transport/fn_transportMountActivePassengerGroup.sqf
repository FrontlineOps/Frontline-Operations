/*
 * Function: FLO_fnc_transportMountActivePassengerGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Forces an active passenger group into an active carrier's cargo space and
 *   verifies that the mounted state is coherent in the live world.
 *
 * Arguments:
 *   0: Passenger Group ID <STRING>
 *   1: Passenger Group Data <HASHMAP>
 *   2: Carrier Group ID <STRING>
 *   3: Carrier Group Data <HASHMAP>
 *   4: Carrier Vehicles <ARRAY> - Optional
 *
 * Return Value:
 *   BOOL - True when the passenger group is fully mounted
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_passengerData", createHashMap, [createHashMap]],
    ["_transportGroupId", "", [""]],
    ["_transportData", createHashMap, [createHashMap]],
    ["_transportVehicles", [], [[]]]
];

if (_passengerGroupId == "" || {_transportGroupId == ""}) exitWith { false };
if !(_passengerData get "isActive") exitWith { false };
if !(_transportData get "isActive") exitWith { false };

private _passengerRealGroup = _passengerData get "realGroup";
private _transportRealGroup = _transportData get "realGroup";
if (isNull _passengerRealGroup || {isNull _transportRealGroup}) exitWith {
    [_passengerGroupId, _passengerData, _transportGroupId, _transportData, "missing_real_group", _transportVehicles] call FLO_fnc_transportLogMountFailureContext;
    ["TRANSPORT", 2, format [
        "Active mount failed for %1 into %2 due to missing real group reference",
        _passengerGroupId,
        _transportGroupId
    ]] call FLO_fnc_log;
    false
};

if (count _transportVehicles == 0) then {
    _transportVehicles = ([_transportRealGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { !isNull _x && {alive _x} };
};
if (count _transportVehicles == 0) exitWith {
    [_passengerGroupId, _passengerData, _transportGroupId, _transportData, "no_live_vehicles", _transportVehicles] call FLO_fnc_transportLogMountFailureContext;
    ["TRANSPORT", 2, format [
        "Active mount failed for %1 into %2 because the carrier has no live vehicles",
        _passengerGroupId,
        _transportGroupId
    ]] call FLO_fnc_log;
    false
};

private _aliveUnits = units _passengerRealGroup select { alive _x };
if (count _aliveUnits == 0) exitWith { true };

private _freeCargoSeats = 0;
{
    _freeCargoSeats = _freeCargoSeats + (_x emptyPositions "cargo");
} forEach _transportVehicles;

if (_freeCargoSeats < count _aliveUnits) exitWith {
    [_passengerGroupId, _passengerData, _transportGroupId, _transportData, "insufficient_live_capacity", _transportVehicles] call FLO_fnc_transportLogMountFailureContext;
    ["TRANSPORT", 2, format [
        "Active mount failed for %1 into %2 because the carrier only has %3 live cargo seats for %4 units",
        _passengerGroupId,
        _transportGroupId,
        _freeCargoSeats,
        count _aliveUnits
    ]] call FLO_fnc_log;
    false
};

private _seatFailure = false;
{
    private _veh = vehicle _x;
    if (_veh != _x && {_veh in _transportVehicles}) then { continue };

    if (_veh != _x) then {
        moveOut _x;
    };

    private _seatVehicle = objNull;
    {
        if (_x emptyPositions "cargo" > 0) exitWith {
            _seatVehicle = _x;
        };
    } forEach _transportVehicles;

    if (isNull _seatVehicle) exitWith {
        _seatFailure = true;
    };

    _x moveInCargo _seatVehicle;
} forEach _aliveUnits;

private _mountedCount = {
    private _veh = vehicle _x;
    _veh != _x && { _veh in _transportVehicles }
} count _aliveUnits;

if (_seatFailure || {_mountedCount != count _aliveUnits}) exitWith {
    [_passengerGroupId, _passengerData, _transportGroupId, _transportData, "partial_mount", _transportVehicles] call FLO_fnc_transportLogMountFailureContext;
    ["TRANSPORT", 2, format [
        "Active mount failed for %1 into %2 (%3/%4 mounted)",
        _passengerGroupId,
        _transportGroupId,
        _mountedCount,
        count _aliveUnits
    ]] call FLO_fnc_log;
    false
};

[_passengerData, _transportGroupId] call FLO_fnc_virtualizationSetMountedIn;

true
