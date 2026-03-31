/*
 * Function: FLO_fnc_spawnCivilians
 * Author: Frontline Operations Development Group
 * Description:
 *   Seeds a civilian population with role-based ambient routes and local
 *   objective ownership metadata so settlements look inhabited rather than
 *   randomly populated.
 *
 * Return Value:
 * NUMBER - Number of civilian virtual groups created
 */

if (isNil "FLO_CivilianConfig") then {
    if (isNil "FLO_fnc_civilianConfig") exitWith { 0 };
    [] call FLO_fnc_civilianConfig;
};

private _densityConfig = FLO_CivilianConfig get "DENSITY";
private _locationTypes = FLO_CivilianConfig get "CIV_LOCATION_TYPES";
private _roleCounts = createHashMap;
private _allLocations = [];

{
    {
        _allLocations pushBack [_x, _y];
    } forEach (nearestLocations [[worldSize * 0.5, worldSize * 0.5, 0], [_y], worldSize]);
} forEach _locationTypes;

private _createdCount = 0;
private _groups = FLO_virtualGroups get "_groups";

{
    _x params ["_location", "_locationType"];

    private _locationPos = locationPosition _location;
    private _objectiveId = [_locationPos] call FLO_fnc_civilianResolveObjective;
    if (_objectiveId == "") then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    private _objectiveRadius = (_objective get "radius") max 90;
    private _density = _densityConfig get _locationType;
    if (isNil "_density") then { continue };
    _density params ["_minPedestrians", "_maxPedestrians", "_minCars", "_maxCars"];

    private _pedestrianCount = _minPedestrians + floor random ((_maxPedestrians - _minPedestrians) + 1);
    private _carCount = _minCars + floor random ((_maxCars - _minCars) + 1);

    for "_i" from 1 to _pedestrianCount do {
        private _spawnPos = [_objectiveId, true] call FLO_fnc_getRandomObjectivePos;
        if (_spawnPos isEqualTo [0, 0, 0]) then {
            _spawnPos = +(_objective get "position");
            _spawnPos set [2, 0];
        };

        private _profile = [_objectiveId, _locationType, "civilian", _spawnPos] call FLO_fnc_civilianBuildRoleProfile;
        private _route = [_objectiveId, _profile get "role", _spawnPos] call FLO_fnc_civilianBuildAmbientRoute;
        private _groupId = [_spawnPos, "civilian", nil, _objectiveId, 1, civilian] call FLO_fnc_createVirtualGroup;
        if (_groupId == "") then { continue };

        private _groupData = _groups get _groupId;
        _groupData set ["civilianRole", _profile get "role"];
        _groupData set ["civilianObjective", _objectiveId];
        _groupData set ["civilianAnchorPos", _profile get "anchorPos"];
        _groupData set ["civilianRouteAnchors", _route get "anchors"];
        _groupData set ["civilianKnowledgeBias", _profile get "knowledgeBias"];
        _groupData set ["civilianTrustBias", _profile get "trustBias"];
        _groupData set ["civilianRoutineState", _profile get "routineState"];

        private _waypoints = _route get "waypoints";
        if ((count _waypoints) > 0) then {
            [_groupId, _waypoints, false, true, "CIV_AMBIENT"] call FLO_fnc_updateVirtualGroupWaypoints;
        } else {
            _groupData set ["noWaypoints", true];
        };

        private _role = _profile get "role";
        _roleCounts set [_role, (_roleCounts getOrDefault [_role, 0]) + 1];
        _createdCount = _createdCount + 1;
    };

    for "_i" from 1 to _carCount do {
        if (isNil "CivVehArray" || {count CivVehArray == 0}) then { continue };

        private _parkingData = [(_objective get "position"), _objectiveRadius, 4] call FLO_fnc_getRoadParkingPos;
        _parkingData params ["_parkPos", "_parkDir"];

        private _groupId = [_parkPos, "civilianVehicle", nil, _objectiveId, 1, civilian] call FLO_fnc_createVirtualGroup;
        if (_groupId == "") then { continue };

        private _groupData = _groups get _groupId;
        private _profile = [_objectiveId, _locationType, "civilianVehicle", _parkPos] call FLO_fnc_civilianBuildRoleProfile;
        _groupData set ["direction", _parkDir];
        _groupData set ["civilianRole", _profile get "role"];
        _groupData set ["civilianObjective", _objectiveId];
        _groupData set ["civilianAnchorPos", _parkPos];
        _groupData set ["civilianRouteAnchors", [_parkPos]];
        _groupData set ["civilianKnowledgeBias", _profile get "knowledgeBias"];
        _groupData set ["civilianTrustBias", _profile get "trustBias"];
        _groupData set ["civilianRoutineState", _profile get "routineState"];

        private _nearbyLocations = nearestLocations [_locationPos, _locationTypes, 3000];
        _nearbyLocations = _nearbyLocations select { locationPosition _x distance2D _locationPos > 500 };

        if ((count _nearbyLocations) > 0) then {
            private _destinationLocation = selectRandom _nearbyLocations;
            private _destinationObjectiveId = [locationPosition _destinationLocation] call FLO_fnc_civilianResolveObjective;
            private _destinationPos = if (_destinationObjectiveId != "") then {
                [_destinationObjectiveId, true] call FLO_fnc_getRandomObjectivePos
            } else {
                locationPosition _destinationLocation
            };
            if (_destinationPos isEqualTo [0, 0, 0]) then {
                _destinationPos = locationPosition _destinationLocation;
            };

            private _vehicleWaypoints = [
                [_destinationPos, "MOVE", "SAFE", "LIMITED", "COLUMN", "WHITE", 20],
                [_parkPos, "MOVE", "SAFE", "LIMITED", "COLUMN", "WHITE", 20],
                [_destinationPos, "CYCLE", "SAFE", "LIMITED", "COLUMN", "WHITE", 20]
            ];

            _groupData set ["civilianRouteAnchors", [_parkPos, _destinationPos]];
            [_groupId, _vehicleWaypoints, false, true, "CIV_TRAFFIC"] call FLO_fnc_updateVirtualGroupWaypoints;
        };

        _roleCounts set ["driver", (_roleCounts getOrDefault ["driver", 0]) + 1];
        _createdCount = _createdCount + 1;
    };

    if (isNil "CivBuildingClasses" || {isNil "CiviliansPerLocationMin"} || {isNil "CiviliansPerLocationMax"}) then {
        continue;
    };

    private _buildingMultiplierMap = FLO_CivilianConfig get "BUILDING_MULTIPLIER";
    private _buildingMultiplier = _buildingMultiplierMap get _locationType;
    if (isNil "_buildingMultiplier") then {
        _buildingMultiplier = 1;
    };

    private _buildingCount = floor ((CiviliansPerLocationMin + floor random ((CiviliansPerLocationMax - CiviliansPerLocationMin) + 1)) * _buildingMultiplier);
    if (_buildingCount <= 0) then { continue };

    private _buildings = [];
    { _buildings append (nearestObjects [_locationPos, [_x], _objectiveRadius]); } forEach CivBuildingClasses;
    if ((count _buildings) == 0) then { continue };

    private _buildingPositions = [];
    {
        private _building = _x;
        private _index = 0;
        while {true} do {
            private _buildingPos = _building buildingPos _index;
            if (_buildingPos isEqualTo [0, 0, 0]) exitWith {};
            _buildingPositions pushBack _buildingPos;
            _index = _index + 1;
        };
    } forEach _buildings;
    if ((count _buildingPositions) == 0) then { continue };

    _buildingPositions = _buildingPositions call BIS_fnc_arrayShuffle;

    {
        if (_forEachIndex >= _buildingCount) exitWith {};
        if (isNil "CivMenArray" || {count CivMenArray == 0}) exitWith {};

        private _unitType = selectRandom CivMenArray;
        private _buildingPos = _x;
        private _groupId = [_buildingPos, "civ_building", nil, _objectiveId, 1, civilian, _unitType] call FLO_fnc_createVirtualGroup;
        if (_groupId == "") then { continue };

        private _groupData = _groups get _groupId;
        private _profile = [_objectiveId, _locationType, "civ_building", _buildingPos] call FLO_fnc_civilianBuildRoleProfile;

        _groupData set ["civilianRole", _profile get "role"];
        _groupData set ["civilianObjective", _objectiveId];
        _groupData set ["civilianAnchorPos", _buildingPos];
        _groupData set ["civilianRouteAnchors", [_buildingPos]];
        _groupData set ["civilianKnowledgeBias", _profile get "knowledgeBias"];
        _groupData set ["civilianTrustBias", _profile get "trustBias"];
        _groupData set ["civilianRoutineState", _profile get "routineState"];
        _groupData set ["noWaypoints", true];

        private _role = _profile get "role";
        _roleCounts set [_role, (_roleCounts getOrDefault [_role, 0]) + 1];
        _createdCount = _createdCount + 1;
    } forEach _buildingPositions;
} forEach _allLocations;

["CIVILIAN", 2, format [
    "Created %1 civilian groups across %2 populated locations | roles=%3",
    _createdCount,
    count _allLocations,
    _roleCounts
]] call FLO_fnc_log;

_createdCount
