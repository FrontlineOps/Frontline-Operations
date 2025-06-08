/*
 * Function: FLO_fnc_getObjectivePath
 * Author: Frontline Operations Development Group
 * Description:
 *   Retrieves the cached waypoint array between two objectives generated
 *   by FLO_fnc_buildObjectiveGraph. If the path is stored in reverse,
 *   it is reversed automatically.
 *
 * Arguments:
 *   0: From objective ID <STRING>
 *   1: To objective ID <STRING>
 *
 * Returns:
 *   Array of positions (may be empty if no link)
 */

params ["_from","_to"];

if (isNil "FLO_ObjectiveLinks") exitWith { [] };
private _key = format ["%1_%2", _from, _to];
private _link = FLO_ObjectiveLinks get _key;
if (!isNil "_link") exitWith { _link get "waypoints" };
_key = format ["%1_%2", _to, _from];
_link = FLO_ObjectiveLinks get _key;
if (isNil "_link") exitWith { [] };
reverse (_link get "waypoints")
