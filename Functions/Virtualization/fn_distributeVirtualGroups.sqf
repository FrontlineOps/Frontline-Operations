/*
 * Function: FLO_fnc_distributeVirtualGroups
 * Author: Frontline Operations Development Group
 * Description:
 * Distributes virtual groups around an objective with appropriate spacing and positioning.
 * Used during initial placement to ensure groups aren't stacked on top of each other.
 *
 * Arguments:
 * 0: Objective ID or Marker <STRING> - Objective identifier from the index or a marker name
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
    ["_objective", "", [""]],
    ["_groupType", "infantry", [""]],
    ["_count", 1, [0]]
];

// Determine objective data either from the index or a marker
private _objData = nil;
if (!isNil "FLO_Objectives") then {
    _objData = FLO_Objectives get _objective;
    if (isNil "_objData" && {(_objective select [0,4]) isEqualTo "obj_"}) then {
        _objData = FLO_Objectives get (_objective select [4]);
    };
};

private _position = [0,0,0];
private _radius = 100;
private _markerName = "";
if (isNil "_objData") then {
    if (_objective isEqualTo "" || {getMarkerColor _objective isEqualTo ""}) exitWith {
        ["VIRTUALIZATION", 2, format["Cannot distribute groups - invalid objective: %1", _objective]] call FLO_fnc_log;
        []
    };
    _markerName = _objective;
    _position = getMarkerPos _objective;
    private _size = getMarkerSize _objective;
    _radius = (_size select 0) min (_size select 1);
} else {
    _position = _objData get "position";
    _radius = _objData get "radius";
    _markerName = format ["obj_%1", _objective];
};

// Validate position
if (_position isEqualTo [0,0,0]) exitWith {
    ["VIRTUALIZATION", 2, format ["ERROR: Invalid position [0,0,0] for objective %1 - skipping", _objective]] call FLO_fnc_log;
    []
};


// Initialize return array for group IDs
private _createdGroups = [];

// Adjust radius based on group type with some randomness
private _baseFactor = switch (_groupType) do {
    case "infantry": {0.5};
    case "motorized"; case "mechanized"; case "armor": {0.7};
    case "helicopter"; case "jet"; case "air": {0.8};
    case "artillery": {0.6};
    default {0.5};
};
private _distributionRadius = _radius * _baseFactor;
_distributionRadius = _distributionRadius * (0.8 + random 0.4);

// Make sure radius isn't tiny
_distributionRadius = _distributionRadius max 30;

// No longer searching for elevated terrain - placements handled uniformly

// Get group config if infantry
private _groupCfg = objNull;
if (_groupType isEqualTo "infantry" && {!isNil "East_Groups"} && {count East_Groups > 0}) then {
    _groupCfg = East_Groups;
};

// Create and distribute the groups
private _remainingGroups = _count;

// Determine directions towards linked objectives for more dynamic spread
private _linkAngles = [];
if (!isNil "_objData") then {
    private _links = _objData getOrDefault ["linkedObjectives", []];
    {
        private _ldata = FLO_Objectives get _x;
        if (!isNil "_ldata") then {
            _linkAngles pushBack (_position getDir (_ldata get "position"));
        };
    } forEach _links;
};


// Create remaining groups around the objective using dynamic distribution
for "_i" from 1 to _remainingGroups do {
    private _angle = random 360;
    if (count _linkAngles > 0 && {random 1 > 0.3}) then {
        _angle = (selectRandom _linkAngles) + (random 60 - 30);
    };
    private _distance = random [_distributionRadius * 0.5, _distributionRadius, _distributionRadius * 1.2];

    private _offsetX = sin _angle * _distance;
    private _offsetY = cos _angle * _distance;
    private _groupPos = [(_position select 0) + _offsetX, (_position select 1) + _offsetY, 0];

    // For vehicle heavy groups, try to align positions along nearby roads
    if (_groupType in ["motorized", "mechanized", "armor"]) then {
        private _parking = [_groupPos, 200, 8 + random 5] call FLO_fnc_getRoadParkingPos;
        _groupPos = _parking select 0;
    };

    // Ensure position is not on water (unless naval group)
    if (!(_groupType in ["boat", "naval", "submarine"]) && {surfaceIsWater _groupPos}) then {
        _groupPos = [_groupPos, _distributionRadius] call FLO_fnc_getSafeLandPos;
    };

    // Find safe position near the calculated point
    private _safePos = [_groupPos, 0, 30, 3, 0, 0.5, 0] call BIS_fnc_findSafePos;

    // Create the virtual group
    private _groupId = [_safePos, _groupType, _groupCfg, _objective] call FLO_fnc_createVirtualGroup;
    _createdGroups pushBack _groupId;

    // Log creation
    ["VIRTUALIZATION", 3, format["Distributed %1 group at %2 - position: %3", _groupType, _markerName, _safePos]] call FLO_fnc_log;
};

// Return array of created group IDs
_createdGroups
