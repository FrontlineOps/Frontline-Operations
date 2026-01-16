/*
 * Function: FLO_fnc_createVirtualCivilianPopulation
 * Author: Frontline Operations Development Group
 * Description:
 *   Populates cities/villages with realistic civilian activity.
 *   - Pedestrians walk along roads and between buildings
 *   - Some stand/idle at realistic locations
 *   - Cars drive on road network between locations
 *   - Building occupants placed inside structures
 *   - Density scales by location type (capital > city > village)
 *
 * Arguments: None
 * Returns: Number of civilians placed
 */

// Configuration - density multipliers by location type
private _densityConfig = createHashMapFromArray [
    ["NameCityCapital", [8, 12, 4, 6]],  // [minPedestrians, maxPedestrians, minCars, maxCars]
    ["NameCity", [4, 8, 2, 4]],
    ["NameVillage", [1, 3, 0, 2]]
];

// Gather all populated locations
private _civLocationTypes = ["NameCity", "NameCityCapital", "NameVillage"];
private _allLocations = [];
{
    private _type = _x;
    private _locs = nearestLocations [[worldSize/2, worldSize/2, 0], [_type], worldSize];
    { _allLocations pushBack [_x, _type]; } forEach _locs;
} forEach _civLocationTypes;

private _totalCivsPlaced = 0;

// Helper: Get road waypoints within a location for pedestrian walking
private _fnc_getRoadWaypoints = {
    params ["_centerPos", "_radius", "_count"];
    private _roads = _centerPos nearRoads _radius;
    private _waypoints = [];

    if (count _roads < 2) exitWith { _waypoints };

    // Select random road points as waypoints
    private _shuffled = _roads call BIS_fnc_arrayShuffle;
    private _selected = _shuffled select [0, _count min count _shuffled];

    {
        private _roadPos = getPos _x;
        // Offset slightly to sidewalk (2-3m from road center)
        private _connected = roadsConnectedTo _x;
        private _dir = if (count _connected > 0) then { _x getDir (_connected select 0) } else { random 360 };
        private _sidewalkOffset = 2 + random 1;
        private _sideDir = _dir + (selectRandom [90, -90]);
        private _wpPos = [
            (_roadPos select 0) + (sin _sideDir) * _sidewalkOffset,
            (_roadPos select 1) + (cos _sideDir) * _sidewalkOffset,
            0
        ];
        _waypoints pushBack [_wpPos, "MOVE", "CARELESS", "LIMITED", "FILE", "WHITE", 3];
    } forEach _selected;

    // Add CYCLE to loop
    if (count _waypoints > 0) then {
        _waypoints pushBack [_waypoints select 0 select 0, "CYCLE", "CARELESS", "LIMITED", "FILE", "WHITE", 3];
    };

    _waypoints
};

// Process each location
{
    _x params ["_loc", "_locType"];
    private _pos = locationPosition _loc;
    private _locSize = size _loc;
    private _radius = ((_locSize select 0) max (_locSize select 1)) max 100;

    // Get density config for this location type
    private _config = _densityConfig getOrDefault [_locType, [2, 4, 1, 2]];
    _config params ["_minPeds", "_maxPeds", "_minCars", "_maxCars"];

    // Calculate actual counts
    private _numPedestrians = _minPeds + floor random (_maxPeds - _minPeds + 1);
    private _numCars = _minCars + floor random (_maxCars - _minCars + 1);

    // =========================================================================
    // PEDESTRIANS - Walking along roads/sidewalks
    // =========================================================================
    for "_i" from 1 to _numPedestrians do {
        // Find a starting position on/near a road
        private _roads = _pos nearRoads _radius;
        if (count _roads == 0) then { continue };

        private _startRoad = selectRandom _roads;
        private _startPos = getPos _startRoad;

        // Create the civilian group
        private _groupId = [_startPos, "civilian", nil, "civ_pedestrian", 1, civilian] call FLO_fnc_createVirtualGroup;

        // Generate road-following waypoints
        private _waypoints = [_pos, _radius, 4 + floor random 4] call _fnc_getRoadWaypoints;

        if (count _waypoints > 0) then {
            [_groupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
        };

        _totalCivsPlaced = _totalCivsPlaced + 1;
    };
    // =========================================================================
    // CIVILIAN VEHICLES - Parked or driving on roads
    // =========================================================================
    for "_i" from 1 to _numCars do {
        if (isNil "CivVehArray" || {count CivVehArray == 0}) then { continue };

        // Find a road to start from
        private _roads = _pos nearRoads _radius;
        if (count _roads == 0) then { continue };

        private _startRoad = selectRandom _roads;
        private _parkingData = [getPos _startRoad, _radius, 4] call FLO_fnc_getRoadParkingPos;
        _parkingData params ["_parkPos", "_parkDir"];

        private _carGroupId = [_parkPos, "civilianVehicle", nil, "civ_car", 1, civilian] call FLO_fnc_createVirtualGroup;

        // Store parking direction
        private _groupData = (FLO_virtualGroups get "_groups") get _carGroupId;
        _groupData set ["direction", _parkDir];

        // 40% parked, 60% driving
        if (random 1 < 0.4) then {
            // Parked - no waypoints needed
        } else {
            // Driving - find another location to drive to
            private _nearbyLocs = nearestLocations [_pos, _civLocationTypes, 3000];
            _nearbyLocs = _nearbyLocs select { locationPosition _x distance2D _pos > 500 };

            if (count _nearbyLocs > 0) then {
                private _destLoc = selectRandom _nearbyLocs;
                private _destPos = locationPosition _destLoc;

                // Find road near destination
                private _destRoads = _destPos nearRoads 200;
                if (count _destRoads > 0) then {
                    private _destRoadPos = getPos (selectRandom _destRoads);

                    // Create waypoints: start -> destination -> back to start (loop)
                    private _carWaypoints = [
                        [_destRoadPos, "MOVE", "CARELESS", "LIMITED", "COLUMN", "WHITE", 20],
                        [_parkPos, "MOVE", "CARELESS", "LIMITED", "COLUMN", "WHITE", 20],
                        [_destRoadPos, "CYCLE", "CARELESS", "LIMITED", "COLUMN", "WHITE", 20]
                    ];

                    [_carGroupId, _carWaypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                };
            };
        };
    };
    // =========================================================================
    // BUILDING OCCUPANTS - Civilians inside buildings
    // =========================================================================
    if (isNil "CivBuildingClasses" || isNil "CiviliansPerLocationMin") then { continue };

    // Scale building civilian count by location type
    private _buildingMultiplier = switch (_locType) do {
        case "NameCityCapital": { 1.5 };
        case "NameCity": { 1.0 };
        case "NameVillage": { 0.5 };
        default { 1.0 };
    };

    private _baseCivCount = CiviliansPerLocationMin + floor random (CiviliansPerLocationMax - CiviliansPerLocationMin + 1);
    private _civCount = floor (_baseCivCount * _buildingMultiplier);

    // Find buildings within the location
    private _buildings = [];
    { _buildings append (nearestObjects [_pos, [_x], _radius]); } forEach CivBuildingClasses;

    if (count _buildings == 0) then { continue };

    // Gather all valid building positions
    private _buildingPositions = [];
    {
        private _bldg = _x;
        private _i = 0;
        while { true } do {
            private _bldgPos = _bldg buildingPos _i;
            if (_bldgPos isEqualTo [0,0,0]) exitWith {};
            _buildingPositions pushBack _bldgPos;
            _i = _i + 1;
        };
    } forEach _buildings;

    if (count _buildingPositions == 0) then { continue };

    // Shuffle and place civilians
    _buildingPositions = _buildingPositions call BIS_fnc_arrayShuffle;

    private _placed = 0;
    {
        if (_placed >= _civCount) exitWith {};
        if (isNil "CivMenArray" || {count CivMenArray == 0}) exitWith {};

        private _unitType = selectRandom CivMenArray;
        private _bldgPos = _x;

        // Create civilian at building position (stationary)
        private _groupId = [_bldgPos, "civilian", nil, "civ_building", 1, civilian, _unitType] call FLO_fnc_createVirtualGroup;

        // Set as stationary (no waypoints = stays in place)
        private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
        _groupData set ["state", "idle"];
        _groupData set ["autoPatrol", true];

        _placed = _placed + 1;
        _totalCivsPlaced = _totalCivsPlaced + 1;
    } forEach _buildingPositions;

} forEach _allLocations;

// Log summary
["VIRTUALIZATION", 2, format["Created %1 virtual civilians across %2 locations", _totalCivsPlaced, count _allLocations]] call FLO_fnc_log;

_totalCivsPlaced