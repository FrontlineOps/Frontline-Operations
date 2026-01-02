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
params [
    ["_position", [0,0,0], [[]]],
    ["_groupType", "infantry", [""]],
    ["_groupCfg", configNull, [configNull, []]],
    ["_objective", "", [""]],
    ["_unitCount", -1, [0]],
    ["_side", east, [east]]
];

// Generate unique ID for the group
private _groupId = format["vgroup_%1", floor(random 999999)];
private _groups = FLO_virtualGroups get "_groups";
while {_groupId in _groups} do {
    _groupId = format["vgroup_%1", floor(random 999999)];
};

// Get unit count from OPFOR_Group_Counts or use provided count
if (_unitCount <= 0) then {
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
    ["spawnPosition", _position],
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
    ["onMission", false],         // Whether this group is on an active mission (prevents virtualization)
    ["currentOrder", ""],         // Current order type (MOVE, ATTACK, DEFEND, etc.)
    ["linkedObjectives", []],     // Objectives this group is linked to
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