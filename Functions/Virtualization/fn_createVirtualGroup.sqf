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
 * 3: Objective <STRING> - (Optional) ID of the objective this group is tied to
 * 4: Unit Count <NUMBER> - (Optional, default based on group type) Number of units in infantry groups
 * 5: Side <SIDE> - (Optional, default: east) Side of the group
 *
 * Return Value:
 * Group ID <STRING> - The ID of the created virtual group
 *
 * Example:
 * [getMarkerPos "marker_1", "infantry", nil, "obj_1", 8] call FLO_fnc_createVirtualGroup;
 * [getMarkerPos "marker_2", "civilianVehicle", nil, "civ_car", 1, civilian] call FLO_fnc_createVirtualGroup;
 */

// Get parameters with proper type checking
private ["_position", "_groupType", "_groupCfg", "_objective", "_unitCount", "_side"];

_position = _this param [0, [0,0,0], [[]]];
_groupType = _this param [1, "infantry", [""]];
// NOTE: Don't use param for groupCfg - it can be array OR config
_groupCfg = if (count _this > 2 && {!isNil {_this select 2}}) then { _this select 2 } else { configNull };
_objective = _this param [3, "", [""]];
_unitCount = _this param [4, -1, [0]];
_side = _this param [5, east, [east]];

// Validate position - reject groups with invalid positions
if ((_position select 0) < 100 && (_position select 1) < 100) exitWith {
    ["VIRTUALIZATION", 1, format["ERROR: Attempted to create group with invalid position %1 - rejecting", _position]] call FLO_fnc_log;
    ""
};

// Ensure virtualization system is initialized
if (isNil "FLO_virtualGroups") then {
    [2000] call FLO_fnc_initVirtualization;
};

// Generate unique ID for the group
private _groupId = format["vgroup_%1", floor(random 999999)];
private _groups = FLO_virtualGroups get "_groups";
while {_groupId in _groups} do {
    _groupId = format["vgroup_%1", floor(random 999999)];
};

// Get unit count from OPFOR_Group_Counts or use provided count
if (isNil "_unitCount" || { _unitCount <= 0 || typeName _unitCount != "SCALAR" }) then {
    if (_groupType isEqualTo "civilian") then {
        _unitCount = 1 + floor random 3; // 1-3 civilians per group by default
    } else {
        if (_groupType isEqualTo "civilianVehicle") then {
            _unitCount = 1;
        } else {
            _unitCount = [_groupType] call FLO_fnc_getGroupTypeCount;
        };
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
    ["comp", []],
    // Transport system fields
    ["attachedTo", ""],           // GroupId of transport this group is riding in
    ["attachedGroups", []],       // Array of groupIds attached to this transport
    ["attachedType", ""],         // "GROUND" or "AIR"
    ["isTransport", false],       // Whether this group can carry others
    ["dismountAtWaypoint", -1],   // Waypoint index to auto-dismount (-1 = never)
    ["mountedIn", ""]             // GroupId of transport when spawned mounted
];

// Add group to virtualization system
[FLO_virtualGroups, _groupId, _groupData] call (FLO_virtualGroups get "_addGroup");

// Log creation
["VIRTUALIZATION", 3, format["Created virtual group %1 of type %2 at %3", _groupId, _groupType, _position]] call FLO_fnc_log;

// Return the group ID
_groupId 