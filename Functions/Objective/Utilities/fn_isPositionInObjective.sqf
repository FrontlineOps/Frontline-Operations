/*
 * Function: FLO_fnc_isPositionInObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks if a position is inside an objective's area.
 *   Supports both radius-based (circle) and polygon-based checks.
 *   If objective has "polygon" data, uses inPolygon for accuracy.
 *   Otherwise falls back to simple radius check.
 *
 * Arguments:
 *   0: Position to check (ARRAY) - [x,y] or [x,y,z]
 *   1: Objective ID (STRING) or Objective data (HASHMAP)
 *
 * Returns:
 *   BOOL - True if position is inside objective area
 *
 * Examples:
 *   [getPos player, "virtual_1"] call FLO_fnc_isPositionInObjective;
 *   [getPos player, _objectiveData] call FLO_fnc_isPositionInObjective;
 */

params [
    ["_pos", [0,0,0]],
    ["_objective", ""]
];

// Get objective data
private _objData = if (_objective isEqualType "") then {
    if (isNil "FLO_Objectives") exitWith { nil };
    FLO_Objectives get _objective
} else {
    _objective
};

if (isNil "_objData") exitWith { false };

// Check if polygon data exists and should be used
private _polygon = _objData getOrDefault ["polygon", []];
private _usePolygon = _objData getOrDefault ["usePolygon", false];

if (_usePolygon && {count _polygon >= 3}) then {
    // Use polygon check (inPolygon command)
    // Convert position to 2D if needed
    private _pos2D = [_pos select 0, _pos select 1];
    _pos2D inPolygon _polygon
} else {
    // Fall back to radius check
    private _center = _objData get "position";
    private _radius = _objData getOrDefault ["radius", 50];
    
    (_pos distance2D _center) <= _radius
}

