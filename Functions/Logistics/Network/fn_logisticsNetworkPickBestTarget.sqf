/*
 * Function: FLO_fnc_logisticsNetworkPickBestTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the best reinforcement target from a candidate objective set.
 *   Static AA uses priority scoring; maneuver reinforcements first pass hard
 *   saturation gates, then score the remaining objectives by pressure,
 *   priority, and anti-dogpile penalties.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Candidate objective IDs <ARRAY>
 *   2: Group type <STRING> - Default infantry
 *   3: Spawn anchor position <ARRAY> - Default []
 *
 * Return Value:
 *   STRING - Selected objective ID or empty string
 */

params [
    "_net",
    "_candidates",
    ["_groupType", "infantry"],
    ["_spawnPos", []],
    ["_inboundCounts", createHashMap],
    ["_recentDispatchCounts", createHashMap],
    ["_batchDispatchCounts", createHashMap]
];

if (count _candidates == 0) exitWith { "" };

private _lastTarget = _net get "_lastReinforcementTarget";
private _available = +_candidates;

if (_groupType isEqualTo "static_aa") then {
    _available = _available select {
        !([_net, _x] call FLO_fnc_logisticsNetworkObjectiveHasStaticAA)
    };
};
if (count _available == 0) exitWith { "" };

if (_groupType isEqualTo "static_aa") exitWith {
    if (count _available > 1 && {_lastTarget in _available}) then {
        _available = _available - [_lastTarget];
    };

    private _bestScore = -1;
    private _bestCandidates = [];
    private _enemySide = _net get "_enemySide";

    {
        private _objId = _x;
        private _objData = FLO_Objectives get _objId;
        private _score = _objData get "priority";
        private _objPos = _objData get "position";
        private _nearestEnemyDist = 1e12;

        {
            private _enemyData = FLO_Objectives get _x;
            if ((_enemyData get "owner") != _enemySide) then { continue };

            private _dist = _objPos distance2D (_enemyData get "position");
            if (_dist < _nearestEnemyDist) then {
                _nearestEnemyDist = _dist;
            };
        } forEach (keys FLO_Objectives);

        _score = _score + ((_nearestEnemyDist min 6000) * 0.15);

        if (_score > _bestScore) then {
            _bestScore = _score;
            _bestCandidates = [_objId];
        } else {
            if (_score == _bestScore) then {
                _bestCandidates pushBack _objId;
            };
        };
    } forEach _available;

    selectRandom _bestCandidates
};

_available = _available select {
    [_net, _x, _groupType, _inboundCounts, _batchDispatchCounts] call FLO_fnc_logisticsNetworkCanDispatchToObjective
};
if (count _available == 0) exitWith { "" };

private _useAnchorPos = _spawnPos isEqualType [] && {count _spawnPos >= 2};
private _anchorPos = if (_useAnchorPos) then { _spawnPos } else { [] };

private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
private _enemyCountKey = if (_managedSide isEqualTo east) then { "bluforCount" } else { "opforCount" };
private _batchPenalty = _net get "REINFORCEMENT_BATCH_TARGET_PENALTY";
private _inboundPenalty = _net get "REINFORCEMENT_INBOUND_TARGET_PENALTY";
private _recentPenalty = _net get "REINFORCEMENT_RECENT_TARGET_PENALTY";
private _lastTargetPenalty = _net get "REINFORCEMENT_LAST_TARGET_PENALTY";

private _bestTarget = "";
private _bestScore = 1e12;
private _bestDist = 1e12;

{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;
    private _objPos = _objData get "position";
    private _dist = if (_useAnchorPos) then { _objPos distance2D _anchorPos } else { 0 };
    private _friendlyCount = _objData get _friendlyCountKey;
    private _enemyCount = _objData get _enemyCountKey;
    private _pressure = ((_enemyCount * 2) - _friendlyCount) max 0;
    private _priority = _objData get "priority";
    private _batchCount = _batchDispatchCounts getOrDefault [_objId, 0];
    private _inboundCount = _inboundCounts getOrDefault [_objId, 0];
    private _recentCount = _recentDispatchCounts getOrDefault [_objId, 0];
    private _score = _dist
        + (_batchCount * _batchPenalty)
        + (_inboundCount * _inboundPenalty)
        + (_recentCount * _recentPenalty)
        - (_pressure * 450)
        - (_priority * 120);

    if ((count _available) > 1 && {_objId isEqualTo _lastTarget}) then {
        _score = _score + _lastTargetPenalty;
    };

    if (_score < _bestScore || {_score == _bestScore && {_dist < _bestDist}}) then {
        _bestTarget = _objId;
        _bestScore = _score;
        _bestDist = _dist;
    };
} forEach _available;

_bestTarget
