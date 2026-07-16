/*
 * Function: FLO_fnc_gtnPublishPlayerTask
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a side-owned BIS task for one direct assignment.
 */

params ["_ownerSide", "_assignmentId", "_kind", "_objectiveId", "_objective"];

private _taskId = format ["FLO_ATK_%1_%2_%3", _assignmentId, _kind, _objectiveId];
private _title = [_kind, _objectiveId] call FLO_fnc_gtnPlayerTaskTitle;
private _description = [_kind, _objectiveId] call FLO_fnc_gtnPlayerTaskDescription;
private _taskType = [_kind] call FLO_fnc_gtnTaskTypeFromKind;

[
    _ownerSide,
    _taskId,
    [_description, _title, ""],
    _objective get "position",
    "ASSIGNED",
    0,
    true,
    _taskType,
    false
] call BIS_fnc_taskCreate;

_taskId
