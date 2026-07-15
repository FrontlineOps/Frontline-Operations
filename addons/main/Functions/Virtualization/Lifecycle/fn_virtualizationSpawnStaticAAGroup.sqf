/*
 * Function: FLO_fnc_virtualizationSpawnStaticAAGroup
 */

params ["_groupId", "_groupData", "_position", "_side", "_unitCount", "_pools"];

private _sideKey = _pools get "sideKey";
private _unitPool = _pools get "units";
private _staticAAPool = _pools get "staticAA";
private _radarPool = (_pools get "radar") select {
    !(_x isKindOf "Air") &&
    {!(_x isKindOf "Ship")} &&
    {(_x isKindOf "LandVehicle") || {_x isKindOf "StaticWeapon"}}
};

[_unitPool, "units", _sideKey, "static_aa"] call FLO_fnc_virtualizationRequirePoolEntries;
[_staticAAPool, "staticAA", _sideKey, "static_aa"] call FLO_fnc_virtualizationRequirePoolEntries;

private _realGroup = [_side, _groupId, "static_aa"] call FLO_fnc_virtualizationCreateRealGroup;
if (isNull _realGroup) exitWith { grpNull };

private _spawnFailed = false;

if (_radarPool isNotEqualTo []) then {
    private _radarType = selectRandom _radarPool;
    private _radarPos = [_groupId, _position, 20, 250, 8, 0.1, 300, "Static AA radar", _radarType, false] call FLO_fnc_virtualizationResolveGroundSpawnPos;
    if (_radarPos isEqualTo []) then {
        _spawnFailed = true;
    };
    private _crewType = [_radarType, _unitPool, _sideKey, "static_aa"] call FLO_fnc_virtualizationResolveCrewType;
    if (!_spawnFailed) then {
        private _radar = [_realGroup, _radarType, _radarPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
        if (isNull _radar) then {
            _spawnFailed = true;
        } else {
            _radar setVehicleReportRemoteTargets true;
            _radar setVehicleRadar 1;
        };
    };
};

for "_i" from 1 to _unitCount do {
    if (_spawnFailed) then { continue };
    private _samType = selectRandom _staticAAPool;
    private _offset = 25 + (15 * _i);
    private _angle = (360 / _unitCount) * _i;
    private _spawnPos = [_groupId, _position, _offset, 300, 5, 0.1, 350, "Static AA launcher", _samType, false] call FLO_fnc_virtualizationResolveGroundSpawnPos;
    if (_spawnPos isEqualTo []) then {
        _spawnFailed = true;
        continue
    };
    private _crewType = [_samType, _unitPool, _sideKey, "static_aa"] call FLO_fnc_virtualizationResolveCrewType;
    private _launcher = [_realGroup, _samType, _spawnPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
    if (isNull _launcher) then {
        _spawnFailed = true;
    } else {
        _launcher setDir (_angle + 180);
        _launcher setVehicleReceiveRemoteTargets true;
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

_groupData set ["noWaypoints", true];

_realGroup
