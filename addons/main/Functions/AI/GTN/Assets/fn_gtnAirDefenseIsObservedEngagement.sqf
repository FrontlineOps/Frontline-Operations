/* Tests cached player observation at aircraft and AA simulation areas. */
params [
    ["_airPositions", [], [[]]],
    ["_aaPosition", [], [[]]]
];

if (_airPositions isEqualTo [] || {count _aaPosition < 2}) then {
    throw "Air-defense observation requires aircraft and AA positions";
};
if ((_airPositions findIf {count _x < 2}) >= 0) then {
    throw "Air-defense observation received an invalid aircraft position";
};

if ((FLO_VirtUpdate get "lastPlayerCacheTime") <= 0) then {
    call FLO_fnc_virtualizationCachePlayers;
};

private _groundRadius = ["activationDistance"] call FLO_fnc_virtualizationGetConfigValue;
if (([_aaPosition] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) <= _groundRadius) exitWith { true };

private _airRadius = _groundRadius * FLO_AirActivationDistanceMultiplier;
(_airPositions findIf {
    ([_x] call FLO_fnc_virtualizationGetNearestCachedPlayerDistance) <= _airRadius
}) >= 0
