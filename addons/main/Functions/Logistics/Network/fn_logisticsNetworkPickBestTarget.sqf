/*
 * Function: FLO_fnc_logisticsNetworkPickBestTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the best reinforcement target from a candidate objective set.
 *   Static AA uses priority scoring; maneuver reinforcements first pass hard
 *   saturation gates, then choose by doctrine:
 *   collapse relief first, then frontline pressure, background pressure,
 *   then rear fallback.
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

if (_candidates isEqualTo []) exitWith { "" };

private _lastTarget = _net get "_lastReinforcementTarget";
private _available = +_candidates;

if (_groupType isEqualTo "static_aa") then {
    _available = _available select {
        !([_net, _x] call FLO_fnc_logisticsNetworkObjectiveHasStaticAA)
    };
};
if (_available isEqualTo []) exitWith { "" };

if (_groupType isEqualTo "static_aa") exitWith {
    if (count _available > 1 && {_lastTarget in _available}) then {
        _available = _available - [_lastTarget];
    };

    private _bestScore = -1;
    private _bestCandidates = [];
    private _enemyObjectives = _net get "_enemyObjectiveIds";

    if (_enemyObjectives isEqualTo []) exitWith { "" };

    {
        private _objId = _x;
        private _objData = FLO_Objectives get _objId;
        private _score = _objData get "priority";
        private _objPos = _objData get "position";
        private _nearestEnemyDist = 1e12;

        {
            private _dist = _objPos distance2D ((FLO_Objectives get _x) get "position");
            if (_dist < _nearestEnemyDist) then {
                _nearestEnemyDist = _dist;
            };
        } forEach _enemyObjectives;

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
if (_available isEqualTo []) exitWith { "" };

private _managedSide = _net get "_managedSide";
private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);
private _branchRecentCounts = [_net, _recentDispatchCounts] call FLO_fnc_logisticsNetworkBuildBranchDispatchCounts;
private _branchInboundCounts = [_net, _inboundCounts] call FLO_fnc_logisticsNetworkBuildBranchDispatchCounts;
private _branchBatchCounts = [_net, _batchDispatchCounts] call FLO_fnc_logisticsNetworkBuildBranchDispatchCounts;
private _collapseCandidates = [];
private _frontlinePressureCandidates = [];
private _pressureCandidates = [];
private _rearCandidates = [];

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;

    if ((_objective get _enemyCountKey) > 0) then {
        if ([_net, _objectiveId] call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure) then {
            _collapseCandidates pushBack _objectiveId;
        } else {
            if ([_net, _objectiveId] call FLO_fnc_logisticsNetworkObjectiveIsFrontlinePressure) then {
                _frontlinePressureCandidates pushBack _objectiveId;
            } else {
                _pressureCandidates pushBack _objectiveId;
            };
        };
        continue;
    };

    _rearCandidates pushBack _objectiveId;
} forEach _available;

if (_collapseCandidates isNotEqualTo []) exitWith {
    [_net, _collapseCandidates, _inboundCounts, _recentDispatchCounts, _batchDispatchCounts, _branchInboundCounts, _branchRecentCounts, _branchBatchCounts] call FLO_fnc_logisticsNetworkPickPressureTarget
};

if (_frontlinePressureCandidates isNotEqualTo []) exitWith {
    [_net, _frontlinePressureCandidates, _inboundCounts, _recentDispatchCounts, _batchDispatchCounts, _branchInboundCounts, _branchRecentCounts, _branchBatchCounts] call FLO_fnc_logisticsNetworkPickPressureTarget
};

if (_pressureCandidates isNotEqualTo []) exitWith {
    [_net, _pressureCandidates, _inboundCounts, _recentDispatchCounts, _batchDispatchCounts, _branchInboundCounts, _branchRecentCounts, _branchBatchCounts] call FLO_fnc_logisticsNetworkPickPressureTarget
};

[_net, _rearCandidates] call FLO_fnc_logisticsNetworkPickRearTarget
