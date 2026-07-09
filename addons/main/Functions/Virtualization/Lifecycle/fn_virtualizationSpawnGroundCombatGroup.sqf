/*
 * Function: FLO_fnc_virtualizationSpawnGroundCombatGroup
 */

params ["_groupId", "_position", "_side", "_unitCount", "_groupType", "_pools"];

private _sideKey = _pools get "sideKey";
private _unitPool = _pools get "units";
[_unitPool, "units", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;

private _poolData = [_groupType, _pools] call FLO_fnc_virtualizationGetGroundCombatVehiclePool;
_poolData params ["_vehiclePool", "_vehiclePoolName"];
[_vehiclePool, _vehiclePoolName, _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;

private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
private _composition = _groupData get "comp";
if (_composition isEqualTo []) then {
    _composition = [_groupType, _unitCount, _side] call FLO_fnc_virtualizationSelectInitialAssetComposition;
    [_groupData, _composition] call FLO_fnc_virtualizationSetAssetComposition;
};

private _realGroup = [_side, _groupId, _groupType] call FLO_fnc_virtualizationCreateRealGroup;
if (isNull _realGroup) exitWith { grpNull };

{
    private _vehicleType = _x;
    private _carrierIndex = _forEachIndex + 1;
    private _minDist = 10 + (20 * _carrierIndex);
    private _spawnPos = [
        _groupId,
        _position,
        _minDist,
        [150, 100] select (_groupType isEqualTo "mobile_aa"),
        [10, 8] select (_groupType isEqualTo "mobile_aa"),
        0.2,
        [200, 150] select (_groupType isEqualTo "mobile_aa"),
        "Vehicle"
    ] call FLO_fnc_virtualizationResolveGroundSpawnPos;
    private _crewType = [_vehicleType, _unitPool, _sideKey, _groupType] call FLO_fnc_virtualizationResolveCrewType;
    [_realGroup, _vehicleType, _spawnPos, _crewType] call FLO_fnc_virtualizationCreateCrewedVehicle;
} forEach _composition;

if ((units _realGroup) isEqualTo []) exitWith {
    deleteGroup _realGroup;
    grpNull
};

_realGroup
