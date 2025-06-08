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

private _sorted = [_from, _to];
_sorted sort true;
private _key = format ["%1_%2", _sorted select 0, _sorted select 1];
private _link = FLO_ObjectiveLinks get _key;
if (isNil "_link") exitWith { [] };

private _path = +(_link get "waypoints");
if ((_link get "from") != _from) then { reverse _path; };
_path