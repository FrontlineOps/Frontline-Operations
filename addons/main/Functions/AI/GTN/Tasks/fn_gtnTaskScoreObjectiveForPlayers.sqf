/*
 * Function: FLO_fnc_gtnTaskScoreObjectiveForPlayers
 * Author: Frontline Operations Development Group
 * Description:
 *   Scores an objective for player-facing GTN tasks using player proximity,
 *   local player concentration, objective subtype, and frontline pressure so
 *   tasks stay anchored to the local fight instead of defaulting to large
 *   rear-area objectives or one distant outlier player.
 *
 * Arguments:
 *   0: Objective ID <STRING>
 *   1: Objective Data <HASHMAP>
 *   2: Player Positions <ARRAY>
 *   3: Role <STRING> - "capture", "defend", "destroy"
 *   4: Objective World State Data <HASHMAP>
 *   5: World State <HASHMAP|NIL>
 *
 * Return Value:
 *   Score <NUMBER>
 */

params [
    ["_objectiveId", "", [""]],
    ["_objectiveData", createHashMap, [createHashMap]],
    ["_playerPositions", [], [[]]],
    ["_role", "capture", [""]],
    ["_objectiveState", createHashMap, [createHashMap]],
    ["_worldState", nil]
];

private _objectivePos = _objectiveData get "position";
private _playerDistances = _playerPositions apply { _objectivePos distance2D _x };
_playerDistances sort true;

private _nearestPlayerDist = _playerDistances param [0, 1e9];
private _distanceBasis = _nearestPlayerDist;
private _nearestSampleCount = (count _playerDistances) min 3;
if (_nearestSampleCount > 0) then {
    private _distanceTotal = 0;
    for "_i" from 0 to (_nearestSampleCount - 1) do {
        _distanceTotal = _distanceTotal + (_playerDistances select _i);
    };
    _distanceBasis = _distanceTotal / _nearestSampleCount;
};

if (_nearestPlayerDist isEqualTo 1e9) then {
    _nearestPlayerDist = 6000;
    _distanceBasis = 6000;
};

private _subtype = toLower (_objectiveData get "subtype");
private _priority = _objectiveData get "priority";
private _friendlyCount = 0;
private _enemyCount = 0;
private _underAttack = false;
private _contested = false;

if (_objectiveState isNotEqualTo []) then {
    _friendlyCount = _objectiveState get "friendlyCount";
    _enemyCount = _objectiveState get "enemyCount";
    _underAttack = _objectiveState get "underAttack";
    _contested = _objectiveState get "contested";
};

private _subtypeScore = switch (_role) do {
    case "destroy": {
        switch (_subtype) do {
            case "local": { 48 };
            case "cluster": { 44 };
            case "village": { 40 };
            case "marine": { 36 };
            case "city": { 18 };
            case "capital": { 6 };
            default { 22 };
        };
    };
    case "defend": {
        switch (_subtype) do {
            case "local": { 34 };
            case "cluster": { 30 };
            case "village": { 32 };
            case "marine": { 28 };
            case "city": { 24 };
            case "capital": { 20 };
            default { 22 };
        };
    };
    default {
        switch (_subtype) do {
            case "local": { 42 };
            case "cluster": { 38 };
            case "village": { 36 };
            case "marine": { 32 };
            case "city": { 16 };
            case "capital": { 4 };
            default { 20 };
        };
    };
};

private _supportingPlayerCount = {
    _x <= 2500
} count _playerDistances;
private _distanceScore = linearConversion [600, 7000, _distanceBasis, 52, 0, true];
private _supportBonus = if (_supportingPlayerCount > 0) then {
    linearConversion [1, 4, _supportingPlayerCount, 0, 14, true]
} else {
    0
};
private _frontlineBonus = 0;
private _frontlineEnemy = false;

if (_objectiveState isNotEqualTo [] && {!isNil {_objectiveState get "frontlineEnemy"}}) then {
    _frontlineEnemy = _objectiveState get "frontlineEnemy";
};

if (!_frontlineEnemy && {!isNil "_worldState"}) then {
    if (_role in ["capture", "destroy"]) then {
        if (_worldState call ["_isFrontlineEnemyObjective", [_objectiveId]]) then {
            _frontlineEnemy = true;
        };
    };
};

if (_frontlineEnemy) then {
    _frontlineBonus = 30;
};

private _pressureBonus = switch (_role) do {
    case "defend": {
        (([0, 28] select (_underAttack))
        + ([0, 18] select (_contested))
        + ((_enemyCount - _friendlyCount) max 0) * 3)
    };
    case "destroy": {
        ((_enemyCount max 0) * 2) + ([0, 8] select (_contested))
    };
    default {
        ((_friendlyCount - _enemyCount) max 0) + ([0, 6] select (_contested))
    };
};

private _farPenalty = 0;
if (_distanceBasis > 4500) then {
    _farPenalty = linearConversion [4500, 9000, _distanceBasis, 8, 30, true];
};

_subtypeScore + _distanceScore + _supportBonus + _frontlineBonus + _pressureBonus + (_priority * 0.2) - _farPenalty
