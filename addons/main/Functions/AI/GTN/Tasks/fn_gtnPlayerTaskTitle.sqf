/*
 * Function: FLO_fnc_gtnPlayerTaskTitle
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the display title for a GTN player task.
 *
 * Arguments:
 *   0: Task kind <STRING>
 *   1: Objective id <STRING>
 *   2: Objective data <HASHMAP>
 *   3: Task metadata <HASHMAP> - Optional
 *
 * Return Value:
 *   Task title <STRING>
 */

params [
    "_kind",
    "_objId",
    "_objData",
    ["_meta", createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]]]
];

private _name = _objData get "name";
private _targetLabel = _meta get "targetLabel";
private _targetCount = _meta get "targetCount";

switch (_kind) do {
    case "capture": { format ["Capture %1", _name] };
    case "defend": { format ["Defend %1", _name] };
    case "destroy": {
        if (_targetLabel != "") then {
            if (_targetCount > 0) then {
                format ["Destroy %1 enemy %2 at %3", _targetCount, _targetLabel, _name]
            } else {
                format ["Destroy enemy %1 at %2", _targetLabel, _name]
            }
        } else {
            format ["Destroy enemy assets at %1", _name]
        }
    };
    default { format ["Operate at %1", _name] };
}
