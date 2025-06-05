/*
 * Function: FLO_fnc_indexVirtualObjectives
 * Description: Finds clusters of structures not covered by existing objectives and adds them as new objectives to the given HashMap.
 * Arguments:
 *   0: Existing objectives HashMap (by reference)
 *   1: (Optional) Debug mode (default: false)
 * Returns: Number of new objectives added
 * Example: [FLO_Objectives, true] call FLO_fnc_indexVirtualObjectives;
 */

params [
    ["_objectives", createHashMap],
    ["_debug", false],
    ["_gridSize", 100]
];

private _minRadius = 90;
private _maxRadius = 300;

private _baseClasses = [
    "HeliH", "AirportBase", "Strategic", "House_F",
    "House_Small", "House", "HouseBase", "Church"
];

// 1. Gather all structures in one call
private _allStructures = nearestObjects [[worldSize/2, worldSize/2, 0], _baseClasses, worldSize];
diag_log format ["[VirtualObjectives] Found %1 structures at %2", count _allStructures, diag_tickTime];

// 2. Remove duplicates
private _uniqueStructures = [];
{
    if (!(_x in _uniqueStructures)) then { _uniqueStructures pushBack _x; };
} forEach _allStructures;
diag_log format ["[VirtualObjectives] Found %1 unique structures at %2", count _uniqueStructures, diag_tickTime];

// 3. Build grid for covered objectives
private _coveredGrid = createHashMap;
private _coveredList = [];
{
    private _data = _objectives get _x;
    if (!isNil "_data") then {
        private _pos = _data get "position";
        private _radius = (_data get "radius") max 60;
        _coveredList pushBack [_pos, _radius];
        // Mark all grid cells covered by this objective
        private _minX = floor ((_pos select 0 - _radius) / _gridSize);
        private _maxX = ceil  ((_pos select 0 + _radius) / _gridSize);
        private _minY = floor ((_pos select 1 - _radius) / _gridSize);
        private _maxY = ceil  ((_pos select 1 + _radius) / _gridSize);
        for "_gx" from _minX to _maxX do {
            for "_gy" from _minY to _maxY do {
                private _cell = format ["%1_%2", _gx, _gy];
                if (isNil {_coveredGrid get _cell}) then { _coveredGrid set [_cell, []]; };
                (_coveredGrid get _cell) pushBack [_pos, _radius];
            };
        };
    };
} forEach (keys _objectives);
diag_log format ["[VirtualObjectives] Built covered grid at %1", diag_tickTime];

// 4. Find uncovered structures using grid
private _uncovered = [];
{
    private _pos = getPosWorld _x;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];
    private _covered = false;
    private _cellList = _coveredGrid getOrDefault [_cell, []];
    {
        if (_pos distance2D (_x select 0) < (_x select 1)) exitWith { _covered = true; };
    } forEach _cellList;
    if (!_covered) then { _uncovered pushBack _x; };
} forEach _uniqueStructures;
diag_log format ["[VirtualObjectives] Found %1 uncovered structures at %2", count _uncovered, diag_tickTime];

// 5. Grid-based clustering
private _structureGrid = createHashMap;
{
    private _pos = getPosWorld _x;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];
    if (isNil {_structureGrid get _cell}) then { _structureGrid set [_cell, []]; };
    (_structureGrid get _cell) pushBack _x;
} forEach _uncovered;

private _clusters = [];
private _visited = createHashMap;
{
    private _pos = getPosWorld _x;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];
    if (!isNil {_visited get _cell}) then { continue; };
    // Gather all structures in this cell and neighbors
    private _cluster = [];
    for "_dx" from -1 to 1 do {
        for "_dy" from -1 to 1 do {
            private _ncell = format ["%1_%2", _gx + _dx, _gy + _dy];
            private _objs = _structureGrid getOrDefault [_ncell, []];
            { if (!(_x in _cluster)) then { _cluster pushBack _x; }; } forEach _objs;
            _visited set [_ncell, true];
        };
    };
    if (count _cluster > 0) then { _clusters pushBack _cluster; };
} forEach _uncovered;
diag_log format ["[VirtualObjectives] Found %1 clusters at %2", count _clusters, diag_tickTime];

// 6. For each cluster, create a new objective
private _newCount = 0;
for "_i" from 0 to (count _clusters - 1) do {
    private _cluster = _clusters select _i;
    // Skip tiny clusters
    if (count _cluster < 4) then { continue; };
    // Calculate centroid
    private _sumX = 0; private _sumY = 0; private _sumZ = 0;
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
    private _covered = false;
    {
        if (_centroid distance2D (_x select 0) < (_x select 1)) exitWith { _covered = true; };
    } forEach _coveredList;
    if (_covered) then { continue; };
    // Fast radius: max distance from centroid to any member, min _minRadius
    private _radius = _minRadius;
    {
        private _p = getPosWorld _x;
        private _dist = _centroid distance2D _p;
        if (_dist > _radius) then { _radius = _dist; };
    } forEach _cluster;
    _radius = (_radius + 10) min _maxRadius; // pad a bit, clamp to max
    if (count _cluster == 0) then { continue; };
    private _structCount = count _cluster;
    private _priority = (_structCount * 2) min 100 max 1;
    private _structurePositions = [];
    { _structurePositions pushBack (getPosWorld _x); } forEach _cluster;
    private _id = format ["virtual_%1", _i];
    private _objData = createHashMapFromArray [
        ["type", "virtual"],
        ["subtype", "cluster"],
        ["position", _centroid],
        ["priority", _priority],
        ["radius", _radius],
        ["structures", _cluster],
        ["structurePositions", _structurePositions],
        ["location", objNull],
        ["locType", "virtual"]
    ];
    _objectives set [_id, _objData];
    _newCount = _newCount + 1;
    // Debug marker
    if (_debug) then {
        private _marker = createMarkerLocal [format["obj_%1", _id], _centroid];
        _marker setMarkerShapeLocal "ELLIPSE";
        _marker setMarkerSizeLocal [_radius, _radius];
        _marker setMarkerColorLocal "ColorBlue";
        _marker setMarkerAlphaLocal 0.3;
        _marker setMarkerTextLocal format["V:%1", _priority];
        {
            private _sMarker = createMarkerLocal [format["obj_%1_struct_%2", _id, _forEachIndex], _x];
            _sMarker setMarkerTypeLocal "mil_dot";
            _sMarker setMarkerColorLocal "ColorBlack";
            _sMarker setMarkerAlphaLocal 0.7;
        } forEach _structurePositions;
    };
};

diag_log format ["[VirtualObjectives] Added %1 virtual objectives at %2", _newCount, diag_tickTime];

_newCount; 