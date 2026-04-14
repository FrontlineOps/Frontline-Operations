/*
 * Function: FLO_fnc_vehicleCleanupProcessCandidates
 * Author: Frontline Operations Development Group
 * Description:
 *   Rechecks active cleanup candidates and deletes the ones that have remained
 *   eligible past the configured grace time.
 *
 * Arguments:
 * 0: Cleanup state <HASHMAP>
 * 1: Cleanup context <HASHMAP>
 * 2: Current time <NUMBER>
 *
 * Return Value:
 * ARRAY - [deletedCount, droppedCount]
 */

params [
    ["_state", createHashMap, [createHashMap]],
    ["_context", createHashMap, [createHashMap]],
    ["_now", 0, [0]]
];

private _candidates = _state get "candidates";
private _graceTime = _state get "graceTime";
private _deletedCount = 0;
private _droppedCount = 0;

{
    private _entry = _candidates get _x;
    _entry params ["_vehicle", "_firstSeen"];

    if (isNull _vehicle) then {
        _candidates deleteAt _x;
        _droppedCount = _droppedCount + 1;
        continue;
    };

    if !([
        _vehicle,
        _context get "trackedVehicleKeys",
        _context get "playerPositions",
        _context get "installationPositions",
        _context get "playerSafeRadius",
        _context get "installationSafeRadius"
    ] call FLO_fnc_vehicleShouldCleanup) then {
        _candidates deleteAt _x;
        _droppedCount = _droppedCount + 1;
        continue;
    };

    if (_now - _firstSeen < _graceTime) then {
        continue;
    };

    ["VEHICLE_CLEANUP", 3, format [
        "Removing abandoned derelict %1 at %2 after %3s empty",
        typeOf _vehicle,
        getPosATL _vehicle,
        round (_now - _firstSeen)
    ]] call FLO_fnc_log;

    _vehicle hideObjectGlobal true;
    deleteVehicle _vehicle;
    _candidates deleteAt _x;
    _deletedCount = _deletedCount + 1;
} forEach +(keys _candidates);

[_deletedCount, _droppedCount]
