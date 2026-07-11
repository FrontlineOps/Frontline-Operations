/*
 * Function: FLO_fnc_minefieldGetBlockingObjectiveId
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the objective id that blocks minefield placement at a position,
 *   excluding the defended objective itself. Empty string means the position
 *   does not fall inside any other objective.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Objective ids to ignore <ARRAY>
 * 2: Candidate objective ids to check <ARRAY> (optional)
 *
 * Return Value:
 * STRING
 */

params [
    ["_position", [0, 0, 0]],
    ["_ignoredObjectiveIds", []],
    ["_candidateObjectiveIds", []]
];

if ((count _position) < 2) exitWith { "" };

private _blockingObjectiveId = "";
private _objectiveAreaCache = FLO_MinefieldObjectiveAreaCache;
private _objectiveIds = if (_candidateObjectiveIds isNotEqualTo []) then { _candidateObjectiveIds } else { keys _objectiveAreaCache };

{
    private _objectiveId = _x;
    if (_objectiveId in _ignoredObjectiveIds) then { continue };

    private _objectiveArea = _objectiveAreaCache get _objectiveId;
    if ([_position, _objectiveArea] call FLO_fnc_minefieldIsPositionInsideObjectiveArea) exitWith {
        _blockingObjectiveId = _objectiveId;
    };
} forEach _objectiveIds;

_blockingObjectiveId
