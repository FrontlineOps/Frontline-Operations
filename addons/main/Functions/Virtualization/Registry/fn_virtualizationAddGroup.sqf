/*
 * Function: FLO_fnc_virtualizationAddGroup
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_emitEvent", true, [true]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if (_groupId in _groups) then {
    throw format ["Virtual group %1 already exists", _groupId];
};
[_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;

private _pos = _groupData get "position";
if !([_pos, true, format ["virtualizationAddGroup %1", _groupId]] call FLO_fnc_validateGroupPosition) exitWith {
    false
};

_groups set [_groupId, _groupData];
[_groupId, _pos, _groupData get "side"] call FLO_fnc_virtualizationSpatialAdd;
call FLO_fnc_virtualizationTouchRegistry;

if (_emitEvent) then {
    [
        "FLO_Virtualization_GroupAdded",
        [_groupId, [_groupId] call FLO_fnc_virtualizationSnapshotGroup]
    ] call CBA_fnc_localEvent;
};

true
