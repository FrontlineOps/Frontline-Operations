/*
 * Function: FLO_fnc_virtualizationGenerateGroupId
 */

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _groupId = format ["vgroup_%1", floor (random 999999)];

while {_groupId in _groups} do {
    _groupId = format ["vgroup_%1", floor (random 999999)];
};

_groupId
