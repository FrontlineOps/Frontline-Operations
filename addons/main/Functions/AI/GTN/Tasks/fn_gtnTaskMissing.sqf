/*
 * Function: FLO_fnc_gtnTaskMissing
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks whether a task id is empty or no longer exists.
 *
 * Arguments:
 *   0: Task id <STRING>
 *
 * Return Value:
 *   Missing <BOOL>
 */

params ["_taskId"];

if (_taskId isEqualTo "") exitWith { true };
!([_taskId] call BIS_fnc_taskExists)
