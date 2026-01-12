/*
 * Function: FLO_fnc_advancedObjectiveIndexer
 * Author: Frontline Operations Development Group
 * Description:
 *   Fast objective generation using map location sizes.
 *   Uses Arma's built-in location size data - no expensive scanning.
 *   Uses DBSCAN clustering for realistic objective placement of non-locations.
 *
 * Arguments: None
 * Returns: HashMap of all objectives (stored in FLO_Objectives)
 * Example: [] call FLO_fnc_advancedObjectiveIndexer;
 */

diag_log "[ADV_INDEX] Starting fast objective indexing...";

// === PHASE 1: Get all map locations with their sizes ===
private _center = [worldSize/2, worldSize/2, 0];

// Location types - NameLocal removed to avoid clutter, small objectives caught by DBSCAN
private _locationConfigs = [
    ["NameCityCapital", "civilian", "capital", 100, 1.5],  // Size multiplier
    ["NameCity", "civilian", "city", 75, 1.3],
    ["NameVillage", "civilian", "village", 50, 1.2],
    ["Airport", "military", "airfield", 95, 1.5],
    ["Strategic", "military", "strategic", 85, 1.2]
];

private _allLocations = [];

{
    _x params ["_locType", "_category", "_subtype", "_basePriority", "_sizeMultiplier"];
    private _locs = nearestLocations [_center, [_locType], worldSize];
    
    {
        private _loc = _x;
        private _locPos = locationPosition _loc;
        private _locName = text _loc;
        private _locSize = size _loc;  // Returns [width, height]
        
        // Calculate radius from location's actual size
        private _width = _locSize select 0;
        private _height = _locSize select 1;
        private _radius = ((_width max _height) * _sizeMultiplier) max 100;
        
        _allLocations pushBack [_locPos, _locName, _locType, _category, _subtype, _basePriority, _radius];
        
    } forEach _locs;
} forEach _locationConfigs;

diag_log format ["[ADV_INDEX] Found %1 map locations", count _allLocations];

// === PHASE 2: Merge overlapping locations (single pass) ===
private _mergedObjectives = [];
private _used = createHashMap;

// Sort by priority (highest first) so big cities absorb smaller overlapping areas
_allLocations = [_allLocations, [], {_x select 5}, "DESCEND"] call BIS_fnc_sortBy;

{
    private _idx = _forEachIndex;
    if (_used getOrDefault [_idx, false]) then { continue };
    
    _x params ["_pos", "_name", "_locType", "_category", "_subtype", "_priority", "_radius"];
    
    private _mergedRadius = _radius;
    private _mergeCount = 1;
    
    // Find overlapping locations
    {
        private _otherIdx = _forEachIndex;
        if (_otherIdx == _idx || {_used getOrDefault [_otherIdx, false]}) then { continue };
        
        _x params ["_oPos", "_oName", "_oLocType", "_oCategory", "_oSubtype", "_oPriority", "_oRadius"];
        
        private _dist = _pos distance2D _oPos;
        
        // Merge only if centers are very close (40% of combined radii)
        // This prevents nearby but distinct settlements from merging
        if (_dist < ((_radius + _oRadius) * 0.4)) then {
            _used set [_otherIdx, true];
            _mergeCount = _mergeCount + 1;
            
            // Expand radius to cover merged location
            private _neededRadius = _dist + _oRadius;
            if (_neededRadius > _mergedRadius) then { _mergedRadius = _neededRadius };
        };
    } forEach _allLocations;
    
    _used set [_idx, true];
    
    _mergedObjectives pushBack [_pos, _name, _category, _subtype, _priority, _mergedRadius, _mergeCount];
    
    diag_log format ["[ADV_INDEX] %1 (%2): radius %3m%4", 
        _name, _subtype, round _mergedRadius, 
        if (_mergeCount > 1) then { format [" (merged %1)", _mergeCount] } else { "" }];
    
} forEach _allLocations;

diag_log format ["[ADV_INDEX] Created %1 objectives", count _mergedObjectives];

// === PHASE 3: Create objectives HashMap ===
private _allObjectives = createHashMap;
private _objectiveIndex = 0;

{
    _x params ["_pos", "_name", "_category", "_subtype", "_priority", "_radius", "_mergeCount"];
    
    private _objId = if (_name != "") then {
        private _safeName = _name regexReplace ["[^a-zA-Z0-9]", "_"];
        format ["obj_%1_%2", _safeName, _objectiveIndex]
    } else {
        format ["loc_%1", _objectiveIndex]
    };
    
    private _objData = createHashMapFromArray [
        ["type", _category],
        ["subtype", _subtype],
        ["position", _pos],
        ["priority", _priority],
        ["radius", _radius],
        ["polygon", []],
        ["usePolygon", false],
        ["structures", []],
        ["structureCount", 0],
        ["structurePositions", []],
        ["location", _objId],
        ["locType", "location_based"],
        ["owner", east],
        ["name", _name],
        ["markerIds", []],
        ["linkedObjectives", []],
        ["mergedCount", _mergeCount]
    ];
    
    _allObjectives set [_objId, _objData];
    _objectiveIndex = _objectiveIndex + 1;
    
} forEach _mergedObjectives;

// === PHASE 4: DBSCAN pass for uncovered small objectives ===
// Find buildings not covered by existing objectives and cluster them
diag_log "[ADV_INDEX] Running DBSCAN for uncovered areas...";

private _coveredPositions = _mergedObjectives apply { _x select 0 };
private _coveredRadii = _mergedObjectives apply { _x select 5 };

// Get all buildings and filter to uncovered ones
private _allBuildings = nearestTerrainObjects [_center, ["HOUSE", "BUILDING"], worldSize, false];
private _uncoveredBuildings = _allBuildings select {
    private _bPos = getPos _x;
    private _isCovered = false;
    {
        private _objPos = _coveredPositions select _forEachIndex;
        private _objRad = _coveredRadii select _forEachIndex;
        if (_bPos distance2D _objPos < _objRad) exitWith { _isCovered = true };
    } forEach _coveredPositions;
    !_isCovered
};

diag_log format ["[ADV_INDEX] Found %1 uncovered buildings", count _uncoveredBuildings];

// Only run DBSCAN if there are uncovered buildings
if (count _uncoveredBuildings > 10) then {
    private _uncoveredPositions = _uncoveredBuildings apply { getPos _x };
    private _clusters = [_uncoveredPositions, 150, 5] call FLO_fnc_dbscanCluster;  // Smaller epsilon
    
    diag_log format ["[ADV_INDEX] DBSCAN found %1 additional clusters", count _clusters];
    
    {
        private _cluster = _x;
        if (count _cluster < 5) then { continue };
        
        // Calculate centroid and radius
        private _sumX = 0; private _sumY = 0;
        { _sumX = _sumX + (_x select 0); _sumY = _sumY + (_x select 1); } forEach _cluster;
        private _clusterPos = [_sumX / count _cluster, _sumY / count _cluster, 0];
        
        private _maxDist = 0;
        { private _d = _clusterPos distance2D _x; if (_d > _maxDist) then { _maxDist = _d }; } forEach _cluster;
        
        // CAP radius at 400m - DBSCAN is for small objectives only
        private _clusterRadius = ((_maxDist + 30) max 100) min 400;
        
        // SKIP if this cluster overlaps with any existing location-based objective
        private _overlapsExisting = false;
        {
            private _objPos = _coveredPositions select _forEachIndex;
            private _objRad = _coveredRadii select _forEachIndex;
            if (_clusterPos distance2D _objPos < (_objRad + _clusterRadius) * 0.6) exitWith {
                _overlapsExisting = true;
            };
        } forEach _coveredPositions;
        
        if (_overlapsExisting) then { continue };
        
        // Create small objective
        private _objId = format ["cluster_%1", _objectiveIndex];
        private _objData = createHashMapFromArray [
            ["type", "military"],
            ["subtype", "compound"],
            ["position", _clusterPos],
            ["priority", 40],
            ["radius", _clusterRadius],
            ["polygon", []],
            ["usePolygon", false],
            ["structures", []],
            ["structureCount", count _cluster],
            ["structurePositions", _cluster],
            ["location", _objId],
            ["locType", "dbscan"],
            ["owner", east],
            ["name", ""],
            ["markerIds", []],
            ["linkedObjectives", []],
            ["mergedCount", 1]
        ];
        
        _allObjectives set [_objId, _objData];
        _objectiveIndex = _objectiveIndex + 1;
        
        diag_log format ["[ADV_INDEX] Added cluster objective: %1 buildings, radius %2m", count _cluster, round _clusterRadius];
        
    } forEach _clusters;
};

// === PHASE 5: Link objectives ===
private _keys = keys _allObjectives;
{
    private _id = _x;
    private _data = _allObjectives get _id;
    private _pos = _data get "position";
    private _links = _keys select { _x != _id && { ((_allObjectives get _x) get "position") distance2D _pos < 3000 } };
    _data set ["linkedObjectives", _links];
} forEach _keys;

// === PHASE 6: Store and create markers ===
FLO_Objectives = _allObjectives;
publicVariable "FLO_Objectives";

{ [_x, _allObjectives get _x] call FLO_fnc_createObjectiveMarker } forEach _keys;

diag_log format ["[ADV_INDEX] Complete: %1 objectives (locations + DBSCAN)", count _allObjectives];

_allObjectives
