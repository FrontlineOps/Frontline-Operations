/*
 * Function: FLO_fnc_getNearestObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds the nearest objective from FLO_Objectives to a given position.
 *   Optionally filters by owner side.
 *
 * Arguments:
 *   0: Position to check from (ARRAY)
 *   1: Filter by owner side (SIDE) - Optional, nil for any side
 *
 * Returns:
 *   STRING - Objective ID, or "" if none found
 *
 * Examples:
 *   [getPos player] call FLO_fnc_getNearestObjective;
 *   [getPos player, east] call FLO_fnc_getNearestObjective;
 */

params [
    ["_pos", [0,0,0]],
    ["_filterSide", nil]
];

if (isNil "FLO_Objectives") exitWith { "" };

private _closest = "";
private _minDist = 1e9;

{
    private _data = FLO_Objectives get _x;
    if (isNil "_data") then { continue };

    // Filter by side if specified
    if (!isNil "_filterSide") then {
        private _owner = _data get "owner";
        if (_owner isEqualType "") then {
            private _ownerKey = toUpper _owner;
            if (_ownerKey isEqualTo "EAST") then { _owner = east; };
            if (_ownerKey isEqualTo "WEST") then { _owner = west; };
        };
        if !(_owner isEqualTo _filterSide) then { continue };
    };

    private _objPos = _data get "position";
    private _dist = _pos distance2D _objPos;

    if (_dist < _minDist) then {
        _minDist = _dist;
        _closest = _x;
    };
} forEach (keys FLO_Objectives);

_closest
