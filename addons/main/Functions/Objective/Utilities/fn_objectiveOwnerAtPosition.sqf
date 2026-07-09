/*
 * Function: FLO_fnc_objectiveOwnerAtPosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the normalized owner of the objective containing a position.
 *
 * Arguments:
 * 0: Position <ARRAY>
 *
 * Returns:
 * Owner <SIDE>
 */
params ["_pos"];

private _owner = sideUnknown;

{
    private _objData = FLO_Objectives get _x;
    if ([_pos, _objData] call FLO_fnc_isPositionInObjective) exitWith {
        _owner = _objData get "owner";
    };
} forEach (keys FLO_Objectives);

[_owner] call FLO_fnc_objectiveNormalizeOwner
