/*
 * Function: FLO_fnc_militaryIntel
 * Author: Frontline Operations Development Group
 * Description:
 *   Client entry point for composition-based intel interactions.
 *
 * Arguments:
 *   0: Source object that provided the intel <OBJECT>
 *
 * Return Value:
 *   Nothing
 *
 * Example:
 *   [_laptop] call FLO_fnc_militaryIntel;
 */

params [["_source", objNull, [objNull]]];

if (!hasInterface) exitWith {
    ["INTEL", 1, "FLO_fnc_militaryIntel called outside a client interface"] call FLO_fnc_log;
};

private _origin = _source;
if (isNull _origin) then {
    _origin = player;
};

if (isNull _origin) exitWith {
    ["INTEL", 1, "FLO_fnc_militaryIntel called without a source object or local player"] call FLO_fnc_log;
};

private _gridPos = mapGridPosition (getPosATL _origin);
private _itemClass = typeOf _origin;

[_gridPos, _itemClass] remoteExecCall ["FLO_fnc_addIntelServer", 2];
