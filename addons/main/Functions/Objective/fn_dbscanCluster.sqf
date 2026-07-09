/*
 * Function: FLO_fnc_dbscanCluster
 * Author: Frontline Operations Development Group
 * Description:
 *   DBSCAN (Density-Based Spatial Clustering of Applications with Noise) implementation.
 *   Optimized for large datasets using spatial grid and hashmap lookups.
 *
 * Arguments:
 *   0: Points (ARRAY of positions [x,y,z] or objects)
 *   1: Epsilon (NUMBER) - Maximum distance between points in same cluster
 *   2: MinPoints (NUMBER) - Minimum points to form a cluster (default: 3)
 *
 * Returns:
 *   ARRAY of clusters, where each cluster is an array of points
 *
 * Example:
 *   [_buildingPositions, 300, 3] call FLO_fnc_dbscanCluster;
 */

params [
    ["_points", []],
    ["_epsilon", 300],
    ["_minPoints", 3]
];

if (_points isEqualTo []) exitWith { [] };

private _startTime = diag_tickTime;

// Convert objects to positions if needed
private _positions = _points apply {
    if (_x isEqualType objNull) then { getPosWorld _x } else { _x }
};

private _count = count _positions;
diag_log format ["[DBSCAN] Starting clustering of %1 points...", _count];

// Use hashmaps for O(1) lookups instead of arrays
private _labels = createHashMap;      // pointIdx -> clusterId (-1 = noise)
private _visited = createHashMap;     // pointIdx -> bool

// Build spatial grid for faster neighbor queries
private _gridSize = _epsilon;
private _grid = createHashMap;

{
    private _pos = _x;
    private _idx = _forEachIndex;
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    private _cell = format ["%1_%2", _gx, _gy];
    
    private _cellData = _grid getOrDefault [_cell, []];
    _cellData pushBack _idx;
    _grid set [_cell, _cellData];
} forEach _positions;

diag_log format ["[DBSCAN] Built spatial grid with %1 cells", count _grid];

// Function to get neighbors within epsilon using spatial grid
private _fnc_getNeighbors = {
    params ["_pointIdx"];
    private _pos = _positions select _pointIdx;
    private _neighbors = [];
    
    private _gx = floor ((_pos select 0) / _gridSize);
    private _gy = floor ((_pos select 1) / _gridSize);
    
    // Check 3x3 grid cells around point
    for "_dx" from -1 to 1 do {
        for "_dy" from -1 to 1 do {
            private _cell = format ["%1_%2", _gx + _dx, _gy + _dy];
            private _cellData = _grid getOrDefault [_cell, []];
            
            {
                private _otherIdx = _x;
                if (_otherIdx != _pointIdx) then {
                    private _otherPos = _positions select _otherIdx;
                    if (_pos distance2D _otherPos <= _epsilon) then {
                        _neighbors pushBack _otherIdx;
                    };
                };
            } forEach _cellData;
        };
    };
    
    _neighbors
};

// DBSCAN algorithm with progress logging
private _clusterId = 0;
private _clusters = [];
private _lastLog = diag_tickTime;

for "_i" from 0 to (_count - 1) do {
    // Progress logging every 2 seconds
    if (diag_tickTime - _lastLog > 2) then {
        diag_log format ["[DBSCAN] Progress: %1/%2 points processed, %3 clusters found", 
            _i, _count, count _clusters];
        _lastLog = diag_tickTime;
    };
    
    if (_visited getOrDefault [_i, false]) then { continue };
    
    _visited set [_i, true];
    
    private _neighbors = [_i] call _fnc_getNeighbors;
    
    if (count _neighbors < _minPoints) then {
        _labels set [_i, -1]; // Mark as noise
        continue;
    };
    
    // Start new cluster
    private _currentCluster = [_i];
    _labels set [_i, _clusterId];
    
    // Process neighbors using hashmap for O(1) "in seedset" checks
    private _seedSet = createHashMap;
    { _seedSet set [_x, true]; } forEach _neighbors;
    
    private _seedQueue = +_neighbors; // Work queue
    
    while {_seedQueue isNotEqualTo []} do {
        private _q = _seedQueue deleteAt 0;
        
        if (!(_visited getOrDefault [_q, false])) then {
            _visited set [_q, true];
            private _qNeighbors = [_q] call _fnc_getNeighbors;
            
            if (count _qNeighbors >= _minPoints) then {
                // Add new neighbors to seed set (O(1) lookup)
                {
                    if !(_seedSet getOrDefault [_x, false]) then {
                        _seedSet set [_x, true];
                        _seedQueue pushBack _x;
                    };
                } forEach _qNeighbors;
            };
        };
        
        // Add to cluster if not already in one
        if ((_labels getOrDefault [_q, -1]) == -1) then {
            _labels set [_q, _clusterId];
            _currentCluster pushBack _q;
        };
    };
    
    if (count _currentCluster >= _minPoints) then {
        _clusters pushBack _currentCluster;
    };
    _clusterId = _clusterId + 1;
};

// Convert cluster indices back to positions
private _result = _clusters apply {
    private _cluster = _x;
    _cluster apply { _positions select _x }
};

private _elapsed = diag_tickTime - _startTime;
diag_log format ["[DBSCAN] Completed in %1s: %2 points -> %3 clusters (epsilon: %4, minPoints: %5)", 
    round(_elapsed * 10) / 10, _count, count _result, _epsilon, _minPoints];

_result
