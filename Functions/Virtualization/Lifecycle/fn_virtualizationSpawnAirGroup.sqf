/*
 * Function: FLO_fnc_virtualizationSpawnAirGroup
 */

params ["_position", "_side", "_unitCount", "_groupType", "_pools"];

private _sideKey = _pools get "sideKey";
private _unitPool = _pools get "units";
[_unitPool, "units", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;

private _heliPool = _pools get "airHeli";
private _jetPool = _pools get "airJet";

private _airPool = switch (_groupType) do {
    case "helicopter": {
        [_heliPool, "airHeli", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries
    };
    case "jet": {
        [_jetPool, "airJet", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries
    };
    default {
        private _combined = +_heliPool + _jetPool;
        [_combined, "airHeli/airJet", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries
    };
};

private _realGroup = createGroup [_side, true];

for "_i" from 1 to _unitCount do {
    private _aircraftType = selectRandom _airPool;
    private _spawnHeight = if (_groupType isEqualTo "jet") then { 500 } else { 100 };
    private _spawnPos = [(_position select 0) + (50 * _i), (_position select 1), _spawnHeight];
    private _crewType = [_aircraftType, _unitPool, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
    [_realGroup, _aircraftType, _spawnPos, _crewType, true] call FLO_fnc_virtualizationCreateCrewedVehicle;
};

_realGroup
