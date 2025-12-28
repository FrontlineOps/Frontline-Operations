/*
 * Function: FLO_fnc_createVirtualCivilianPopulation
 * Description: Populates all city/village locations with civilian groups, cars, and building occupants using cluster expansion.
 * Arguments: None
 * Returns: Number of civilians placed (optional)
 */

private _civLocationTypes = ["NameCity", "NameCityCapital", "NameVillage"];
private _allLocations = [];
{
    _allLocations append (nearestLocations [[worldSize/2, worldSize/2, 0], [_x], worldSize]);
} forEach _civLocationTypes;
private _totalCivsPlaced = 0;
{
    private _loc = _x;
    private _pos = locationPosition _loc;
    // Create a civilian group at this location (patrolling/outdoors)
    private _groupId = [_pos, "civilian", nil, "civ_location", -1, civilian] call FLO_fnc_createVirtualGroup;
    // Assign patrol or stationary waypoints
    private _pattern = selectRandom ["circle", "square", "stationary"];
    private _size = 50 + random 100; // 50-150m area
    private _waypoints = [];
    switch (_pattern) do {
        case "circle": {
            for "_i" from 0 to 5 do {
                private _angle = _i * 60;
                private _rawPos = [(_pos select 0) + (sin _angle * _size), (_pos select 1) + (cos _angle * _size), 0];
                private _wpPos = [_rawPos, _size] call FLO_fnc_getSafeLandPos;
                _waypoints pushBack [_wpPos, "MOVE", "SAFE", "LIMITED", "COLUMN", "YELLOW", 5];
            };
        };
        case "square": {
            private _p1 = [[(_pos select 0) + _size, (_pos select 1) + _size, 0], _size] call FLO_fnc_getSafeLandPos;
            private _p2 = [[(_pos select 0) - _size, (_pos select 1) + _size, 0], _size] call FLO_fnc_getSafeLandPos;
            private _p3 = [[(_pos select 0) - _size, (_pos select 1) - _size, 0], _size] call FLO_fnc_getSafeLandPos;
            private _p4 = [[(_pos select 0) + _size, (_pos select 1) - _size, 0], _size] call FLO_fnc_getSafeLandPos;
            _waypoints = [
                [_p1, "MOVE", "SAFE", "LIMITED", "COLUMN", "YELLOW", 5],
                [_p2, "MOVE", "SAFE", "LIMITED", "COLUMN", "YELLOW", 5],
                [_p3, "MOVE", "SAFE", "LIMITED", "COLUMN", "YELLOW", 5],
                [_p4, "MOVE", "SAFE", "LIMITED", "COLUMN", "YELLOW", 5]
            ];
        };
        case "stationary": {
            _waypoints = [[[_pos select 0, _pos select 1, 0], "SENTRY", "SAFE", "LIMITED", "COLUMN", "YELLOW", 5]];
        };
    };
    [_groupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
    // Spawn civilian cars (parked and patrolling)
    private _numCars = 1 + floor random 3; // 1-3 cars per location
    for "_i" from 1 to _numCars do {
        private _carType = selectRandom CivVehArray;
        // Try to place parked cars on roads
        private _carPos = [(_pos select 0) + (random 40 - 20), (_pos select 1) + (random 40 - 20), 0];
        private _carGroupId = [_carPos, "civilianVehicle", nil, "civ_car", 1, civilian] call FLO_fnc_createVirtualGroup;
        // 50% parked, 50% simple patrol
        if (random 1 < 0.5) then {
            // Parked: place on road if possible, no waypoints
            private _roads = _carPos nearRoads 300;
            if (count _roads > 0) then {
                private _road = selectRandom _roads;
                private _roadPos = getPos _road;
                private _connected = roadsConnectedTo _road;
                private _roadDir = if (count _connected > 0) then {
                    _road getDir (_connected select 0)
                } else {
                    random 360
                };
                private _offset = 3 + random 1; // 3-4 meters
                private _sideSign = if (random 1 < 0.5) then {1} else {-1};
                private _sideDir = _roadDir + (90 * _sideSign);
                private _sidePos = [
                    (_roadPos select 0) + (sin _sideDir) * _offset,
                    (_roadPos select 1) + (cos _sideDir) * _offset,
                    _roadPos select 2
                ];
                private _groupData = (FLO_virtualGroups get "_groups") get _carGroupId;
                if (!isNil "_groupData") then {
                    _groupData set ["position", _sidePos];
                };
            };
        } else {
            // Simple patrol - ensure waypoints are on roads or at least on land
            private _carPatrol = [];
            for "_j" from 0 to 2 do {
                private _angle = random 360;
                private _dist = 1000 + random 200; // 1000-1200m from car position
                private _rawPos = [(_carPos select 0) + (sin _angle * _dist), (_carPos select 1) + (cos _angle * _dist), 0];

                // Try to find a road position, otherwise use safe land position
                private _roads = _rawPos nearRoads 200;
                private _wp = if (count _roads > 0) then {
                    getPos (selectRandom _roads)
                } else {
                    [_rawPos, 300] call FLO_fnc_getSafeLandPos
                };

                _carPatrol pushBack [_wp, "MOVE", "SAFE", "LIMITED", "COLUMN", "YELLOW", 3];
            };
            [_carGroupId, _carPatrol] call FLO_fnc_updateVirtualGroupWaypoints;
        };
    };
    // --- Place additional civilians in buildings (with cluster expansion) ---
    private _civCount = CiviliansPerLocationMin + floor random (CiviliansPerLocationMax - CiviliansPerLocationMin + 1);
    // Initial buildings near the location
    private _initialBuildings = [];
    {
        _initialBuildings append (nearestObjects [_pos, [_x], 200]);
    } forEach CivBuildingClasses;
    private _allBuildings = +_initialBuildings;
    private _checkedBuildings = [];
    private _expansionRadius = 100;
    private _maxBuildings = 200;
    private _maxIterations = 8;
    private _iteration = 0;
    while {count _allBuildings < _maxBuildings && _iteration < _maxIterations} do {
        private _newBuildings = [];
        {
            if (!(_x in _checkedBuildings)) then {
                private _nearby = nearestObjects [_x, CivBuildingClasses, _expansionRadius];
                {
                    if (!(_x in _allBuildings)) then {_newBuildings pushBack _x};
                } forEach _nearby;
                _checkedBuildings pushBack _x;
            };
        } forEach _allBuildings;
        if (_newBuildings isEqualTo []) exitWith {};
        _allBuildings append _newBuildings;
        _iteration = _iteration + 1;
    };
    // Gather building positions
    private _buildingPositions = [];
    {
        private _bldg = _x;
        private _bldgPositions = [];
        private _i = 0;
        while {true} do {
            private _bldgPos = _bldg buildingPos _i;
            if (_bldgPos isEqualTo [0,0,0]) exitWith {};
            _bldgPositions pushBack _bldgPos;
            _i = _i + 1;
        };
        _buildingPositions append _bldgPositions;
    } forEach _allBuildings;
    _buildingPositions = _buildingPositions call BIS_fnc_arrayShuffle;
    private _placed = 0;
    {
        if (_placed >= _civCount) exitWith {};
        private _unitType = selectRandom CivMenArray;
        private _pos = _x;
        // Place a single civilian at this building position
        [_pos, "civilian", 1, "civ_building", -1, civilian, _unitType] call FLO_fnc_createVirtualGroup;
        _placed = _placed + 1;
        _totalCivsPlaced = _totalCivsPlaced + 1;
    } forEach _buildingPositions;
} forEach _allLocations;
_totalCivsPlaced; 