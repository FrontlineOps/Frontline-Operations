/*
 * Function: FLO_fnc_gtnEvaluateGroupEngagementTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Evaluates whether a known enemy target is a valid opportunistic
 *   engagement target for a specific GTN-commanded group and returns a
 *   score/reason when valid.
 *
 * Arguments:
 * 0: Friendly group data <HASHMAP>
 * 1: Resolved enemy target data <HASHMAP>
 * 2: Commander config <HASHMAP>
 *
 * Return Value:
 * ARRAY - Empty when invalid, otherwise [score, reason, leashMeters]
 */

params ["_groupData", "_targetData", "_config", ["_groupContext", createHashMap, [createHashMap]]];

private _result = [];
private _order = _groupContext getOrDefault ["order", _groupData get "commanderOrder"];
if !(_order in ["ATTACK", "DEFEND", "GARRISON"]) exitWith { _result };

private _targetPos = _targetData get "position";
if (count _targetPos < 2) exitWith { _result };

private _targetOrder = _targetData get "commanderOrder";
private _targetType = _targetData get "groupType";
private _objectiveIds = _targetData get "objectiveIds";
private _isPlayerControlled = _targetData get "isPlayerControlled";
private _ageSeconds = diag_tickTime - (_targetData get "lastSeen");
private _targetOrderBonus = switch (_targetOrder) do {
    case "GARRISON": { 22 };
    case "DEFEND": { 18 };
    case "ATTACK": { 12 };
    case "MOVE": { 8 };
    default { 4 };
};
private _targetTypeBonus = switch (_targetType) do {
    case "armor": { 18 };
    case "mechanized": { 14 };
    case "motorized": { 11 };
    case "mobile_aa": { 12 };
    case "static_aa": { 10 };
    case "artillery": { 9 };
    default { 8 };
};
private _freshnessBonus = ((_config get "engagementFreshSeconds") - (_ageSeconds min (_config get "engagementFreshSeconds"))) / 12;
private _playerBonus = if (_isPlayerControlled) then { 12 } else { 0 };

switch (_order) do {
    case "ATTACK": {
        private _groupPos = _groupContext getOrDefault ["groupPos", _groupData get "position"];
        private _directDist = _groupPos distance2D _targetPos;
        private _leashMeters = _groupContext getOrDefault ["leashMeters", _config get "attackEngagementLeashMeters"];
        private _attackObjective = _groupContext getOrDefault ["attackObjective", _groupData get "attackObjective"];
        private _inAttackObjective = _attackObjective != "" && {_attackObjective in _objectiveIds};
        private _routePoints = _groupContext getOrDefault ["routePoints", []];

        private _routeDist = _directDist;
        if (count _routePoints > 1) then {
            _routeDist = 1e12;
            for "_i" from 0 to ((count _routePoints) - 2) do {
                private _segDist = [_targetPos, _routePoints select _i, _routePoints select (_i + 1)] call FLO_fnc_gtnDistanceToSegment2D;
                if (_segDist < _routeDist) then {
                    _routeDist = _segDist;
                };
            };
        };

        if (_directDist > _leashMeters && {_routeDist > _leashMeters}) exitWith { _result };

        private _proximityScore = ((_leashMeters - (_directDist min _leashMeters)) / 35) + ((_leashMeters - (_routeDist min _leashMeters)) / 30);
        private _objectiveBonus = if (_inAttackObjective) then { 28 } else { 0 };
        private _reason = if (_inAttackObjective) then {
            "ATTACK_OBJECTIVE"
        } else {
            if (_routeDist <= _directDist) then { "ATTACK_ROUTE" } else { "ATTACK_LOCAL" };
        };

        _result = [
            20 + _targetOrderBonus + _targetTypeBonus + _freshnessBonus + _playerBonus + _objectiveBonus + _proximityScore + ((_targetData get "contactCount") * 3),
            _reason,
            _config get "attackEngagementLeashMeters"
        ];
    };

    case "DEFEND": {
        private _objectiveId = _groupContext getOrDefault ["objectiveId", _groupData get "defendObjective"];
        if (_objectiveId == "" || {!(_objectiveId in _objectiveIds)}) exitWith { _result };

        private _holdPos = _groupContext getOrDefault ["holdPos", _groupData get "position"];
        private _leashMeters = _groupContext getOrDefault ["leashMeters", _config get "defenseEngagementLeashMeters"];
        private _holdDist = _holdPos distance2D _targetPos;
        if (_holdDist > _leashMeters) exitWith { _result };

        private _localThreatBonus = switch (_targetOrder) do {
            case "ATTACK": { 18 };
            case "MOVE": { 12 };
            default { 0 };
        };

        _result = [
            15 + _targetOrderBonus + _targetTypeBonus + _freshnessBonus + _playerBonus + _localThreatBonus + ((_leashMeters - _holdDist) / 25),
            "DEFEND_OBJECTIVE",
            _leashMeters
        ];
    };

    case "GARRISON": {
        private _objectiveId = _groupContext getOrDefault ["objectiveId", _groupData get "garrisonObjective"];
        if (_objectiveId == "" || {!(_objectiveId in _objectiveIds)}) exitWith { _result };

        private _holdPos = _groupContext getOrDefault ["holdPos", _groupData get "position"];
        private _leashMeters = _groupContext getOrDefault ["leashMeters", _config get "garrisonEngagementLeashMeters"];
        private _holdDist = _holdPos distance2D _targetPos;
        if (_holdDist > _leashMeters) exitWith { _result };

        private _localThreatBonus = switch (_targetOrder) do {
            case "ATTACK": { 18 };
            case "MOVE": { 12 };
            default { 0 };
        };

        _result = [
            15 + _targetOrderBonus + _targetTypeBonus + _freshnessBonus + _playerBonus + _localThreatBonus + ((_leashMeters - _holdDist) / 25),
            "GARRISON_OBJECTIVE",
            _leashMeters
        ];
    };
};

_result
