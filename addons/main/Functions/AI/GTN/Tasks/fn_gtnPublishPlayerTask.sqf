/*
 * Function: FLO_fnc_gtnPublishPlayerTask
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a side-owned BIS task from a GTN player task candidate.
 *
 * Arguments:
 *   0: Owner side <SIDE>
 *   1: Slot prefix <STRING>
 *   2: Task kind <STRING>
 *   3: Objective id <STRING>
 *   4: Objective data <HASHMAP>
 *   5: Task metadata <HASHMAP> - Optional
 *
 * Return Value:
 *   Task id <STRING>
 */

params [
    "_ownerSide",
    "_slotPrefix",
    "_kind",
    "_objId",
    "_objData",
    ["_meta", createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]]]
];

private _taskId = format ["FLO_GTN_%1_%2_%3", _slotPrefix, _kind, _objId];
private _title = [_kind, _objId, _objData, _meta] call FLO_fnc_gtnPlayerTaskTitle;
private _desc = [_kind, _objId, _objData, _meta] call FLO_fnc_gtnPlayerTaskDescription;
private _taskType = [_kind] call FLO_fnc_gtnTaskTypeFromKind;
private _pos = _meta getOrDefault ["taskPos", _objData get "position"];

[
    _ownerSide,
    _taskId,
    [_desc, _title, ""],
    _pos,
    "ASSIGNED",
    0,
    true,
    _taskType,
    false
] call BIS_fnc_taskCreate;

_taskId
