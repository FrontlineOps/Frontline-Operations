/*
 * Function: FLO_fnc_virtualizationSelectInitialAssetComposition
 */

params [
    ["_groupType", "", [""]],
    ["_unitCount", 0, [0]],
    ["_side", east, [east]]
];

if !(_groupType in ["motorized", "mechanized", "armor", "mobile_aa"]) exitWith { [] };

private _pools = [_side] call FLO_fnc_virtualizationGetSpawnPools;
private _sideKey = _pools get "sideKey";
private _poolData = [_groupType, _pools] call FLO_fnc_virtualizationGetGroundCombatVehiclePool;
_poolData params ["_vehiclePool", "_vehiclePoolName"];

[_vehiclePool, _vehiclePoolName, _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;

private _selectionPool = _vehiclePool;
if (_groupType in ["motorized", "mechanized"]) then {
    _selectionPool = _vehiclePool select { ([_x] call FLO_fnc_transportGetCapacity) > 0 };

    if (_selectionPool isEqualTo []) then {
        ["VIRTUALIZATION", 2, format [
            "No cargo-capable %1 carriers in %2 pool for %3 - organic package support disabled for this pool",
            _groupType,
            _sideKey,
            _vehiclePool
        ]] call FLO_fnc_log;
        _selectionPool = _vehiclePool;
    };
};

private _assetCount = _unitCount max 1;
private _composition = [];

for "_i" from 1 to _assetCount do {
    _composition pushBack (selectRandom _selectionPool);
};

_composition
