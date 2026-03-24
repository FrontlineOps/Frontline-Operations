/*
 * Function: FLO_fnc_virtualizationSpawnArtilleryGroup
 */

params ["_groupId", "_position", "_side", "_unitCount", "_pools"];

private _sideKey = _pools get "sideKey";
private _unitPool = _pools get "units";
private _artilleryPool = _pools get "groundArtillery";

[_unitPool, "units", _sideKey, "artillery"] call FLO_fnc_virtualizationRequirePoolEntries;
[_artilleryPool, "groundArtillery", _sideKey, "artillery"] call FLO_fnc_virtualizationRequirePoolEntries;

private _realGroup = createGroup [_side, true];

for "_i" from 1 to _unitCount do {
    private _artilleryType = selectRandom _artilleryPool;
    private _minDist = 15 + (25 * _i);
    private _spawnPos = [_groupId, _position, _minDist, 150, 12, 0.15, 200, "Artillery"] call FLO_fnc_virtualizationResolveGroundSpawnPos;
    private _crewType = [_artilleryType, _unitPool, _sideKey, "artillery"] call FLO_fnc_virtualizationResolveCrewType;
    [_realGroup, _artilleryType, _spawnPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
};

_realGroup
