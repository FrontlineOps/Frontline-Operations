/*
 * Function: FLO_fnc_virtualizationSpawnAirGroup
 */

params ["_groupId", "_position", "_side", "_unitCount", "_groupType", "_pools", "_groupData"];

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

private _realGroup = [_side, _groupId, _groupType] call FLO_fnc_virtualizationCreateRealGroup;
if (isNull _realGroup) exitWith { grpNull };

private _spawnParkedHelicopters = _groupType == "helicopter"
    && { count (_groupData get "waypoints") == 0 }
    && { (_groupData get "missionLock") == "" }
    && { (_groupData get "replacementState") == "" }
    && { !(_groupData get "engagementActive") }
    && { count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) == 0 }
    && { (_groupData get "state") == "idle" || { _groupData get "transportRole" } };

for "_i" from 1 to _unitCount do {
    private _aircraftType = selectRandom _airPool;
    private _spawnParked = _spawnParkedHelicopters && { _aircraftType isKindOf "Helicopter" };
    private _spawnPos = if (_spawnParked) then {
        [_position, _aircraftType, _i - 1, 600] call FLO_fnc_virtualizationResolveIdleHelicopterParkPos
    } else {
        private _spawnHeight = if (_groupType isEqualTo "jet") then { 500 } else { 100 };
        [(_position select 0) + (50 * _i), (_position select 1), _spawnHeight]
    };
    private _crewType = [_aircraftType, _unitPool, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
    [_realGroup, _aircraftType, _spawnPos, _crewType, !_spawnParked] call FLO_fnc_virtualizationCreateCrewedVehicle;
};

if ((count units _realGroup) == 0) exitWith {
    deleteGroup _realGroup;
    grpNull
};

_realGroup
