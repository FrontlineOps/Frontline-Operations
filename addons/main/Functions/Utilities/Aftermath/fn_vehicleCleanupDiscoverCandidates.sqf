/*
 * Function: FLO_fnc_vehicleCleanupDiscoverCandidates
 * Author: Frontline Operations Development Group
 * Description:
 *   Performs the lower-frequency broad discovery scan for abandoned live
 *   vehicle cleanup candidates.
 *
 * Arguments:
 * 0: Cleanup state <HASHMAP>
 * 1: Cleanup context <HASHMAP>
 * 2: Current time <NUMBER>
 *
 * Return Value:
 * NUMBER - Newly discovered candidates this pass
 */

params [
    ["_state", createHashMap, [createHashMap]],
    ["_context", createHashMap, [createHashMap]],
    ["_now", 0, [0]]
];

private _candidates = _state get "candidates";
private _discoveredCount = 0;

{
    if !([
        _x,
        _context get "trackedVehicleKeys",
        _context get "playerPositions",
        _context get "installationPositions",
        _context get "playerSafeRadius",
        _context get "installationSafeRadius"
    ] call FLO_fnc_vehicleShouldCleanup) then {
        continue;
    };

    private _vehicleKey = str _x;
    if !(isNil { _candidates get _vehicleKey }) then {
        continue;
    };

    _candidates set [_vehicleKey, [_x, _now]];
    _discoveredCount = _discoveredCount + 1;
} forEach vehicles;

_state set ["nextDiscoveryAt", _now + (_state get "discoveryInterval")];

_discoveredCount
