/*
 * Function: FLO_fnc_minefieldCancelObjectiveBuild
 * Author: Frontline Operations Development Group
 * Description:
 *   Cancels any queued minefield build for one objective.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Reason <STRING>
 *
 * Return Value:
 * BOOL
 */

params [
    ["_objectiveId", ""],
    ["_reason", "CANCELED"]
];

if (_objectiveId == "") exitWith { false };
if (isNil "FLO_MinefieldBuild") exitWith { false };

private _objectiveIndex = FLO_MinefieldBuild get "objectiveIndex";
if !(_objectiveId in _objectiveIndex) exitWith { false };

[(_objectiveIndex get _objectiveId), _reason] call FLO_fnc_minefieldFinalizeBuildJob
