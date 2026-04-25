/*
 * Function: FLO_fnc_minefieldDeleteObjectiveFields
 * Author: Frontline Operations Development Group
 * Description:
 *   Deletes the tracked minefield, if any, for one objective.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Reason <STRING> (optional)
 *
 * Return Value:
 * BOOL
 */

params [
    ["_objectiveId", ""],
    ["_reason", "STALE"]
];

if (_objectiveId == "") exitWith { false };
private _canceledQueuedBuild = [_objectiveId, _reason] call FLO_fnc_minefieldCancelObjectiveBuild;
if (isNil "FLO_MinefieldObjectiveIndex") exitWith { _canceledQueuedBuild };
if !(_objectiveId in FLO_MinefieldObjectiveIndex) exitWith { _canceledQueuedBuild };

private _fieldId = FLO_MinefieldObjectiveIndex get _objectiveId;

[_fieldId, _reason] call FLO_fnc_minefieldDeleteField
