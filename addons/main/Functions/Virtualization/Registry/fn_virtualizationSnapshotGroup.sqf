/*
 * Function: FLO_fnc_virtualizationSnapshotGroup
 */

params [["_groupId", "", [""]]];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
[_groupData] call FLO_fnc_virtualizationCloneValue
