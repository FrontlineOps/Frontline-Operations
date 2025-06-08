/*
 * Function: FLO_fnc_indexObjectives
 * Author: Frontline Operations Development Group
 * Description:
 * Indexes all map objectives (military, civilian, industrial, etc.) into a global HashMap for virtualization and circular growth.
 * Uses dynamic radius and structure count to determine objective size and priority.
 * Power line structures (PowerLines_base_F) are ignored when scanning.
 * Arguments: None
 * Returns: HashMap of all objectives (FLO_Objectives)
 * Example: [] call FLO_fnc_indexObjectives;
 */

// Define location types and their classification
private _locationTypes = [
    // Civilian
    ["NameCityCapital", "civilian", "capital"],
    ["NameCity", "civilian", "city"],
    ["NameVillage", "civilian", "village"],
    ["NameLocal", "civilian", "local"],
    // Military/Strategic
    ["NameMarine", "military", "marine"]
    // Terrain/Other (optional, for diversity)
    // ["NameHill", "terrain", "hill", 30],
    // ["NameMountain", "terrain", "mountain", 35],
    // ["NameForest", "terrain", "forest", 20],
    // ["NameValley", "terrain", "valley", 15],
    // ["NameRiver", "terrain", "river", 10],
    // ["NameLake", "terrain", "lake", 10]
];

private _baseClasses = [
    "HeliH", "AirportBase", "Strategic", "House_F",
    "House_Small", "House", "HouseBase", "Church"
];

private _center = [worldSize/2, worldSize/2, 0];
private _allLocations = [];
private _typeMap = createHashMap;

for "_i" from 0 to (count _locationTypes - 1) do {
    private _typeArr = _locationTypes select _i;
    private _locType = _typeArr select 0;
    private _cat = _typeArr select 1;
    private _subtype = _typeArr select 2;
    private _found = nearestLocations [_center, [_locType], worldSize];
    {
        if !(_x in _allLocations) then {
            _allLocations pushBack _x;
            _typeMap set [str _x, [_cat, _subtype, _locType]];
        };
    } forEach _found;
};

private _allObjectives = createHashMap;

for "_i" from 0 to (count _allLocations - 1) do {
    private _loc = _allLocations select _i;
    private _pos = locationPosition _loc;
    private _locStr = str _loc;
    private _cat = "unknown";
    private _subtype = "unknown";
    private _locType = "unknown";
    
    private _arr = _typeMap get _locStr;
    if (!isNil "_arr") then {
        _cat = _arr select 0;
        _subtype = _arr select 1;
        _locType = _arr select 2;
    };

    // --- Dynamic radius/structure scan ---
    private _minRadius = 90; // Always grow to at least this
    private _maxRadius = 300;
    private _step = 30;
    private _minGrowth = 2;
    private _radius = _step;
    private _allFound = [];
    private _lastCount = 0;
    while {_radius <= _maxRadius} do {
        private _found = nearestObjects [_pos, _baseClasses, _radius];
        _found = _found select { !(_x isKindOf "PowerLines_base_F") };
        if ((_radius >= _minRadius) && ((count _found) - _lastCount < _minGrowth) && (count _found > 0)) exitWith {};
        _allFound = _found;
        _lastCount = count _found;
        _radius = _radius + _step;
    };
    // If nothing found, fallback to a minimum radius
    if (_radius < _minRadius) then { _radius = _minRadius; };
    // Now check if we found any buildings/structures
    if (count _allFound == 0) then { continue; };
    // Priority: scale structure count to 1-100, factor in radius
    private _structCount = count _allFound;
    private _priority = (_structCount * 2) min 100 max 1; // Simple scaling, tweak as needed
    // Store all structure positions for debug
    private _structurePositions = [];
    { _structurePositions pushBack (getPosWorld _x); } forEach _allFound;

    private _objData = createHashMapFromArray [
        ["type", _cat],
        ["subtype", _subtype],
        ["position", _pos],
        ["priority", _priority],
        ["radius", _radius],
        ["structures", _allFound],
        ["structurePositions", _structurePositions],
        ["location", _loc],
        ["locType", _locType],
        ["owner", east]
    ];
    _allObjectives set [_locStr, _objData];
};

// Link objectives by proximity (within 5km)
private _keys = keys _allObjectives;
for "_i" from 0 to (count _keys - 1) do {
    private _id = _keys select _i;
    private _data = _allObjectives get _id;
    private _pos = _data get "position";
    private _links = [];
    for "_j" from 0 to (count _keys - 1) do {
        private _otherId = _keys select _j;
        if (_otherId != _id) then {
            private _other = _allObjectives get _otherId;
            if ((_other get "position") distance2D _pos < 5000) then {
                _links pushBack _otherId;
            };
        };
    };
    _data set ["linkedObjectives", _links];
};

// Store globally
FLO_Objectives = _allObjectives;
publicVariable "FLO_Objectives";

// Add virtual objectives for uncovered clusters (docks, industrial, etc.)
[FLO_Objectives, FLO_Objectives_Debug, 100] call FLO_fnc_indexVirtualObjectives;

// Create map markers for all objectives (including newly added virtual ones)
_keys = keys FLO_Objectives;
{
    private _id = _x;
    private _data = FLO_Objectives get _id;
    private _pos = _data get "position";
    private _radius = _data get "radius";
    private _owner = _data getOrDefault ["owner", east];
    private _marker = createMarker [format ["obj_%1", _id], _pos];
    _marker setMarkerShape "ELLIPSE";
    _marker setMarkerSize [_radius, _radius];
    private _color = switch (_owner) do {
        case west: {"colorBLUFOR"};
        case east: {"colorOPFOR"};
        case resistance: {"ColorGUER"};
        default {"ColorBlack"};
    };
    _marker setMarkerColor _color;
    _marker setMarkerAlpha 0.3;
} forEach _keys;

if (FLO_Objectives_Debug) then {
    for "_i" from 0 to (count _keys - 1) do {
        private _id = _keys select _i;
        private _data = _allObjectives get _id;
        private _pos = _data get "position";
        private _radius = _data get "radius";
        private _priority = _data get "priority";
        private _structurePositions = _data get "structurePositions";
        private _marker = createMarkerLocal [format["obj_%1", _id], _pos];
        _marker setMarkerShapeLocal "ELLIPSE";
        _marker setMarkerSizeLocal [_radius, _radius];
        _marker setMarkerColorLocal "ColorRed";
        _marker setMarkerAlphaLocal 0.3;
        _marker setMarkerTextLocal format["P:%1", _priority];
        // Mark each structure
        {
            private _sMarker = createMarkerLocal [format["obj_%1_struct_%2", _id, _forEachIndex], _x];
            _sMarker setMarkerTypeLocal "mil_dot";
            _sMarker setMarkerColorLocal "ColorBlack";
            _sMarker setMarkerAlphaLocal 0.7;
        } forEach _structurePositions;
    };
};

_allObjectives;