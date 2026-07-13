/*
 * Function: FLO_fnc_createVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Creates a new virtual group with the specified parameters.
 *
 * Arguments:
 * 0: Position <ARRAY> - [x, y, z] where the group will be created
 * 1: Group Type <STRING> - "infantry", "motorized", "mechanized", "armor", "helicopter", "jet", "air", "artillery", "civilian", "civilianVehicle"
 * 2: Group Config <CONFIG> - (Optional) Group config from CfgGroups if using a predefined group
 * 3: Home Objective <STRING> - (Optional) ID of the objective this group is tied to
 * 4: Unit Count <NUMBER> - (Optional, default based on group type) Number of units in infantry groups
 * 5: Side <SIDE> - (Optional, default: east) Side of the group
 * 6: Spawn Class <STRING> - Optional preferred unit class for civilian activation/persistence
 *
 * Return Value:
 * Group ID <STRING> - The ID of the created virtual group
 *
 * Example:
 * [getMarkerPos "marker_1", "infantry", nil, "obj_1", 8] call FLO_fnc_createVirtualGroup;
 * [getMarkerPos "marker_2", "civilianVehicle", nil, "civ_car", 1, civilian] call FLO_fnc_createVirtualGroup;
 */
params [
    ["_position", [0,0,0], [[]]],
    ["_groupType", "infantry", [""]],
    ["_groupCfg", configNull, [configNull, []]],
    ["_homeObjective", "", [""]],
    ["_unitCount", -1, [0]],
    ["_side", east, [east]],
    ["_spawnClass", "", [""]]
];

_position = [_position] call FLO_fnc_virtualizationNormalizePosition;
if !([_position, true, format ["createVirtualGroup %1 home=%2 side=%3", _groupType, _homeObjective, _side]] call FLO_fnc_validateGroupPosition) exitWith {
    ""
};

private _groupId = call FLO_fnc_virtualizationGenerateGroupId;
private _groupData = [
    _position,
    _groupType,
    _groupCfg,
    _homeObjective,
    _unitCount,
    _side,
    _spawnClass,
    _groupId
] call FLO_fnc_virtualizationBuildGroupData;

// Add group to virtualization system
if !([_groupId, _groupData] call FLO_fnc_virtualizationAddGroup) exitWith {
    ""
};

// Log creation
["VIRTUALIZATION", 5, format["Created virtual group %1 of type %2 at %3", _groupId, _groupType, _position]] call FLO_fnc_log;

// Return the group ID
_groupId 
