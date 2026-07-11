/*
 * Function: FLO_fnc_virtualizationSetAssetCompositionById
 * Description:
 *   Replaces canonical asset composition through an ID-based command.
 */

params [
    ["_groupId", "", [""]],
    ["_composition", [], [[]]]
];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _candidate = [_groupData] call FLO_fnc_virtualizationCloneValue;
[_candidate, _composition] call FLO_fnc_virtualizationSetAssetComposition;
_candidate set ["nextProcessAt", 0];
[_candidate, _groupId] call FLO_fnc_virtualizationValidateGroup;
{
    _groupData set [_x, _candidate get _x];
} forEach ["comp", "vehicleType", "nextProcessAt"];
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, ["comp", "vehicleType"]]
] call CBA_fnc_localEvent;

true
