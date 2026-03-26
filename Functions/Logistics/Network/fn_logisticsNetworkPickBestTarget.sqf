/*
 * Function: FLO_fnc_logisticsNetworkPickBestTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the best reinforcement target from a candidate objective set.
 *   Static AA uses priority scoring; maneuver reinforcements first pass hard
 *   saturation gates, then choose by explicit target role:
 *   pressure first, then supply advance, then rear fallback.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Candidate objective IDs <ARRAY>
 *   2: Group type <STRING> - Default infantry
 *   3: Inbound requested-objective counts <HASHMAP> - Default empty map
 *   4: Recent dispatch counts <HASHMAP> - Default empty map
 *   5: Batch requested-objective counts <HASHMAP> - Default empty map
 *
 * Return Value:
 *   STRING - Selected objective ID or empty string
 */

params [
    "_net",
    "_candidates",
    ["_groupType", "infantry"],
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

private _managedSide = _net get "_managedSide";
private _enemyCountKey = if (_managedSide isEqualTo east) then { "bluforCount" } else { "opforCount" };
private _pressureCandidates = [];
private _advanceCandidates = [];
private _rearCandidates = [];

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;

    if ((_objective get _enemyCountKey) > 0) then {
        _pressureCandidates pushBack _objectiveId;
        continue;
    };

    private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
    if (_role get "isAdvanceCandidate") then {
        _advanceCandidates pushBack _objectiveId;
    } else {
        _rearCandidates pushBack _objectiveId;
    };
} forEach _available;

if (count _pressureCandidates > 0) exitWith {
    [_net, _pressureCandidates, _inboundCounts, _recentDispatchCounts, _batchDispatchCounts] call FLO_fnc_logisticsNetworkPickPressureTarget
};

if (count _advanceCandidates > 0) exitWith {
    [_net, _advanceCandidates] call FLO_fnc_logisticsNetworkPickAdvanceTarget
};

[_net, _rearCandidates] call FLO_fnc_logisticsNetworkPickRearTarget
