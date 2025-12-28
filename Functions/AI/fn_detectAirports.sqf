/*
 * Function: FLO_fnc_detectAirports
 * Author: Frontline Operations Development Group
 * Description:
 * Detects airports and helipads on the map by scanning for runway objects,
 * helipads, and location markers. Creates FLO_Airports HashMap for air operations.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Airports HashMap <HASHMAP>
 *
 * Example:
 * call FLO_fnc_detectAirports;
 */

if (!isServer) exitWith { createHashMap };

["AI Airports", 3, "Starting airport detection..."] call FLO_fnc_log;

// Return cached if exists
if (!isNil "FLO_Airports" && {count FLO_Airports > 0}) exitWith { FLO_Airports };

FLO_Airports = createHashMap;

// Object types to search for (common across maps)
private _runwayTypes = [
    "Land_runway_edgelight", "Land_runway_edgelight_blue_F",
    "Land_Runway_PAPI", "Land_Runway_PAPI_2",
    "Land_runway_end", "Land_runway_end_light",
    "Land_TaxiOrange_line_F", "Land_TaxiWhite_line_F"
];

private _helipadTypes = [
    "Land_HelipadCircle_F", "Land_HelipadSquare_F",
    "Land_HelipadRescue_F", "Land_HelipadEmpty_F",
    "Land_HelipadCivil_F", "Land_Heliport_F",
    "HeliH", "HeliHCivil", "HeliHRescue"
];

// Search for runway objects across the map
private _allRunwayObjects = [];
{
    private _objects = nearestObjects [[worldSize/2, worldSize/2, 0], [_x], worldSize];
    _allRunwayObjects append _objects;
} forEach _runwayTypes;

// Search for helipad objects
private _allHelipadObjects = [];
{
    private _objects = nearestObjects [[worldSize/2, worldSize/2, 0], [_x], worldSize];
    _allHelipadObjects append _objects;
} forEach _helipadTypes;

["AI Airports", 3, format["Found %1 runway objects and %2 helipads", count _allRunwayObjects, count _allHelipadObjects]] call FLO_fnc_log;

// Cluster runway objects into airports (within 500m = same airport)
private _runwayClusters = [];
private _processedRunways = [];

{
    private _obj = _x;
    if (_obj in _processedRunways) then { continue };

    private _pos = getPos _obj;
    private _cluster = [_obj];
    _processedRunways pushBack _obj;

    // Find all runway objects within 500m
    {
        if (!(_x in _processedRunways) && {(getPos _x) distance2D _pos < 500}) then {
            _cluster pushBack _x;
            _processedRunways pushBack _x;
        };
    } forEach _allRunwayObjects;

    if (count _cluster >= 3) then { _runwayClusters pushBack _cluster; };
} forEach _allRunwayObjects;

// Create airport entries from runway clusters
private _airportIndex = 0;
{
    private _cluster = _x;
    private _positions = _cluster apply { getPos _x };

    // Calculate center of cluster
    private _centerX = 0; private _centerY = 0;
    { _centerX = _centerX + (_x select 0); _centerY = _centerY + (_x select 1); } forEach _positions;
    _centerX = _centerX / (count _positions);
    _centerY = _centerY / (count _positions);
    private _centerPos = [_centerX, _centerY, 0];

    // Calculate runway heading from object spread
    private _minX = selectMin (_positions apply { _x select 0 });
    private _maxX = selectMax (_positions apply { _x select 0 });
    private _minY = selectMin (_positions apply { _x select 1 });
    private _maxY = selectMax (_positions apply { _x select 1 });
    private _heading = if ((_maxX - _minX) > (_maxY - _minY)) then { 90 } else { 0 };

    // Find nearby helipads
    private _nearbyHelipads = _allHelipadObjects select { (getPos _x) distance2D _centerPos < 800 };

    private _airportData = createHashMapFromArray [
        ["position", _centerPos],
        ["name", format["Airfield_%1", _airportIndex]],
        ["type", if (count _nearbyHelipads > 0) then {"MIXED"} else {"AIRFIELD"}],
        ["runways", [[_centerPos, _heading]]],
        ["helipads", _nearbyHelipads apply { [getPos _x, typeOf _x] }],
        ["capacity", [4, count _nearbyHelipads max 2]],
        ["side", civilian],
        ["assignedAircraft", []]
    ];

    FLO_Airports set [format["airport_%1", _airportIndex], _airportData];
    _airportIndex = _airportIndex + 1;
    ["AI Airports", 3, format["Created airport at %1 with %2 helipads", _centerPos, count _nearbyHelipads]] call FLO_fnc_log;
} forEach _runwayClusters;


// Create heliport entries from standalone helipads (not near airports)
private _standaloneHelipads = _allHelipadObjects select {
    private _pos = getPos _x;
    (values FLO_Airports) findIf { (_x get "position") distance2D _pos < 800 } == -1
};

// Cluster standalone helipads (within 200m = same heliport)
private _helipadClusters = [];
private _processedHelipads = [];

{
    private _obj = _x;
    if (_obj in _processedHelipads) then { continue };
    private _pos = getPos _obj;
    private _cluster = [_obj];
    _processedHelipads pushBack _obj;

    {
        if (!(_x in _processedHelipads) && {(getPos _x) distance2D _pos < 200}) then {
            _cluster pushBack _x;
            _processedHelipads pushBack _x;
        };
    } forEach _standaloneHelipads;
    _helipadClusters pushBack _cluster;
} forEach _standaloneHelipads;

// Create heliport entries
{
    private _cluster = _x;
    private _positions = _cluster apply { getPos _x };

    private _centerX = 0; private _centerY = 0;
    { _centerX = _centerX + (_x select 0); _centerY = _centerY + (_x select 1); } forEach _positions;
    _centerX = _centerX / (count _positions);
    _centerY = _centerY / (count _positions);
    private _centerPos = [_centerX, _centerY, 0];

    private _heliportData = createHashMapFromArray [
        ["position", _centerPos],
        ["name", format["Heliport_%1", _airportIndex]],
        ["type", "HELIPORT"],
        ["runways", []],
        ["helipads", _cluster apply { [getPos _x, typeOf _x] }],
        ["capacity", [0, count _cluster max 1]],
        ["side", civilian],
        ["assignedAircraft", []]
    ];

    FLO_Airports set [format["heliport_%1", _airportIndex], _heliportData];
    _airportIndex = _airportIndex + 1;
    ["AI Airports", 4, format["Created heliport at %1 with %2 pads", _centerPos, count _cluster]] call FLO_fnc_log;
} forEach _helipadClusters;

// Also check map locations for named airports
private _mapLocations = nearestLocations [[worldSize/2, worldSize/2], ["Airport", "NameMarine"], worldSize];
{
    private _locPos = locationPosition _x;
    private _locName = text _x;

    // Check if we already have an airport near this location
    private _existingIdx = (values FLO_Airports) findIf { (_x get "position") distance2D _locPos < 1000 };

    if (_existingIdx != -1) then {
        // Update existing airport with proper name
        private _keys = keys FLO_Airports;
        private _key = _keys select _existingIdx;
        (FLO_Airports get _key) set ["name", _locName];
        ["AI Airports", 3, format["Updated airport %1 with name: %2", _key, _locName]] call FLO_fnc_log;
    } else {
        // Create new airport entry from location
        private _airportData = createHashMapFromArray [
            ["position", _locPos],
            ["name", _locName],
            ["type", "AIRFIELD"],
            ["runways", [[_locPos, 0]]],
            ["helipads", []],
            ["capacity", [2, 2]],
            ["side", civilian],
            ["assignedAircraft", []]
        ];

        FLO_Airports set [format["loc_airport_%1", _airportIndex], _airportData];
        _airportIndex = _airportIndex + 1;
        ["AI Airports", 3, format["Created airport from location: %1 at %2", _locName, _locPos]] call FLO_fnc_log;
    };
} forEach _mapLocations;

["AI Airports", 2, format["Airport detection complete: %1 airports/heliports found", count FLO_Airports]] call FLO_fnc_log;

// Broadcast to clients
publicVariable "FLO_Airports";

FLO_Airports