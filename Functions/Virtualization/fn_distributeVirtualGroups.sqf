/*
 * Function: FLO_fnc_distributeVirtualGroups
 * Author: Frontline Operations Development Group
 * Description:
 * Distributes virtual groups around an objective with appropriate spacing and positioning.
 * Used during initial placement to ensure groups aren't stacked on top of each other.
 *
 * Arguments:
 * 0: Objective Marker <STRING> - Marker name for the objective
 * 1: Group Type <STRING> - Type of group to distribute
 * 2: Count <NUMBER> - Number of groups to distribute
 *
 * Return Value:
 * Array of created group IDs <ARRAY>
 *
 * Example:
 * ["o_support_1", "infantry", 3] call FLO_fnc_distributeVirtualGroups;
 */

params [
    ["_objectiveMarker", "", [""]],
    ["_groupType", "infantry", [""]],
    ["_count", 1, [0]]
];

// Check if marker exists
if (_objectiveMarker == "" || {getMarkerColor _objectiveMarker == ""}) exitWith {
    ["VIRTUALIZATION", 2, format["Cannot distribute groups - invalid marker: %1", _objectiveMarker]] call FLO_fnc_log;
    []
};

// Initialize return array for group IDs
private _createdGroups = [];

// Get objective properties
private _position = getMarkerPos _objectiveMarker;
private _size = getMarkerSize _objectiveMarker;
private _radius = (_size select 0) min (_size select 1);

// Adjust radius based on group type
private _distributionRadius = switch (_groupType) do {
    case "infantry": { _radius * 0.5 };
    case "motorized";
    case "mechanized";
    case "armor": { _radius * 0.7 };
    case "helicopter";
    case "jet";
    case "air": { _radius * 0.8 };
    case "artillery": { _radius * 0.6 };
    default { _radius * 0.5 };
};

// Make sure radius isn't tiny
_distributionRadius = _distributionRadius max 30;

// Get group config if infantry
private _groupCfg = objNull;
if (_groupType == "infantry" && {count East_Groups > 0}) then {
    _groupCfg = selectRandom East_Groups;
};

// Create and distribute the groups
for "_i" from 1 to _count do {
    // Calculate position based on distribution pattern
    private _angle = (360 / _count) * _i;
    private _distance = random [_distributionRadius * 0.3, _distributionRadius * 0.6, _distributionRadius];
    
    // Calculate offset position
    private _offsetX = sin(_angle) * _distance;
    private _offsetY = cos(_angle) * _distance;
    private _groupPos = [(_position select 0) + _offsetX, (_position select 1) + _offsetY, 0];
    
    // Find safe position near the calculated point
    private _safePos = [_groupPos, 0, 30, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
    
    // Create the virtual group
    private _groupId = [_safePos, _groupType, _groupCfg, _objectiveMarker] call FLO_fnc_createVirtualGroup;
    _createdGroups pushBack _groupId;
    
    // Log creation
    ["VIRTUALIZATION", 3, format["Distributed %1 group at %2 - position: %3", _groupType, _objectiveMarker, _safePos]] call FLO_fnc_log;
};

// Return array of created group IDs
_createdGroups 