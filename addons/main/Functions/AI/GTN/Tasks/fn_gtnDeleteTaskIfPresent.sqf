/*
 * Function: FLO_fnc_gtnDeleteTaskIfPresent
 * Author: Frontline Operations Development Group
 * Description:
 *   Deletes a BIS task when a task id is present.
 *
 * Arguments:
 *   0: Task id <STRING>
 *
 * Return Value:
 *   Nothing
 */

params ["_taskId"];

if (_taskId isEqualTo "") exitWith {};
[_taskId] call BIS_fnc_deleteTask;
