/*
 * Function: FLO_fnc_gtnPlayerTaskDescription
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the description text for a GTN player task.
 *
 * Arguments:
 *   0: Task kind <STRING>
 *   1: Objective id <STRING>
 *   2: Objective data <HASHMAP>
 *   3: Task metadata <HASHMAP> - Optional
 *
 * Return Value:
 *   Task description <STRING>
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
    case "capture": { format ["Commander objective: capture %1 and hold the area.", _name] };
    case "defend": { format ["Commander objective: defend %1 against enemy pressure.", _name] };
    case "destroy": {
        if (_targetLabel != "") then {
            if (_targetCount > 0) then {
                format ["Commander intel reports %1 enemy %2 near %3. Destroy marked targets.", _targetCount, _targetLabel, _name]
            } else {
                format ["Commander intel reports enemy %1 near %2. Destroy that target.", _targetLabel, _name]
            }
        } else {
            format ["Commander objective: destroy hostile assets around %1.", _name]
        }
    };
    default { format ["Commander objective: operate near %1.", _name] };
}
