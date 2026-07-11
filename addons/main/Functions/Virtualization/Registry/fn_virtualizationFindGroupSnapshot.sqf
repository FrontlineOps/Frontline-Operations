/*
 * Function: FLO_fnc_virtualizationFindGroupSnapshot
 * Description:
 *   Returns an immutable snapshot when the group exists, otherwise nil.
 */

params [["_groupId", "", [""]]];

private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroup;
if (isNil "_groupData") exitWith { nil };
[_groupData] call FLO_fnc_virtualizationCloneValue
