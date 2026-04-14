/*
 * Function: FLO_fnc_civilianInvestigateAction
 * Author: Frontline Operations Development Group
 * Description:
 *   Backward-compatible wrapper for civilian intel requests.
 *
 * Arguments:
 * 0: Civilian <OBJECT>
 * 1: Caller <OBJECT>
 *
 * Return Value:
 * BOOL
 */

params ["_civilian", "_caller"];

[_civilian, _caller] call FLO_fnc_civilianRequestIntel
