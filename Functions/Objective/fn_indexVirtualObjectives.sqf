/*
 * Function: FLO_fnc_indexVirtualObjectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds clusters of structures not covered by existing objectives and adds
 *   them as new "virtual" objectives to the given HashMap.
 *
 * Arguments:
 *   0: Existing objectives HashMap (by reference)
 *   1: Debug mode (BOOL) - Optional, default from config
 *   2: Grid size (NUMBER) - Optional, default from config
 *
 * Returns: Number of new objectives added
 *
 * Example:
 *   [FLO_Objectives, true, 100] call FLO_fnc_indexVirtualObjectives;
 */

params [
    ["_objectives", createHashMap],
    ["_debug", nil],
    ["_gridSize", nil]
];

// Initialize and get config values
["init"] call FLO_fnc_objectiveConfig;

// Use config defaults if not provided
if (isNil "_debug") then { _debug = ["get", "debug"] call FLO_fnc_objectiveConfig };
if (isNil "_gridSize" || {!(_gridSize isEqualType 0)} || {_gridSize <= 0}) then {
    _gridSize = ["get", "gridSize"] call FLO_fnc_objectiveConfig;
};

private _minRadius = ["get", "minRadius"] call FLO_fnc_objectiveConfig;
private _maxRadius = ["get", "maxRadius"] call FLO_fnc_objectiveConfig;
private _baseClasses = ["get", "baseClasses"] call FLO_fnc_objectiveConfig;
private _excludeClasses = ["get", "excludeClasses"] call FLO_fnc_objectiveConfig;
private _minClusterSizes = ["get", "minClusterSize"] call FLO_fnc_objectiveConfig;

// 1. Gather all structures in one call
private _allStructures = nearestObjects [[worldSize/2, worldSize/2, 0], _baseClasses, worldSize];

// Filter excluded classes
_allStructures = _allStructures select {
    private _obj = _x;
    !({ _obj isKindOf _x } count _excludeClasses > 0)
};

// 2. Build grid for covered objectives (spatial hash)
private _coveredGrid = createHashMap;
private _coveredList = [];

{
    private _data = _objectives get _x;
    if (isNil "_data") then { continue };

    private _pos = _data get "position";
    private _radius = (_data getOrDefault ["radius", 60]) max 60;
    _coveredList pushBack [_pos, _radius];

    // Calculate grid cells this objective covers
    private _posX = _pos select 0;
    private _posY = _pos select 1;
    private _minX = floor ((_posX - _radius) / _gridSize);
    private _maxX = ceil ((_posX + _radius) / _gridSize);
    private _minY = floor ((_posY - _radius) / _gridSize);
    private _maxY = ceil ((_posY + _radius) / _gridSize);

    // Mark all cells in bounding box
    for "_gx" from _minX to _maxX do {
        for "_gy" from _minY to _maxY do {
            private _cell = format ["%1_%2", _gx, _gy];
            private _cellList = _coveredGrid getOrDefault [_cell, []];
            _cellList pushBack [_pos, _radius];
            _coveredGrid set [_cell, _cellList];
        };
    };
} forEach (keys _objectives);

// 3. Find uncovered structures using spatial grid
private _uncovered = _allStructures select {
    private _pos = getPosWorld _x;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];

    // Check if covered by any objective in this cell
    private _cellList = _coveredGrid getOrDefault [_cell, []];
    private _isCovered = false;
    { if (_pos distance2D (_x select 0) < (_x select 1)) exitWith { _isCovered = true } } forEach _cellList;
    !_isCovered
};

// 4. Build structure grid for clustering
private _structureGrid = createHashMap;
{
    private _pos = getPosWorld _x;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];

    private _cellList = _structureGrid getOrDefault [_cell, []];
    _cellList pushBack _x;
    _structureGrid set [_cell, _cellList];
} forEach _uncovered;

// 5. Cluster adjacent grid cells
private _clusters = [];
private _visited = createHashMap;

{
    private _pos = getPosWorld _x;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];

    // Skip already visited cells
    if (_cell in keys _visited) then { continue };

    // Gather all structures in this cell and neighbors (3x3 grid)
    private _cluster = [];
    for "_dx" from -1 to 1 do {
        for "_dy" from -1 to 1 do {
            private _ncell = format ["%1_%2", _gx + _dx, _gy + _dy];
            private _objs = _structureGrid getOrDefault [_ncell, []];
            { _cluster pushBackUnique _x } forEach _objs;
            _visited set [_ncell, true];
        };
    };

    if (count _cluster > 0) then { _clusters pushBack _cluster };
} forEach _uncovered;

// 6. Create objectives from clusters
private _newCount = 0;

// Get minimum cluster size from config
private _sizeThreshold = if (!isNil "OPFOR_Objective_Size_Threshold") then { OPFOR_Objective_Size_Threshold } else { "Small" };
private _minClusterSize = _minClusterSizes getOrDefault [_sizeThreshold, 4];

{
    private _cluster = _x;
    private _clusterIndex = _forEachIndex;

    // Skip clusters smaller than threshold
    if (count _cluster < _minClusterSize) then { continue };

    // Calculate centroid
    private _sumX = 0;
    private _sumY = 0;
    private _sumZ = 0;
    {
        private _p = getPosWorld _x;
        _sumX = _sumX + (_p select 0);
        _sumY = _sumY + (_p select 1);
        _sumZ = _sumZ + (_p select 2);
    } forEach _cluster;

    private _centroid = [
        _sumX / (count _cluster),
        _sumY / (count _cluster),
        _sumZ / (count _cluster)
    ];

    // Check if centroid is covered by any existing objective
    private _isCovered = false;
    { if (_centroid distance2D (_x select 0) < (_x select 1)) exitWith { _isCovered = true } } forEach _coveredList;
    if (_isCovered) then { continue };

    // Calculate radius: max distance from centroid to any member
    private _radius = _minRadius;
    {
        private _dist = _centroid distance2D (getPosWorld _x);
        if (_dist > _radius) then { _radius = _dist };
    } forEach _cluster;
    _radius = (_radius + 10) min _maxRadius;

    // Calculate priority
    private _structCount = count _cluster;
    private _priority = (_structCount * 2) min 100 max 1;

    // Collect structure positions
    private _structurePositions = _cluster apply { getPosWorld _x };

    // Create objective data
    private _id = format ["virtual_%1", _clusterIndex];
    private _objData = createHashMapFromArray [
        ["type", "virtual"],
        ["subtype", "cluster"],
        ["position", _centroid],
        ["priority", _priority],
        ["radius", _radius],
        ["structures", _cluster],
        ["structurePositions", _structurePositions],
        ["location", ""],
        ["locType", "virtual"],
        ["owner", east],
        ["polygon", []],
        ["usePolygon", false],
        ["markerIds", []]
    ];

    _objectives set [_id, _objData];
    _newCount = _newCount + 1;

    // Debug marker
    if (_debug) then {
        private _marker = createMarkerLocal [format ["obj_%1", _id], _centroid];
        _marker setMarkerShapeLocal "ELLIPSE";
        _marker setMarkerSizeLocal [_radius, _radius];
        _marker setMarkerColorLocal "ColorBlue";
        _marker setMarkerAlphaLocal 0.3;
        _marker setMarkerTextLocal format ["V:%1", _priority];

        {
            private _sMarker = createMarkerLocal [format ["obj_%1_struct_%2", _id, _forEachIndex], _x];
            _sMarker setMarkerTypeLocal "mil_dot";
            _sMarker setMarkerColorLocal "ColorBlack";
            _sMarker setMarkerAlphaLocal 0.7;
        } forEach _structurePositions;
    };
} forEach _clusters;

_newCount