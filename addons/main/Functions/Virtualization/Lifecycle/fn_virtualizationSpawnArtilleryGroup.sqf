/*
 * Function: FLO_fnc_virtualizationSpawnArtilleryGroup
 */

params ["_groupId", "_position", "_side", "_unitCount", "_pools"];

private _sideKey = _pools get "sideKey";
private _unitPool = _pools get "units";
private _artilleryPool = _pools get "groundArtillery";

[_unitPool, "units", _sideKey, "artillery"] call FLO_fnc_virtualizationRequirePoolEntries;
[_artilleryPool, "groundArtillery", _sideKey, "artillery"] call FLO_fnc_virtualizationRequirePoolEntries;

private _realGroup = [_side, _groupId, "artillery"] call FLO_fnc_virtualizationCreateRealGroup;
if (isNull _realGroup) exitWith { grpNull };

private _groupData = (call FLO_fnc_virtualizationGetGroupMap) get _groupId;
private _spawnFailed = false;
for "_i" from 1 to _unitCount do {
    if (_spawnFailed) then { continue };
    private _artilleryType = selectRandom _artilleryPool;
    private _minDist = 15 + (25 * _i);
    private _spawnPos = [_groupId, _position, _minDist, 150, 12, 0.15, 200, "Artillery", _artilleryType, false] call FLO_fnc_virtualizationResolveGroundSpawnPos;
    if (_spawnPos isEqualTo []) then {
        _spawnFailed = true;
        continue
    };
    private _crewType = [_artilleryType, _unitPool, _sideKey, "artillery"] call FLO_fnc_virtualizationResolveCrewType;
    private _vehicle = [_realGroup, _artilleryType, _spawnPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
    if (isNull _vehicle) then {
        _spawnFailed = true;
    };
};

if (_spawnFailed) exitWith {
    [_groupData, _realGroup, false] call FLO_fnc_virtualizationDeleteRealGroupAssets;
    grpNull
};

if ((units _realGroup) isEqualTo []) exitWith {
    deleteGroup _realGroup;
    grpNull
};

_realGroup
