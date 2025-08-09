/*
 * Function: FLO_fnc_indexVirtualObjectives
 * Description: Finds clusters of structures not covered by existing objectives and adds them as new objectives to the given HashMap.
 * Power line structures (PowerLines_base_F) are ignored when gathering structures.
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

// Debug logging for initial parameter values
["OBJECTIVE", 3, format["fn_indexVirtualObjectives called with _gridSize: %1 (type: %2)", _gridSize, typeName _gridSize]] call FLO_fnc_log;

// Safety check for gridSize at function level
if (!(_gridSize isEqualType 0) || _gridSize <= 0) then {
    ["OBJECTIVE", 3, format["Invalid gridSize detected at function start: %1 (type: %2). Using fallback value of 100", _gridSize, typeName _gridSize]] call FLO_fnc_log;
    _gridSize = 100;
};

private _minRadius = 90;
private _maxRadius = 300;

private _baseClasses = [
    "HeliH", "AirportBase", "Strategic", "House_F",
    "House_Small", "House", "HouseBase", "Church"
];

// 1. Gather all structures in one call
private _allStructures = nearestObjects [[worldSize/2, worldSize/2, 0], _baseClasses, worldSize];
_allStructures = _allStructures select { !(_x isKindOf "PowerLines_base_F") };

// 2. Remove duplicates
private _uniqueStructures = [];
{
    if (!(_x in _uniqueStructures)) then { _uniqueStructures pushBack _x; };
} forEach _allStructures;

// 3. Build grid for covered objectives
private _coveredGrid = createHashMap;
private _coveredList = [];
{
    private _data = _objectives get _x;
    if (!isNil "_data") then {
        private _pos = _data get "position";
        private _radius = (_data get "radius") max 60;
        _coveredList pushBack [_pos, _radius];

        // Debug logging for zero divisor issue
        ["OBJECTIVE", 3, format["fn_indexVirtualObjectives - _gridSize value: %1, type: %2", _gridSize, typeName _gridSize]] call FLO_fnc_log;
        ["OBJECTIVE", 3, format["fn_indexVirtualObjectives - _pos: %1, _radius: %2", _pos, _radius]] call FLO_fnc_log;

        // Force gridSize to be valid right before calculation
        private _safeGridSize = 100;
        ["OBJECTIVE", 3, format["fn_indexVirtualObjectives - Forced _safeGridSize to: %1", _safeGridSize]] call FLO_fnc_log;

        private _posX = _pos select 0;
        private _posY = _pos select 1;
        ["OBJECTIVE", 3, format["fn_indexVirtualObjectives - _posX: %1, _posY: %2, _radius: %3", _posX, _posY, _radius]] call FLO_fnc_log;   

        // Calculate bounds step by step
        private _leftBound = _posX - _radius;
        private _rightBound = _posX + _radius;
        private _topBound = _posY - _radius;
        private _bottomBound = _posY + _radius;

        ["OBJECTIVE", 3, format["fn_indexVirtualObjectives - bounds: left=%1, right=%2, top=%3, bottom=%4", _leftBound, _rightBound, _topBound, _bottomBound]] call FLO_fnc_log;
        // Perform division with explicit safety check
        private _minX = 0;
        private _maxX = 0;
        private _minY = 0;
        private _maxY = 0;

        if (_safeGridSize > 0) then {
            _minX = floor (_leftBound / _safeGridSize);
            _maxX = ceil (_rightBound / _safeGridSize);
            _minY = floor (_topBound / _safeGridSize);
            _maxY = ceil (_bottomBound / _safeGridSize);
        } else {
            diag_log "[FLO_ERROR] _safeGridSize is still zero or negative!";
            _minX = 0;
            _maxX = 1;
            _minY = 0;
            _maxY = 1;
        };

        ["OBJECTIVE", 3, format["fn_indexVirtualObjectives - grid bounds: minX=%1, maxX=%2, minY=%3, maxY=%4", _minX, _maxX, _minY, _maxY]] call FLO_fnc_log;
        for "_gx" from _minX to _maxX do {
            for "_gy" from _minY to _maxY do {
                private _cell = format ["%1_%2", _gx, _gy];
                if (isNil {_coveredGrid get _cell}) then { _coveredGrid set [_cell, []]; };
                (_coveredGrid get _cell) pushBack [_pos, _radius];
            };
        };
    };
} forEach (keys _objectives);

// 4. Find uncovered structures using grid
private _uncovered = [];
{
    private _pos = getPosWorld _x;
    private _safeGridSize = _gridSize;
    if (!(_safeGridSize isEqualType 0) || _safeGridSize <= 0) then { _safeGridSize = 100; };
    private _gx = floor ((_pos select 0) / _safeGridSize);
    private _gy = floor ((_pos select 1) / _safeGridSize);
    private _cell = format ["%1_%2", _gx, _gy];
    private _covered = false;
    private _cellList = _coveredGrid getOrDefault [_cell, []];
    {
        if (_pos distance2D (_x select 0) < (_x select 1)) exitWith { _covered = true; };
    } forEach _cellList;
    if (!_covered) then { _uncovered pushBack _x; };
} forEach _uniqueStructures;

// 5. Grid-based clustering
private _structureGrid = createHashMap;
{
    private _pos = getPosWorld _x;
    private _safeGridSize = _gridSize;
    if (!(_safeGridSize isEqualType 0) || _safeGridSize <= 0) then { _safeGridSize = 100; };
    private _gx = floor ((_pos select 0) / _safeGridSize);
    private _gy = floor ((_pos select 1) / _safeGridSize);
    private _cell = format ["%1_%2", _gx, _gy];
    if (isNil {_structureGrid get _cell}) then { _structureGrid set [_cell, []]; };
    (_structureGrid get _cell) pushBack _x;
} forEach _uncovered;

private _clusters = [];
private _visited = createHashMap;
{
    private _pos = getPosWorld _x;
    private _safeGridSize = _gridSize;
    if (!(_safeGridSize isEqualType 0) || _safeGridSize <= 0) then { _safeGridSize = 100; };
    private _gx = floor ((_pos select 0) / _safeGridSize);
    private _gy = floor ((_pos select 1) / _safeGridSize);
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

// 6. For each cluster, create a new objective
private _newCount = 0;
for "_i" from 0 to (count _clusters - 1) do {
    private _cluster = _clusters select _i;
    // Get minimum cluster size based on configuration
    private _minClusterSize = switch (OPFOR_Objective_Size_Threshold) do {
        case "Small": { 4 };
        case "Medium": { 8 };
        case "Large": { 12 };
        case "Huge": { 24 };
        default { 4 }; // Default to Small if invalid setting
    };
    // Skip clusters smaller than threshold
    if (count _cluster < _minClusterSize) then { continue; };
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
        ["locType", "virtual"],
        ["owner", east]
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

_newCount; 