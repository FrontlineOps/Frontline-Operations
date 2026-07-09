/*
 * Function: FLO_fnc_gtnMarkTaskSucceeded
 * Author: Frontline Operations Development Group
 * Description:
 *   Marks a BIS task succeeded and deletes it after a delay.
 *
 * Arguments:
 *   0: Task id <STRING>
 *   1: Cleanup delay <NUMBER> - Optional, default 45
 *
 * Return Value:
 *   Nothing
 */

params ["_taskId", ["_cleanupDelay", 45]];

if (_taskId isEqualTo "") exitWith {};

[_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
[_taskId, _cleanupDelay] spawn {
    params ["_tid", "_delay"];
    sleep _delay;
    [_tid] call BIS_fnc_deleteTask;
};
