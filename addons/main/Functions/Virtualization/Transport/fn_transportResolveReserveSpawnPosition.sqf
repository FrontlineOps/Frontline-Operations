/*
 * Function: FLO_fnc_transportResolveReserveSpawnPosition
 * Description:
 *   Builds a staged spawn position for a reserve carrier on its selected
 *   objective. Uses the logistics spawn cache as the base anchor, then spreads
 *   additional reserve carriers around that anchor so they do not stack on one
 *   point.
 *
 * Arguments:
 *   0: Logistics network <HASHMAP>
 *   1: Objective ID <STRING>
 *   2: Existing reserve count already assigned to that objective <NUMBER>
 *   3: Reserve type <STRING> - "ground" or "air"
 *   4: Fallback position <ARRAY>
 *
 * Return Value:
 *   ARRAY - Spawn position [x,y,z]
 */

params [
    ["_net", createHashMap, [createHashMap]],
    ["_objectiveId", "", [""]],
    ["_objectiveReserveCount", 0, [0]],
    ["_reserveType", "ground", [""]],
    ["_fallbackPos", [], [[]]]
];

private _spawnPos = [_net, _objectiveId] call FLO_fnc_logisticsNetworkGetCachedSpawnPosition;
if (_spawnPos isEqualTo [0, 0, 0]) then {
    _spawnPos = +_fallbackPos;
};

if (_spawnPos isEqualTo []) exitWith { [0, 0, 0] };

_spawnPos set [2, 0];

if (_objectiveReserveCount <= 0) exitWith { _spawnPos };

private _objective = FLO_Objectives get _objectiveId;
private _centerPos = +(_objective get "position");
_centerPos set [2, 0];

private _radius = ((_objective get "radius") max 80) * 0.8;
private _spreadBase = [14, 35] select (_reserveType isEqualTo "air");
private _spreadStep = [12, 28] select (_reserveType isEqualTo "air");
private _ringIndex = floor ((_objectiveReserveCount - 1) / 6);
private _angle = (_objectiveReserveCount * 137.5) mod 360;
private _offsetMeters = (_spreadBase + (_ringIndex * _spreadStep)) min _radius;

private _offsetPos = [
    (_spawnPos select 0) + ((sin _angle) * _offsetMeters),
    (_spawnPos select 1) + ((cos _angle) * _offsetMeters),
    0
];

if ((_offsetPos distance2D _centerPos) > _radius) then {
    _offsetPos = [
        (_centerPos select 0) + ((sin _angle) * (_radius * 0.85)),
        (_centerPos select 1) + ((cos _angle) * (_radius * 0.85)),
        0
    ];
};

_offsetPos
