/* Validates one class-aware physical ground-vehicle activation position. */
params [
    ["_candidate", [], [[]]],
    ["_origin", [], [[]]],
    ["_maxDistance", 0, [0]],
    ["_vehicleType", "", [""]],
    ["_safeRadius", 0, [0]],
    ["_playerClearance", 150, [0]]
];

if (_vehicleType == "" || {!isClass (configFile >> "CfgVehicles" >> _vehicleType)}) then {
    throw format ["Ground spawn validation received invalid vehicle class %1", _vehicleType];
};
if (count _candidate < 2 || {count _origin < 2} || {_maxDistance <= 0}) exitWith { false };
if ((_candidate select 0) < 100 && {(_candidate select 1) < 100}) exitWith { false };
if ((_candidate distance2D _origin) > _maxDistance) exitWith { false };
if (surfaceIsWater _candidate) exitWith { false };

private _isStatic = _vehicleType isKindOf "StaticWeapon";
private _minimumNormalZ = [0.9, 0.94] select _isStatic;
if (((surfaceNormal _candidate) select 2) < _minimumNormalZ) exitWith { false };

private _vehicleSize = sizeOf _vehicleType;
private _clearance = (_safeRadius max ((_vehicleSize * 0.55) max 4)) min 20;
if ((nearestTerrainObjects [
    _candidate,
    ["BUILDING", "HOUSE", "WALL", "ROCKS", "TREE", "SMALL TREE"],
    _clearance,
    false,
    true
]) isNotEqualTo []) exitWith { false };
if ((nearestObjects [_candidate, ["House", "LandVehicle", "StaticWeapon"], _clearance, true]) isNotEqualTo []) exitWith {
    false
};

if ((FLO_VirtUpdate get "lastPlayerCacheTime") <= 0) then {
    call FLO_fnc_virtualizationCachePlayers;
};

([_candidate] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) >= _playerClearance
