/*
 * Function: FLO_fnc_createVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Creates a new virtual group with the specified parameters.
 *
 * Arguments:
 * 0: Position <ARRAY> - [x, y, z] where the group will be created
 * 1: Group Type <STRING> - "infantry", "motorized", "mechanized", "armor", "helicopter", "jet", "air", "artillery"
 * 2: Group Config <CONFIG> - (Optional) Group config from CfgGroups if using a predefined group
 * 3: Objective <STRING> - (Optional) ID of the objective this group is tied to
 * 4: Unit Count <NUMBER> - (Optional, default based on group type) Number of units in infantry groups
 * 5: Side <SIDE> - (Optional, default: east) Side of the group
 *
 * Return Value:
 * Group ID <STRING> - The ID of the created virtual group
 *
 * Example:
 * [getMarkerPos "marker_1", "infantry", nil, "obj_1", 8] call FLO_fnc_createVirtualGroup;
 */

// Get parameters with proper type checking
private ["_position", "_groupType", "_groupCfg", "_objective", "_unitCount", "_side"];

_position = _this param [0, [0,0,0], [[]]];
_groupType = _this param [1, "infantry", [""]];
_groupCfg = _this param [2, configNull];
_objective = _this param [3, "", [""]];
_unitCount = _this param [4, -1, [0]];
_side = _this param [5, east, [east]];

// Ensure virtualization system is initialized
if (isNil "FLO_virtualGroups") then {
    [2000] call FLO_fnc_initVirtualization;
};

// Generate unique ID for the group
private _groupId = format["vgroup_%1", floor(random 999999)];
private _groups = FLO_virtualGroups get "_groups";
while {(_groups get _groupId) isNotEqualTo objNull} do {
    _groupId = format["vgroup_%1", floor(random 999999)];
};

// Get unit count from OPFOR_Group_Counts or use provided count
if (_unitCount < 0) then {
    private _groupCounts = OPFOR_Group_Counts;
    private _foundCount = false;
    {
        _x params ["_type", "_count"];
        if (_type == _groupType) then {
            _unitCount = _count;
            _foundCount = true;
        };
    } forEach _groupCounts;
    
    if (!_foundCount) then {
        // Default fallback if group type not found
        _unitCount = 1;
        diag_log format ["[VIRTUALIZATION] ERROR: No unit count defined for group type %1, using default of 1", _groupType];
    };
};

// Create group data hashmap
private _groupData = createHashMapFromArray [
    ["position", _position],
    ["groupType", _groupType],
    ["groupCfg", _groupCfg],
    ["objective", _objective],
    ["unitCount", _unitCount],
    ["side", _side],
    ["isActive", false],
    ["realGroup", grpNull],
    ["state", "idle"],
    ["waypoints", []],
    ["comp", []]
];

// Add group to virtualization system
[FLO_virtualGroups, _groupId, _groupData] call (FLO_virtualGroups get "_addGroup");

// Log creation
["VIRTUALIZATION", 3, format["Created virtual group %1 of type %2 at %3", _groupId, _groupType, _position]] call FLO_fnc_log;

// Return the group ID
_groupId 