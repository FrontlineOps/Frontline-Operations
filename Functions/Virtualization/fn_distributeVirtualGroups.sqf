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

// Check for important terrain features nearby (mountains, hills, etc.)
private _importantPositions = [];

// If this is a special objective type or has a specific prefix, look for terrain features
if (_groupType in ["infantry", "motorized"] || {((getMarkerType _objectiveMarker) find "loc_") == 0}) then {
    // Find elevated positions within 300-800m of the objective
    for "_i" from 0 to 7 do {
        private _searchAngle = (_i * 45) + (random 20);
        private _searchDist = 300 + (random 500);
        private _searchPos = [
            (_position select 0) + (sin _searchAngle * _searchDist),
            (_position select 1) + (cos _searchAngle * _searchDist)
        ];
        
        // Get terrain height at this position
        private _terrainHeight = getTerrainHeightASL _searchPos;
        private _objectiveHeight = getTerrainHeightASL _position;
        
        // If this position is elevated compared to the objective, add it
        if (_terrainHeight > _objectiveHeight + 15) then {
            _importantPositions pushBack [_searchPos, _terrainHeight - _objectiveHeight];
        };
    };
    
    // Sort positions by elevation (highest first)
    _importantPositions sort false;
};

// Get group config if infantry
private _groupCfg = objNull;
if (_groupType == "infantry" && {count East_Groups > 0}) then {
    _groupCfg = selectRandom East_Groups;
};

// Create and distribute the groups
private _remainingGroups = _count;
private _terrainPositionsUsed = 0;

// First, place groups at important terrain features (if available and appropriate)
if (count _importantPositions > 0 && _groupType in ["infantry", "motorized", "mechanized", "artillery"]) then {
    // Use up to half of the groups for terrain features
    private _terrainGroupCount = floor(_count / 2) min (count _importantPositions);
    
    for "_i" from 0 to (_terrainGroupCount - 1) do {
        private _terrainPos = (_importantPositions select _i) select 0;
        
        // Find safe position near the terrain feature
        private _safePos = [_terrainPos, 0, 20, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;
        
        // Create the virtual group
        private _groupId = [_safePos, _groupType, _groupCfg, _objectiveMarker] call FLO_fnc_createVirtualGroup;
        _createdGroups pushBack _groupId;
        
        // Log creation
        ["VIRTUALIZATION", 3, format["Distributed %1 group at strategic terrain near %2", _groupType, _objectiveMarker]] call FLO_fnc_log;
        
        _remainingGroups = _remainingGroups - 1;
        _terrainPositionsUsed = _terrainPositionsUsed + 1;
    };
};

// Create remaining groups around the objective using the original pattern
for "_i" from 1 to _remainingGroups do {
    // Calculate position based on distribution pattern
    private _angle = (360 / _remainingGroups) * _i;
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

// If we placed any units at terrain positions, log it
if (_terrainPositionsUsed > 0) then {
    ["VIRTUALIZATION", 3, format["Placed %1 groups at strategic terrain features near %2", _terrainPositionsUsed, _objectiveMarker]] call FLO_fnc_log;
};

// Return array of created group IDs
_createdGroups 