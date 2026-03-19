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
 * ["add", [_groupId, _position, east]] call FLO_fnc_virtualizationSpatialIndex;
 * ["queryRadius", [_pos, 1000]] call FLO_fnc_virtualizationSpatialIndex;  // Groups in overlapping cells
 * ["queryRadius", [_pos, 1000, west, true]] call FLO_fnc_virtualizationSpatialIndex;  // Exact-radius WEST groups
 */

params [["_mode", "init", [""]], ["_args", [], [[]]]];

// ============================================================================
// INITIALIZATION
// ============================================================================
if (isNil "FLO_VirtSpatial") then {
    FLO_VirtSpatial = createHashMapFromArray [
        ["cellSize", 500],
        ["grid", createHashMap],        // "cellX_cellY" -> [groupId1, groupId2, ...]
        ["gridBySide", createHashMapFromArray [
            ["EAST", createHashMap],
            ["WEST", createHashMap],
            ["GUER", createHashMap],
            ["CIV", createHashMap],
            ["UNKNOWN", createHashMap]
        ]],
        ["groupMeta", createHashMap],   // groupId -> [cellKey, sideKey]
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

private _getSideKey = {
    params [["_side", nil]];

    if (isNil "_side") exitWith { "" };
    if (_side isEqualType "") exitWith {
        private _sideKey = toUpper _side;
        if !(_sideKey in ["EAST", "WEST", "GUER", "CIV", "UNKNOWN"]) then {
            _sideKey = "UNKNOWN";
        };
        _sideKey;
    };
    if (_side isEqualTo east) exitWith { "EAST" };
    if (_side isEqualTo west) exitWith { "WEST" };
    if (_side isEqualTo resistance) exitWith { "GUER" };
    if (_side isEqualTo civilian) exitWith { "CIV" };
    "UNKNOWN";
};

private _removeFromGrid = {
    params ["_grid", "_cellKey", "_groupId"];

    private _cell = _grid getOrDefault [_cellKey, []];
    _cell = _cell - [_groupId];

    if (count _cell == 0) then {
        _grid deleteAt _cellKey;
    } else {
        _grid set [_cellKey, _cell];
    };
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
        FLO_VirtSpatial set ["gridBySide", createHashMapFromArray [
            ["EAST", createHashMap],
            ["WEST", createHashMap],
            ["GUER", createHashMap],
            ["CIV", createHashMap],
            ["UNKNOWN", createHashMap]
        ]];
        FLO_VirtSpatial set ["groupMeta", createHashMap];
        FLO_VirtSpatial set ["mapSize", worldSize];
        
        ["VIRTUALIZATION", 3, format["Spatial index initialized (cell size: %1m)", _cellSize]] call FLO_fnc_log;
        true
    };

    // Add a group to the index
    case "add": {
        _args params ["_groupId", "_position", ["_side", nil]];
        
        if (isNil "_groupId" || isNil "_position") exitWith { false };
        
        private _cellKey = [_position] call _getCellKey;
        private _grid = FLO_VirtSpatial get "grid";
        private _groupMeta = FLO_VirtSpatial get "groupMeta";
        private _sideKey = [_side] call _getSideKey;
        private _gridBySide = FLO_VirtSpatial get "gridBySide";
        private _sideGrid = _gridBySide getOrDefault [_sideKey, _gridBySide get "UNKNOWN"];
        
        // Add to grid
        private _cell = _grid getOrDefault [_cellKey, []];
        if !(_groupId in _cell) then {
            _cell pushBack _groupId;
            _grid set [_cellKey, _cell];
        };

        private _sideCell = _sideGrid getOrDefault [_cellKey, []];
        if !(_groupId in _sideCell) then {
            _sideCell pushBack _groupId;
            _sideGrid set [_cellKey, _sideCell];
        };
        
        // Track group's cell and side
        _groupMeta set [_groupId, [_cellKey, _sideKey]];
        
        true
    };

    // Remove a group from the index
    case "remove": {
        _args params ["_groupId"];
        
        if (isNil "_groupId") exitWith { false };
        
        private _groupMeta = FLO_VirtSpatial get "groupMeta";
        private _meta = _groupMeta getOrDefault [_groupId, []];
        _meta params [["_cellKey", ""], ["_sideKey", "UNKNOWN"]];
        
        if (_cellKey != "") then {
            private _grid = FLO_VirtSpatial get "grid";
            [_grid, _cellKey, _groupId] call _removeFromGrid;

            private _gridBySide = FLO_VirtSpatial get "gridBySide";
            private _sideGrid = _gridBySide getOrDefault [_sideKey, _gridBySide get "UNKNOWN"];
            [_sideGrid, _cellKey, _groupId] call _removeFromGrid;

            _groupMeta deleteAt _groupId;
        };
        
        true
    };

    // Update a group's position in the index
    case "update": {
        _args params ["_groupId", "_newPosition", ["_side", nil]];
        
        if (isNil "_groupId" || isNil "_newPosition") exitWith { false };
        
        private _groupMeta = FLO_VirtSpatial get "groupMeta";
        private _meta = _groupMeta getOrDefault [_groupId, []];
        _meta params [["_oldCellKey", ""], ["_oldSideKey", "UNKNOWN"]];
        private _newCellKey = [_newPosition] call _getCellKey;
        private _newSideKey = [_side] call _getSideKey;
        
        // Only update if cell or side changed
        if (_oldCellKey != _newCellKey || {_oldSideKey != _newSideKey}) then {
            ["remove", [_groupId]] call FLO_fnc_virtualizationSpatialIndex;
            ["add", [_groupId, _newPosition, _side]] call FLO_fnc_virtualizationSpatialIndex;
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
        _args params ["_position", "_radius", ["_filterSide", nil], ["_exact", false]];
        
        private _cells = [_position, _radius] call _getCellsInRadius;
        private _sideKey = [_filterSide] call _getSideKey;
        private _grid = if (_sideKey == "") then {
            FLO_VirtSpatial get "grid"
        } else {
            (FLO_VirtSpatial get "gridBySide") getOrDefault [_sideKey, createHashMap]
        };
        private _result = [];
        
        {
            private _groupIds = _grid getOrDefault [_x, []];
            _result append _groupIds;
        } forEach _cells;
        
        // Remove duplicates and return
        _result = _result arrayIntersect _result;
        if !(_exact) exitWith { _result };

        private _groups = FLO_virtualGroups get "_groups";
        _result select {
            private _gData = _groups get _x;
            (_gData get "position") distance2D _position <= _radius
        }
    };

    // Rebuild entire index from current groups
    case "rebuild": {
        if (isNil "FLO_virtualGroups") exitWith { false };
        
        FLO_VirtSpatial set ["grid", createHashMap];
        FLO_VirtSpatial set ["gridBySide", createHashMapFromArray [
            ["EAST", createHashMap],
            ["WEST", createHashMap],
            ["GUER", createHashMap],
            ["CIV", createHashMap],
            ["UNKNOWN", createHashMap]
        ]];
        FLO_VirtSpatial set ["groupMeta", createHashMap];
        
        private _groups = FLO_virtualGroups get "_groups";
        {
            private _pos = _y get "position";
            ["add", [_x, _pos, _y get "side"]] call FLO_fnc_virtualizationSpatialIndex;
        } forEach _groups;
        
        ["VIRTUALIZATION", 3, format["Spatial index rebuilt: %1 groups", count keys _groups]] call FLO_fnc_log;
        true
    };

    default { nil };
};

