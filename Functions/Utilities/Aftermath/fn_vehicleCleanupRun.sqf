/*
 * Function: FLO_fnc_vehicleCleanupRun
 * Author: Frontline Operations Development Group
 * Description:
 *   Periodic server scan for abandoned derelict vehicles that should be
 *   removed by FLO's aftermath system while still alive.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - True when the scan completed
 */

if (!isServer) exitWith { false };
if (isNil "FLO_VehicleCleanup") exitWith { false };

private _state = FLO_VehicleCleanup;
if !(_state get "enabled") exitWith { false };

private _now = diag_tickTime;
private _candidates = _state get "candidates";
private _needsDiscovery = _now >= (_state get "nextDiscoveryAt");
private _hasCandidates = (count (keys _candidates)) > 0;

if !(_needsDiscovery || {_hasCandidates}) exitWith { true };

private _context = [] call FLO_fnc_vehicleCleanupBuildContext;
_state set ["playerSafeRadius", _context get "playerSafeRadius"];

if (_needsDiscovery) then {
    private _discoveredCount = [_state, _context, _now] call FLO_fnc_vehicleCleanupDiscoverCandidates;
    if (_discoveredCount > 0) then {
        ["VEHICLE_CLEANUP", 3, format [
            "Discovered %1 new abandoned live vehicle cleanup candidates",
            _discoveredCount
        ]] call FLO_fnc_log;
    };
};

private _deletedCount = 0;
if ((count (keys (_state get "candidates"))) > 0) then {
    private _results = [_state, _context, _now] call FLO_fnc_vehicleCleanupProcessCandidates;
    _deletedCount = _results select 0;
};

if (_deletedCount > 0) then {
    ["VEHICLE_CLEANUP", 2, format ["Deleted %1 abandoned derelict vehicles", _deletedCount]] call FLO_fnc_log;
};

true
