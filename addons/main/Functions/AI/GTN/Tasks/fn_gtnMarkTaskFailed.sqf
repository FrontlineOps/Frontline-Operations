/*
 * Function: FLO_fnc_gtnMarkTaskFailed
 * Description: Marks a BIS task failed and removes it after a short delay.
 */

params ["_taskId", ["_cleanupDelay", 45]];

if (_taskId == "") exitWith {};

[_taskId, "FAILED", true] call BIS_fnc_taskSetState;
[_taskId, _cleanupDelay] spawn {
    params ["_resolvedTaskId", "_delay"];
    sleep _delay;
    [_resolvedTaskId] call BIS_fnc_deleteTask;
};
