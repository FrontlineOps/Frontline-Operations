/*
 * Function: FLO_fnc_aftermathIsPositionInHotObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Determines whether a position is inside an objective that is currently
 *   hot enough to preserve battlefield evidence and live derelicts.
 *
 * Arguments:
 * 0: Position <ARRAY>
 *
 * Return Value:
 * BOOL - True when the position sits inside a hot objective area
 */

params [["_position", [0, 0, 0], [[]]]];

private _objectiveId = [_position] call FLO_fnc_getNearestObjective;
if (_objectiveId == "") exitWith { false };
if !([_position, _objectiveId] call FLO_fnc_isPositionInObjective) exitWith { false };

private _objective = FLO_Objectives get _objectiveId;
(_objective get "contested") || { _objective get "underAttack" } || { (_objective get "enemyCount") > 0 }
