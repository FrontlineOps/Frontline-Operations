/*
 * Function: FLO_fnc_getNearestObjective
 * Author: Azraeelian Angel
 * Description:
 * Finds the nearest objective from FLO_Objectives to a given position
 *
 * Arguments:
 * 0: Position to check from <ARRAY>
 *
 * Return Value:
 * Objective ID <STRING>
 *
 * Example:
 * [_position] call FLO_fnc_getNearestObjective;
 */

params ["_pos"];
if (isNil "FLO_Objectives") exitWith {""};
private _closest = "";
private _minDist = 1e9;
{
    private _data = FLO_Objectives get _x;
    if (!isNil "_data") then {
        private _d = _pos distance2D (_data get "position");
        if (_d < _minDist) then { _minDist = _d; _closest = _x; };
    };
} forEach (keys FLO_Objectives);
_closest 