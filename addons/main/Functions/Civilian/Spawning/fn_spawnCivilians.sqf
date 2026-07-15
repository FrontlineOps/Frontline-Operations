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
private _civilianCatalog = FLO_FactionCatalog get "CIVILIAN";
private _civilianMen = _civilianCatalog get "men";
private _civilianVehicles = _civilianCatalog get "vehicles";
private _roleCounts = createHashMap;
private _poiCaches = createHashMap;
private _allLocations = [];

{
    private _locationType = _x;
    {
        _allLocations pushBack [_x, _locationType];
    } forEach (nearestLocations [[worldSize * 0.5, worldSize * 0.5, 0], [_locationType], worldSize]);
} forEach _locationTypes;

private _createdCount = 0;
private _rejectedCount = 0;

{
    _x params ["_location", "_locationType"];

    private _locationPos = locationPosition _location;
    private _objectiveId = [_locationPos] call FLO_fnc_civilianResolveObjective;
    if (_objectiveId == "") then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    private _objectiveRadius = (_objective get "radius") max 90;
    private _poiCache = if (_objectiveId in _poiCaches) then {
        _poiCaches get _objectiveId
    } else {
        private _cache = [_objectiveId] call FLO_fnc_civilianBuildObjectivePoiCache;
        _poiCaches set [_objectiveId, _cache];
        _cache
    };
    private _ambientContext = createHashMapFromArray [
        ["disposition", "NEUTRAL"],
        ["contested", _objective get "contested"]
    ];
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
        private _groupId = [_spawnPos, "civilian", nil, _objectiveId, 1, civilian] call FLO_fnc_createVirtualGroup;
        if (_groupId == "") then {
            _rejectedCount = _rejectedCount + 1;
            continue;
        };

        [_groupId, _profile, _objectiveId, _profile get "anchorPos"] call FLO_fnc_civilianConfigureVirtualGroup;

        if !([_groupId, _ambientContext, _poiCache] call FLO_fnc_civilianApplyInitialRoutine) then {
            _rejectedCount = _rejectedCount + 1;
            continue;
        };

        private _role = _profile get "role";
        _roleCounts set [_role, (_roleCounts getOrDefault [_role, 0]) + 1];
        _createdCount = _createdCount + 1;
    };

    for "_i" from 1 to _carCount do {
        if (_civilianVehicles isEqualTo []) then { continue };

        private _parkingData = [(_objective get "position"), _objectiveRadius, 4] call FLO_fnc_getRoadParkingPos;
        _parkingData params ["_parkPos", "_parkDir"];

        private _groupId = [_parkPos, "civilianVehicle", nil, _objectiveId, 1, civilian] call FLO_fnc_createVirtualGroup;
        if (_groupId == "") then {
            _rejectedCount = _rejectedCount + 1;
            continue;
        };

        private _profile = [_objectiveId, _locationType, "civilianVehicle", _parkPos] call FLO_fnc_civilianBuildRoleProfile;
        [_groupId, _profile, _objectiveId, _parkPos, _parkDir] call FLO_fnc_civilianConfigureVirtualGroup;

        if !([_groupId, _ambientContext, _poiCache] call FLO_fnc_civilianApplyInitialRoutine) then {
            _rejectedCount = _rejectedCount + 1;
            continue;
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
    if (_buildings isEqualTo []) then { continue };

    private _buildingPositions = [];
    {
        private _building = _x;
        private _index = 0;
        while {true} do {
            private _buildingPos = _building buildingPos _index;
            if (_buildingPos isEqualTo [0, 0, 0]) exitWith {};
            if !(surfaceIsWater _buildingPos) then {
                _buildingPositions pushBack _buildingPos;
            };
            _index = _index + 1;
        };
    } forEach _buildings;
    if (_buildingPositions isEqualTo []) then { continue };

    _buildingPositions = _buildingPositions call BIS_fnc_arrayShuffle;

    {
        if (_forEachIndex >= _buildingCount) exitWith {};
        if (_civilianMen isEqualTo []) exitWith {};

        private _unitType = selectRandom _civilianMen;
        private _buildingPos = _x;
        private _groupId = [_buildingPos, "civ_building", nil, _objectiveId, 1, civilian, _unitType] call FLO_fnc_createVirtualGroup;
        if (_groupId == "") then {
            _rejectedCount = _rejectedCount + 1;
            continue;
        };

        private _profile = [_objectiveId, _locationType, "civ_building", _buildingPos] call FLO_fnc_civilianBuildRoleProfile;

        [_groupId, _profile, _objectiveId, _buildingPos] call FLO_fnc_civilianConfigureVirtualGroup;

        if !([_groupId, _ambientContext, _poiCache] call FLO_fnc_civilianApplyInitialRoutine) then {
            _rejectedCount = _rejectedCount + 1;
            continue;
        };

        private _role = _profile get "role";
        _roleCounts set [_role, (_roleCounts getOrDefault [_role, 0]) + 1];
        _createdCount = _createdCount + 1;
    } forEach _buildingPositions;
} forEach _allLocations;

["CIVILIAN", 3, format [
    "Created %1 civilian groups across %2 populated locations | rejected=%3 roles=%4",
    _createdCount,
    count _allLocations,
    _rejectedCount,
    _roleCounts
]] call FLO_fnc_log;

_createdCount
