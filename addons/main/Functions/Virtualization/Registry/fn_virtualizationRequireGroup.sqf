/*
 * Function: FLO_fnc_virtualizationRequireGroup
 */

params [["_groupId", "", [""]]];

if (_groupId == "") then {
    throw "FLO_fnc_virtualizationRequireGroup: empty group id";
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _groupData = _groups get _groupId;
if (isNil "_groupData") then {
    throw format ["Virtual group %1 does not exist", _groupId];
};

_groupData
