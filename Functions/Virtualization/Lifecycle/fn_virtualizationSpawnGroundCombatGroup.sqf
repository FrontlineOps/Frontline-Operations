/*
 * Function: FLO_fnc_virtualizationSpawnGroundCombatGroup
 */

params ["_groupId", "_position", "_side", "_unitCount", "_groupType", "_pools"];

private _sideKey = _pools get "sideKey";
private _unitPool = _pools get "units";
[_unitPool, "units", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;

private _vehiclePool = switch (_groupType) do {
    case "motorized": { _pools get "groundLight" };
    case "mechanized";
    case "armor": { _pools get "groundHeavy" };
    case "mobile_aa": { _pools get "mobileAA" };
    default { [] };
};

private _vehiclePoolName = switch (_groupType) do {
    case "motorized": { "groundLight" };
    case "mechanized";
    case "armor": { "groundHeavy" };
    case "mobile_aa": { "mobileAA" };
    default { _groupType };
};

[_vehiclePool, _vehiclePoolName, _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;

private _realGroup = createGroup [_side, true];

for "_i" from 1 to _unitCount do {
    private _vehicleType = selectRandom _vehiclePool;
    private _minDist = 10 + (20 * _i);
    private _spawnPos = [
        _groupId,
        _position,
        _minDist,
        if (_groupType isEqualTo "mobile_aa") then { 100 } else { 150 },
        if (_groupType isEqualTo "mobile_aa") then { 8 } else { 10 },
        0.2,
        if (_groupType isEqualTo "mobile_aa") then { 150 } else { 200 },
        "Vehicle"
    ] call FLO_fnc_virtualizationResolveGroundSpawnPos;
    private _crewType = [_vehicleType, _unitPool, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
    [_realGroup, _vehicleType, _spawnPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
};

_realGroup
