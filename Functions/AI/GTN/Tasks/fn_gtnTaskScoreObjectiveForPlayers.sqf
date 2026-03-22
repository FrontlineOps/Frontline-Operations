/*
 * Function: FLO_fnc_gtnTaskScoreObjectiveForPlayers
 * Author: Frontline Operations Development Group
 * Description:
 *   Scores an objective for player-facing GTN tasks using player proximity,
 *   objective subtype, and frontline pressure so tasks stay anchored to the
 *   local fight instead of defaulting to large rear-area objectives.
 *
 * Arguments:
 *   0: Objective ID <STRING>
 *   1: Objective Data <HASHMAP>
 *   2: Player Positions <ARRAY>
 *   3: Role <STRING> - "capture", "defend", "destroy"
 *   4: Objective World State Data <HASHMAP|NIL>
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
    ["_objectiveState", nil],
    ["_worldState", nil]
];

private _objectivePos = _objectiveData get "position";
private _nearestPlayerDist = 1e9;

{
    private _dist = _objectivePos distance2D _x;
    if (_dist < _nearestPlayerDist) then {
        _nearestPlayerDist = _dist;
    };
} forEach _playerPositions;

if (_nearestPlayerDist isEqualTo 1e9) then {
    _nearestPlayerDist = 6000;
};

private _subtype = toLower (_objectiveData get "subtype");
private _priority = _objectiveData get "priority";
private _friendlyCount = 0;
private _enemyCount = 0;
private _underAttack = false;
private _contested = false;

if (!isNil "_objectiveState") then {
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

private _distanceScore = linearConversion [600, 7000, _nearestPlayerDist, 52, 0, true];
private _frontlineBonus = 0;

if (!isNil "_worldState") then {
    if (_role in ["capture", "destroy"]) then {
        if (_worldState call ["_isFrontlineEnemyObjective", [_objectiveId]]) then {
            _frontlineBonus = 30;
        };
    };
};

private _pressureBonus = switch (_role) do {
    case "defend": {
        ((if (_underAttack) then { 28 } else { 0 })
        + (if (_contested) then { 18 } else { 0 })
        + ((_enemyCount - _friendlyCount) max 0) * 3)
    };
    case "destroy": {
        ((_enemyCount max 0) * 2) + (if (_contested) then { 8 } else { 0 })
    };
    default {
        ((_friendlyCount - _enemyCount) max 0) + (if (_contested) then { 6 } else { 0 })
    };
};

private _farPenalty = 0;
if (_nearestPlayerDist > 4500) then {
    _farPenalty = linearConversion [4500, 9000, _nearestPlayerDist, 8, 30, true];
};

_subtypeScore + _distanceScore + _frontlineBonus + _pressureBonus + (_priority * 0.2) - _farPenalty
