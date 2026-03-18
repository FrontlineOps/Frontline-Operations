/*
 * Function: FLO_fnc_logisticsNetworkPickBestTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the best reinforcement target from a candidate objective set.
 *   Static AA uses priority scoring; maneuver reinforcements rotate among the
 *   nearest eligible objectives to keep pressure distributed.
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

params ["_net", "_candidates", ["_groupType", "infantry"], ["_spawnPos", []]];

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

private _anchorPos = if (_spawnPos isEqualType [] && {count _spawnPos >= 2}) then {
    _spawnPos
} else {
    (FLO_Objectives get (_available select 0)) get "position"
};

private _scored = [];
{
    private _objPos = (FLO_Objectives get _x) get "position";
    _scored pushBack [(_objPos distance2D _anchorPos), _x];
} forEach _available;
_scored sort true;

private _ordered = _scored apply { _x select 1 };
if (count _ordered > 6) then {
    _ordered resize 6;
};

private _cycle = _net get "_reinforcementTargetCycle";
if ((count _cycle) != (count _ordered) || {str _cycle != str _ordered}) then {
    _cycle = +_ordered;
    _net set ["_reinforcementTargetCycle", _cycle];
    _net set ["_reinforcementCycleIndex", 0];
};

if (count _cycle == 0) exitWith { "" };

private _idx = _net get "_reinforcementCycleIndex";
if (_idx >= count _cycle) then {
    _idx = 0;
};

private _selected = _cycle select _idx;
if ((count _cycle) > 1 && {_selected isEqualTo _lastTarget}) then {
    _idx = (_idx + 1) mod (count _cycle);
    _selected = _cycle select _idx;
};

_net set ["_reinforcementCycleIndex", (_idx + 1) mod (count _cycle)];
_selected
