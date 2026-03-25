/*
 * Function: FLO_fnc_transportGetTrackedGroup
 */

params ["_groupId"];

private _groups = FLO_virtualGroups get "_groups";
private _groupData = _groups get _groupId;

if (isNil "_groupData") then {
    throw format ["[TRANSPORT] Missing virtual group %1", _groupId];
};

_groupData
