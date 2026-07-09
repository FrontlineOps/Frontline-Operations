/*
 * Function: FLO_fnc_virtualizationResolveIdleHelicopterParkPos
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a clear ground parking position for an idle helicopter.
 */

params [
    ["_basePos", [0, 0, 0], [[]]],
    ["_vehicleType", "", [""]],
    ["_index", 0, [0]],
    ["_searchRadius", 600, [0]]
];

private _offsetDistance = if (_index <= 0) then { 0 } else { 24 + (16 * _index) };
private _offsetPos = _basePos getPos [_offsetDistance, (_index * 137) mod 360];
_offsetPos set [2, 0];

private _parkPos = [];
if (_vehicleType != "") then {
    _parkPos = _offsetPos findEmptyPosition [0, _searchRadius, _vehicleType];
};

if (_parkPos isEqualTo [] || { surfaceIsWater _parkPos }) then {
    _parkPos = [_offsetPos, 10, _searchRadius, 16, 0, 0.35, 0] call BIS_fnc_findSafePos;
};

if (_parkPos isEqualTo [] || { surfaceIsWater _parkPos }) then {
    _parkPos = [_offsetPos, _searchRadius] call FLO_fnc_getSafeLandPos;
};

_parkPos set [2, 0];
_parkPos
