/*
 * Function: FLO_fnc_indexObjectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Indexes all map objectives (military, civilian, industrial, etc.) into
 *   a global HashMap for virtualization and circular growth.
 *   Uses dynamic radius and structure count to determine objective size and priority.
 *
 * Arguments: None
 * Returns: HashMap of all objectives (FLO_Objectives)
 * Example: [] call FLO_fnc_indexObjectives;
 */

// Initialize configuration
["init"] call FLO_fnc_objectiveConfig;

// Get configuration values
private _locationTypes = ["get", "locationTypes"] call FLO_fnc_objectiveConfig;
private _baseClasses = ["get", "baseClasses"] call FLO_fnc_objectiveConfig;
private _excludeClasses = ["get", "excludeClasses"] call FLO_fnc_objectiveConfig;
private _minRadius = ["get", "minRadius"] call FLO_fnc_objectiveConfig;
private _maxRadius = ["get", "maxRadius"] call FLO_fnc_objectiveConfig;
private _radiusStep = ["get", "radiusStep"] call FLO_fnc_objectiveConfig;
private _minGrowth = ["get", "minGrowth"] call FLO_fnc_objectiveConfig;
private _linkDistance = ["get", "linkDistance"] call FLO_fnc_objectiveConfig;

private _center = [worldSize/2, worldSize/2, 0];
private _allLocations = [];
private _typeMap = createHashMap;

// Gather all map locations by type
{
    _x params ["_locType", "_cat", "_subtype"];
    private _found = nearestLocations [_center, [_locType], worldSize];
    {
        private _locStr = str _x;
        if !(_locStr in keys _typeMap) then {
            _allLocations pushBack _x;
            _typeMap set [_locStr, [_cat, _subtype, _locType]];
        };
    } forEach _found;
} forEach _locationTypes;

private _allObjectives = createHashMap;

// Process each location
{
    private _loc = _x;
    private _pos = locationPosition _loc;
    private _locStr = str _loc;

    // Get type info from map
    private _typeInfo = _typeMap getOrDefault [_locStr, ["unknown", "unknown", "unknown"]];
    _typeInfo params ["_cat", "_subtype", "_locType"];

    // Dynamic radius/structure scan
    private _radius = _radiusStep;
    private _allFound = [];
    private _lastCount = 0;

    while {_radius <= _maxRadius} do {
        private _found = nearestObjects [_pos, _baseClasses, _radius];
        // Filter excluded classes
        _found = _found select {
            private _obj = _x;
            !({ _obj isKindOf _x } count _excludeClasses > 0)
        };

        // Stop growing if minimal growth and we've reached minimum radius
        if (_radius >= _minRadius && {(count _found) - _lastCount < _minGrowth} && {count _found > 0}) exitWith {};

        _allFound = _found;
        _lastCount = count _found;
        _radius = _radius + _radiusStep;
    };

    // Ensure minimum radius
    if (_radius < _minRadius) then { _radius = _minRadius };

    // Skip locations with no structures
    if (count _allFound == 0) then { continue };

    // Calculate priority (1-100 based on structure count)
    private _structCount = count _allFound;
    private _priority = (_structCount * 2) min 100 max 1;

    // Collect structure positions
    private _structurePositions = _allFound apply { getPosWorld _x };

    // Create objective data
    private _objData = createHashMapFromArray [
        ["type", _cat],
        ["subtype", _subtype],
        ["position", _pos],
        ["priority", _priority],
        ["radius", _radius],
        ["structures", _allFound],
        ["structurePositions", _structurePositions],
        ["location", _locStr],
        ["locType", _locType],
        ["owner", east],
        ["polygon", []],        // For future polygon support
        ["usePolygon", false],  // Whether to use polygon for containment checks
        ["markerIds", []]       // Track created markers
    ];

    _allObjectives set [_locStr, _objData];
} forEach _allLocations;

// Link objectives by proximity
private _keys = keys _allObjectives;
{
    private _id = _x;
    private _data = _allObjectives get _id;
    private _pos = _data get "position";

    // Find all objectives within link distance
    private _links = _keys select {
        _x != _id && {
            ((_allObjectives get _x) get "position") distance2D _pos < _linkDistance
        }
    };

    _data set ["linkedObjectives", _links];
} forEach _keys;

// Store globally
FLO_Objectives = _allObjectives;
publicVariable "FLO_Objectives";

// Add virtual objectives for uncovered clusters
private _gridSize = ["get", "gridSize"] call FLO_fnc_objectiveConfig;
private _debug = ["get", "debug"] call FLO_fnc_objectiveConfig;
[FLO_Objectives, _debug, _gridSize] call FLO_fnc_indexVirtualObjectives;

// Create markers for all objectives using centralized function
{
    [_x] call FLO_fnc_createObjectiveMarker;
} forEach (keys FLO_Objectives);

// Debug markers if enabled
if (_debug || {!isNil "FLO_Objectives_Debug" && {FLO_Objectives_Debug}}) then {
    {
        private _id = _x;
        private _data = FLO_Objectives get _id;
        if (isNil "_data") then { continue };

        private _priority = _data getOrDefault ["priority", 0];
        private _structurePositions = _data getOrDefault ["structurePositions", []];

        // Add priority text to marker
        private _markerName = format ["obj_%1", _id];
        _markerName setMarkerText format ["P:%1", _priority];

        // Mark each structure
        {
            private _sMarker = createMarkerLocal [format ["obj_%1_struct_%2", _id, _forEachIndex], _x];
            _sMarker setMarkerTypeLocal "mil_dot";
            _sMarker setMarkerColorLocal "ColorBlack";
            _sMarker setMarkerAlphaLocal 0.7;
        } forEach _structurePositions;
    } forEach (keys FLO_Objectives);
};

_allObjectives