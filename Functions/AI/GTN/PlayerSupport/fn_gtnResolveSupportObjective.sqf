/*
 * Function: FLO_fnc_gtnResolveSupportObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves the support target objective for a clicked position. Prefers an
 *   objective that actually contains the point and otherwise falls back to the
 *   nearest objective center.
 *
 * Arguments:
 *   0: Position <ARRAY>
 *
 * Return Value:
 *   STRING - Objective ID or ""
 */

params [["_position", [0, 0, 0], [[]], [3]]];

if (isNil "FLO_Objectives") exitWith { "" };

private _bestObjectiveId = "";
private _bestDistance = 1e12;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;

    if !([_position, _objective] call FLO_fnc_isPositionInObjective) then { continue };

    private _distance = _position distance2D (_objective get "position");
    if (_distance < _bestDistance) then {
        _bestDistance = _distance;
        _bestObjectiveId = _objectiveId;
    };
} forEach (keys FLO_Objectives);

if (_bestObjectiveId != "") exitWith { _bestObjectiveId };

[_position] call FLO_fnc_getNearestObjective
