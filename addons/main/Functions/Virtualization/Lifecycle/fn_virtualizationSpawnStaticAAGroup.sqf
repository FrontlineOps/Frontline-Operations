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

private _safePos = [_groupId, _position, 20, 100, 15, 0.1, 150, "Static AA"] call FLO_fnc_virtualizationResolveGroundSpawnPos;

if (_radarPool isNotEqualTo []) then {
    private _radarType = selectRandom _radarPool;
    private _radarPos = _safePos getPos [15, random 360];
    private _crewType = [_radarType, _unitPool, _sideKey, "static_aa"] call FLO_fnc_virtualizationResolveCrewType;
    private _radar = createVehicle [_radarType, _radarPos, [], 0, "NONE"];
    _radar setPos [getPos _radar select 0, getPos _radar select 1, 0];
    _radar setVehicleReportRemoteTargets true;
    _radar setVehicleRadar 1;
    private _operator = _realGroup createUnit [_crewType, _radarPos, [], 0, "NONE"];
    if (isNull _operator) then {
        deleteVehicle _radar;
    } else {
        _operator moveInAny _radar;
    };
};

for "_i" from 1 to _unitCount do {
    private _samType = selectRandom _staticAAPool;
    private _offset = 25 + (15 * _i);
    private _angle = (360 / _unitCount) * _i;
    private _spawnPos = _safePos getPos [_offset, _angle];
    private _launcher = createVehicle [_samType, _spawnPos, [], 0, "NONE"];
    _launcher setPos [getPos _launcher select 0, getPos _launcher select 1, 0];
    _launcher setDir (_angle + 180);
    _launcher setVehicleReceiveRemoteTargets true;
    private _crewType = [_samType, _unitPool, _sideKey, "static_aa"] call FLO_fnc_virtualizationResolveCrewType;
    private _gunner = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
    if (isNull _gunner) then {
        deleteVehicle _launcher;
    } else {
        _gunner moveInGunner _launcher;
    };
};

if ((units _realGroup) isEqualTo []) exitWith {
    deleteGroup _realGroup;
    grpNull
};

_groupData set ["noWaypoints", true];

_realGroup
