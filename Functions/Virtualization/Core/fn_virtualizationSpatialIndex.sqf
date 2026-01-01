/*
 * Function: FLO_fnc_virtualizationSpatialIndex
 * Author: Frontline Operations Development Group
 * Description:
 *   Spatial grid index for fast O(1) lookups of virtual groups by area.
 *   Divides the map into grid cells for efficient proximity queries.
 *
 * Arguments:
 * 0: Mode <STRING> - "init", "add", "remove", "update", "query", "queryRadius"
 * 1: Args <ARRAY> - Mode-specific arguments
 *
 * Return Value:
 * Varies by mode
 *
 * Examples:
 * ["init", [500]] call FLO_fnc_virtualizationSpatialIndex;           // Init with 500m cells
 * ["add", [_groupId, _position]] call FLO_fnc_virtualizationSpatialIndex;
 * ["queryRadius", [_pos, 1000]] call FLO_fnc_virtualizationSpatialIndex;  // Groups within 1000m
 */

params [["_mode", "init", [""]], ["_args", [], [[]]]];

// ============================================================================
// INITIALIZATION
// ============================================================================
if (isNil "FLO_VirtSpatial") then {
    FLO_VirtSpatial = createHashMapFromArray [
        ["cellSize", 500],
        ["grid", createHashMap],        // "cellX_cellY" -> [groupId1, groupId2, ...]
        ["groupCells", createHashMap],  // groupId -> "cellX_cellY" (for fast removal)
        ["mapSize", 30720]              // Default Altis size, will be updated
    ];
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get cell key from position
private _getCellKey = {
    params ["_pos"];
    private _cellSize = FLO_VirtSpatial get "cellSize";
    private _cellX = floor ((_pos select 0) / _cellSize);
    private _cellY = floor ((_pos select 1) / _cellSize);
    format ["%1_%2", _cellX, _cellY]
};

// Get all cell keys within radius
private _getCellsInRadius = {
    params ["_pos", "_radius"];
    private _cellSize = FLO_VirtSpatial get "cellSize";
    private _centerX = floor ((_pos select 0) / _cellSize);
    private _centerY = floor ((_pos select 1) / _cellSize);
    private _cellRadius = ceil (_radius / _cellSize);
    
    private _cells = [];
    for "_x" from (_centerX - _cellRadius) to (_centerX + _cellRadius) do {
        for "_y" from (_centerY - _cellRadius) to (_centerY + _cellRadius) do {
            _cells pushBack format ["%1_%2", _x, _y];
        };
    };
    _cells
};

// ============================================================================
// MODE HANDLERS
// ============================================================================

switch (toLower _mode) do {

    // Initialize the spatial index
    case "init": {
        _args params [["_cellSize", 500, [0]]];
        
        FLO_VirtSpatial set ["cellSize", _cellSize];
        FLO_VirtSpatial set ["grid", createHashMap];
        FLO_VirtSpatial set ["groupCells", createHashMap];
        FLO_VirtSpatial set ["mapSize", worldSize];
        
        ["VIRTUALIZATION", 3, format["Spatial index initialized (cell size: %1m)", _cellSize]] call FLO_fnc_log;
        true
    };

    // Add a group to the index
    case "add": {
        _args params ["_groupId", "_position"];
        
        if (isNil "_groupId" || isNil "_position") exitWith { false };
        
        private _cellKey = [_position] call _getCellKey;
        private _grid = FLO_VirtSpatial get "grid";
        private _groupCells = FLO_VirtSpatial get "groupCells";
        
        // Add to grid
        private _cell = _grid getOrDefault [_cellKey, []];
        if !(_groupId in _cell) then {
            _cell pushBack _groupId;
            _grid set [_cellKey, _cell];
        };
        
        // Track group's cell
        _groupCells set [_groupId, _cellKey];
        
        true
    };

    // Remove a group from the index
    case "remove": {
        _args params ["_groupId"];
        
        if (isNil "_groupId") exitWith { false };
        
        private _groupCells = FLO_VirtSpatial get "groupCells";
        private _cellKey = _groupCells getOrDefault [_groupId, ""];
        
        if (_cellKey != "") then {
            private _grid = FLO_VirtSpatial get "grid";
            private _cell = _grid getOrDefault [_cellKey, []];
            _cell = _cell - [_groupId];
            
            if (count _cell == 0) then {
                _grid deleteAt _cellKey;
            } else {
                _grid set [_cellKey, _cell];
            };
            
            _groupCells deleteAt _groupId;
        };
        
        true
    };

    // Update a group's position in the index
    case "update": {
        _args params ["_groupId", "_newPosition"];
        
        if (isNil "_groupId" || isNil "_newPosition") exitWith { false };
        
        private _groupCells = FLO_VirtSpatial get "groupCells";
        private _oldCellKey = _groupCells getOrDefault [_groupId, ""];
        private _newCellKey = [_newPosition] call _getCellKey;
        
        // Only update if cell changed
        if (_oldCellKey != _newCellKey) then {
            ["remove", [_groupId]] call FLO_fnc_virtualizationSpatialIndex;
            ["add", [_groupId, _newPosition]] call FLO_fnc_virtualizationSpatialIndex;
        };
        
        true
    };

    // Query groups in a specific cell
    case "query": {
        _args params ["_position"];
        
        private _cellKey = [_position] call _getCellKey;
        private _grid = FLO_VirtSpatial get "grid";
        
        _grid getOrDefault [_cellKey, []]
    };

    // Query groups within radius of position
    case "queryradius": {
        _args params ["_position", "_radius"];
        
        private _cells = [_position, _radius] call _getCellsInRadius;
        private _grid = FLO_VirtSpatial get "grid";
        private _result = [];
        
        {
            private _groupIds = _grid getOrDefault [_x, []];
            _result append _groupIds;
        } forEach _cells;
        
        // Remove duplicates and return
        _result arrayIntersect _result
    };

    // Rebuild entire index from current groups
    case "rebuild": {
        if (isNil "FLO_virtualGroups") exitWith { false };
        
        FLO_VirtSpatial set ["grid", createHashMap];
        FLO_VirtSpatial set ["groupCells", createHashMap];
        
        private _groups = FLO_virtualGroups get "_groups";
        {
            private _pos = _y get "position";
            ["add", [_x, _pos]] call FLO_fnc_virtualizationSpatialIndex;
        } forEach _groups;
        
        ["VIRTUALIZATION", 3, format["Spatial index rebuilt: %1 groups", count keys _groups]] call FLO_fnc_log;
        true
    };

    default { nil };
};

