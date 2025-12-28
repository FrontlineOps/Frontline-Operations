/*
 * Function: FLO_fnc_getObjectivePath
 * Author: Frontline Operations Development Group
 * Description:
 *   Retrieves the cached waypoint array between two objectives generated
 *   by FLO_fnc_buildObjectiveGraph. If the path is stored in reverse,
 *   it is reversed automatically. Generates path on-demand if not cached.
 *
 * Arguments:
 *   0: From objective ID (STRING)
 *   1: To objective ID (STRING)
 *
 * Returns:
 *   ARRAY - Array of positions (may be empty if no link)
 *
 * Examples:
 *   ["virtual_1", "virtual_2"] call FLO_fnc_getObjectivePath;
 */

params [
    ["_from", ""],
    ["_to", ""]
];

// Validate inputs
if (_from == "" || _to == "") exitWith { [] };
if (isNil "FLO_ObjectiveLinks") exitWith { [] };
if (isNil "FLO_Objectives") exitWith { [] };

// Create canonical key (sorted alphabetically)
private _sorted = [_from, _to];
_sorted sort true;
private _key = format ["%1_%2", _sorted select 0, _sorted select 1];

// Get link data
private _link = FLO_ObjectiveLinks get _key;
if (isNil "_link") exitWith { [] };

// Get or generate path
private _path = +(_link getOrDefault ["waypoints", []]);

if (count _path == 0) then {
    // Generate path on-demand
    private _fromData = FLO_Objectives get _from;
    private _toData = FLO_Objectives get _to;

    if (isNil "_fromData" || isNil "_toData") exitWith { _path = [] };

    private _fromPos = _fromData get "position";
    private _toPos = _toData get "position";

    // Try to find road path
    _path = [_fromPos, _toPos] call FLO_fnc_findRoadPathSync;

    // Fallback to direct path
    if (count _path == 0) then { _path = [_toPos] };

    // Cache the path
    _link set ["waypoints", _path];
    FLO_ObjectiveLinks set [_key, _link];
};

// Reverse if needed (path stored from->to but we want to->from)
private _result = +_path;
if ((_link getOrDefault ["from", ""]) != _from) then { reverse _result };

_result
