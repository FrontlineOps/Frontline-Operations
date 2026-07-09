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
    ["_label", "ground", [""]]
];

private _spawnPos = [_position, _minDist, _searchRadius, _safeRadius, 0, _waterCoef, 0] call BIS_fnc_findSafePos;
private _spawnValid = (_spawnPos isEqualType []) && {count _spawnPos >= 2};

if (_spawnValid) then {
    if (_spawnPos distance2D _position > _maxDistance) then {
        _spawnValid = false;
    };
    if ((_spawnPos select 0) < 100 && {(_spawnPos select 1) < 100}) then {
        _spawnValid = false;
    };
};

if (!_spawnValid) then {
    _spawnPos = _position getPos [_minDist, random 360];
    _spawnPos set [2, 0];
    ["VIRTUALIZATION", 2, format ["%1 spawn fallback used for group %2", _label, _groupId]] call FLO_fnc_log;
};

private _preClearancePos = +_spawnPos;
_spawnPos = [_spawnPos] call FLO_fnc_getSafeUnvirtualizePos;
if ((_spawnPos distance2D _preClearancePos) > 1) then {
    private _adjustedMeters = (round ((_spawnPos distance2D _preClearancePos) * 10)) / 10;
    ["VIRTUALIZATION", 2, format [
        "%1 spawn position adjusted for player clearance group=%2 original=%3 adjusted=%4 moved=%5m",
        _label,
        _groupId,
        _preClearancePos,
        _spawnPos,
        _adjustedMeters
    ]] call FLO_fnc_log;
};

_spawnPos
