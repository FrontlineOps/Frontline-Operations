/*
 * Function: FLO_fnc_virtualizationUpdateGroupPosition
 */

params ["_groupId", "_newPosition"];

private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroup;
if (isNil "_groupData") exitWith { false };
[_groupId, _groupData, _newPosition] call FLO_fnc_virtualizationUpdateOwnedGroupPosition
