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

// Remove PowerLines_base_F
_uniqueStructures = _uniqueStructures select {typeOf _x != "PowerLines_base_F"};

diag_log format ["[VirtualObjectives] Filtered PowerLines_base_F, %1 structures remain at %2", count _uniqueStructures, diag_tickTime];

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
    // Exclude PowerLines_base_F from clusters (extra safety)
    _cluster = _cluster select {typeOf _x != "PowerLines_base_F"};
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
    // // Debug marker
    // if (_debug) then {
    //     private _marker = createMarkerLocal [format["obj_%1", _id], _centroid];
    //     _marker setMarkerShapeLocal "ELLIPSE";
    //     _marker setMarkerSizeLocal [_radius, _radius];
    //     _marker setMarkerColorLocal "ColorBlue";
    //     _marker setMarkerAlphaLocal 0.3;
    //     _marker setMarkerTextLocal format["V:%1", _priority];
    //     {
    //         private _sMarker = createMarkerLocal [format["obj_%1_struct_%2", _id, _forEachIndex], _x];
    //         _sMarker setMarkerTypeLocal "mil_dot";
    //         _sMarker setMarkerColorLocal "ColorBlack";
    //         _sMarker setMarkerAlphaLocal 0.7;
    //     } forEach _structurePositions;
    // };
};

diag_log format ["[VirtualObjectives] Added %1 virtual objectives at %2", _newCount, diag_tickTime];

// --- Merge overlapping objectives (multi-pass, capped) ---
private _maxMergePasses = 5;
private _mergePass = 0;
private _mergedCount = 1;
while {_mergedCount > 0 && _mergePass < _maxMergePasses} do {
    _mergedCount = 0;
    private _keys = keys _objectives;
    private _merged = [];
    for "_i" from 0 to (count _keys - 1) do {
        private _id1 = _keys select _i;
        if (_id1 in _merged) then { continue; };
        private _obj1 = _objectives get _id1;
        private _pos1 = _obj1 get "position";
        private _rad1 = _obj1 get "radius";
        for "_j" from (_i + 1) to (count _keys - 1) do {
            private _id2 = _keys select _j;
            if (_id2 in _merged) then { continue; };
            private _obj2 = _objectives get _id2;
            private _pos2 = _obj2 get "position";
            private _rad2 = _obj2 get "radius";
            if (_pos1 distance2D _pos2 < ((_rad1 + _rad2) * 0.5)) then {
                // Merge: combine structures, recalc centroid/radius, update _obj1, mark _id2 for removal
                private _allStructs = (_obj1 get "structures") + (_obj2 get "structures");
                // Remove duplicates
                private _allStructsUnique = [];
                { if (!(_x in _allStructsUnique)) then { _allStructsUnique pushBack _x; }; } forEach _allStructs;
                // Recalculate centroid
                private _sumX = 0; private _sumY = 0; private _sumZ = 0;
                { private _p = getPosWorld _x; _sumX = _sumX + (_p select 0); _sumY = _sumY + (_p select 1); _sumZ = _sumZ + (_p select 2); } forEach _allStructsUnique;
                private _centroid = [
                    _sumX / (count _allStructsUnique),
                    _sumY / (count _allStructsUnique),
                    _sumZ / (count _allStructsUnique)
                ];
                // Recalculate radius
                private _radius = _minRadius;
                { private _p = getPosWorld _x; private _dist = _centroid distance2D _p; if (_dist > _radius) then { _radius = _dist; }; } forEach _allStructsUnique;
                _radius = (_radius + 10) min _maxRadius;
                // Update obj1
                _obj1 set ["position", _centroid];
                _obj1 set ["radius", _radius];
                _obj1 set ["structures", _allStructsUnique];
                private _structurePositions = [];
                { _structurePositions pushBack (getPosWorld _x); } forEach _allStructsUnique;
                _obj1 set ["structurePositions", _structurePositions];
                _obj1 set ["priority", ((count _allStructsUnique) * 2) min 100 max 1];
                // Mark obj2 for removal
                _merged pushBack _id2;
                _mergedCount = _mergedCount + 1;
            };
        };
    };
    { _objectives deleteAt _x; } forEach _merged;
    _mergePass = _mergePass + 1;
};

diag_log format ["[VirtualObjectives] Merged objectives in %1 passes at %2", _mergePass, diag_tickTime];

// --- Debug marker creation for final objectives ---
if (_debug) then {
    private _finalKeys = keys _objectives;
    for "_i" from 0 to (count _finalKeys - 1) do {
        private _id = _finalKeys select _i;
        private _data = _objectives get _id;
        private _centroid = _data get "position";
        private _radius = _data get "radius";
        private _priority = _data get "priority";
        private _structurePositions = _data get "structurePositions";
        private _marker = createMarkerLocal [format["vobj_%1", _id], _centroid];
        _marker setMarkerShapeLocal "ELLIPSE";
        _marker setMarkerSizeLocal [_radius, _radius];
        _marker setMarkerColorLocal "ColorBlue";
        _marker setMarkerAlphaLocal 0.3;
        _marker setMarkerTextLocal format["V:%1", _priority];
        {
            private _sMarker = createMarkerLocal [format["vobj_%1_struct_%2", _id, _forEachIndex], _x];
            _sMarker setMarkerTypeLocal "mil_dot";
            _sMarker setMarkerColorLocal "ColorBlack";
            _sMarker setMarkerAlphaLocal 0.7;
        } forEach _structurePositions;
    };
};

_newCount; 