/*
 * Function: FLO_fnc_startSideMission
 * Author: Frontline Operations Development Group
 * Description:
 *  Starts a side mission registered via FLO_fnc_registerSideMission.
 * Arguments:
 * 0: Mission name (STRING)
 * 1: Optional array of arguments passed to the mission function
 * Returns: Script handle or nil
 */

params ["_name", ["_args", []]];

if (isNil "FLO_registeredSideMissions") exitWith { nil };

private _entry = FLO_registeredSideMissions getOrDefault [_name, objNull];
if (isNil "_entry") exitWith { nil };

_entry params ["_missionFnc", "_data"];

[_args, _data] call _missionFnc;
