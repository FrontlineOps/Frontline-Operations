/*
 * Function: FLO_fnc_virtualizationResolveGroundSpawnPos
 */

params [
    "_groupId",
    "_position",
    "_minDist",
    ["_searchRadius", 150, [0]],
    ["_safeRadius", 10, [0]],
    ["_waterCoef", 0.2, [0]],
    ["_maxDistance", 200, [0]],
    ["_label", "ground", [""]],
    ["_vehicleType", "", [""]],
    ["_preferRoad", true, [true]]
];

if (_vehicleType == "") then {
    throw format ["%1 spawn for group %2 has no vehicle class", _label, _groupId];
};

private _searchCenter = [_position] call FLO_fnc_getSafeUnvirtualizePos;
_searchCenter set [2, 0];
if ((_searchCenter distance2D _position) > 1) then {
    private _adjustedMeters = (round ((_searchCenter distance2D _position) * 10)) / 10;
    ["VIRTUALIZATION", 2, format [
        "%1 spawn position adjusted for player clearance group=%2 original=%3 adjusted=%4 moved=%5m",
        _label,
        _groupId,
        _position,
        _searchCenter,
        _adjustedMeters
    ]] call FLO_fnc_log;
};

private _spawnPos = [];
private _bestRoadDistance = 1e12;
if (_preferRoad) then {
    {
        private _candidate = getPosATL _x;
        private _distanceFromOrigin = _candidate distance2D _position;
        if (_distanceFromOrigin < _minDist) then { continue };
        if ([_candidate, _position, _maxDistance, _vehicleType, _safeRadius, 150] call FLO_fnc_virtualizationIsGroundSpawnPositionSafe) then {
            private _distanceFromSearch = _candidate distance2D _searchCenter;
            if (_distanceFromSearch < _bestRoadDistance) then {
                _bestRoadDistance = _distanceFromSearch;
                _spawnPos = _candidate;
            };
        };
    } forEach (_searchCenter nearRoads (_searchRadius min _maxDistance));
};

if (_spawnPos isEqualTo []) then {
    private _emptyPosition = _searchCenter findEmptyPosition [_minDist, _searchRadius, _vehicleType];
    if ([_emptyPosition, _position, _maxDistance, _vehicleType, _safeRadius, 150] call FLO_fnc_virtualizationIsGroundSpawnPositionSafe) then {
        _spawnPos = _emptyPosition;
    };
};

if (_spawnPos isEqualTo []) then {
    for "_attempt" from 1 to 8 do {
        private _candidate = [
            _searchCenter,
            _minDist,
            _searchRadius,
            _safeRadius,
            0,
            _waterCoef,
            0
        ] call BIS_fnc_findSafePos;
        if ([_candidate, _position, _maxDistance, _vehicleType, _safeRadius, 150] call FLO_fnc_virtualizationIsGroundSpawnPositionSafe) exitWith {
            _spawnPos = _candidate;
        };
    };
};

if (_spawnPos isEqualTo []) then {
    for "_radius" from _minDist to _searchRadius step 20 do {
        if (_spawnPos isNotEqualTo []) exitWith {};
        for "_bearing" from 0 to 330 step 30 do {
            private _candidate = _searchCenter getPos [_radius, _bearing];
            if ([_candidate, _position, _maxDistance, _vehicleType, _safeRadius, 150] call FLO_fnc_virtualizationIsGroundSpawnPositionSafe) exitWith {
                _spawnPos = _candidate;
            };
        };
    };
};

if (_spawnPos isEqualTo []) then {
    ["VIRTUALIZATION", 2, format [
        "No safe %1 spawn position for group=%2 vehicle=%3 origin=%4 search=%5m max=%6m",
        _label,
        _groupId,
        _vehicleType,
        _position,
        _searchRadius,
        _maxDistance
    ]] call FLO_fnc_log;
} else {
    _spawnPos set [2, 0];
};

_spawnPos
