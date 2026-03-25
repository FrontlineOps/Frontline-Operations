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
 * HASHMAP - Empty when invalid, otherwise contains:
 *   "score", "reason", "leashMeters"
 */

params ["_groupData", "_targetData", "_config"];

private _result = createHashMap;
private _order = _groupData get "commanderOrder";
if !(_order in ["ATTACK", "DEFEND", "GARRISON"]) exitWith { _result };

private _targetPos = _targetData get "position";
if (count _targetPos < 2) exitWith { _result };

private _targetOrder = _targetData get "commanderOrder";
private _targetType = _targetData get "groupType";
private _objectiveIds = _targetData get "objectiveIds";
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

switch (_order) do {
    case "ATTACK": {
        private _groupPos = _groupData get "position";
        private _directDist = _groupPos distance2D _targetPos;
        private _searchRadius = _config get "attackEngagementSearchRadius";
        private _corridorRadius = _config get "attackEngagementCorridorRadius";
        private _attackObjective = _groupData get "attackObjective";
        private _inAttackObjective = _attackObjective != "" && {_attackObjective in _objectiveIds};

        private _routePoints = [+_groupPos];
        private _waypoints = _groupData get "waypoints";
        private _currentWaypointIndex = (_groupData get "currentWaypointIndex") max 0;
        if (_currentWaypointIndex < count _waypoints) then {
            private _lastWaypointIndex = ((count _waypoints) - 1) min (_currentWaypointIndex + 4);
            for "_i" from _currentWaypointIndex to _lastWaypointIndex do {
                _routePoints pushBack (((_waypoints select _i) select 0));
            };
        };

        if (count _routePoints < 2) then {
            private _orderTargetPos = _groupData get "orderTargetPos";
            if (count _orderTargetPos >= 2) then {
                _routePoints pushBack _orderTargetPos;
            };
        };

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

        if (_directDist > _searchRadius && {!_inAttackObjective} && {_routeDist > _corridorRadius}) exitWith { _result };

        private _proximityScore = ((_searchRadius - (_directDist min _searchRadius)) / 45) + ((_corridorRadius - (_routeDist min _corridorRadius)) / 25);
        private _objectiveBonus = if (_inAttackObjective) then { 28 } else { 0 };
        private _reason = if (_inAttackObjective) then {
            "ATTACK_OBJECTIVE"
        } else {
            if (_routeDist <= _corridorRadius) then { "ATTACK_ROUTE" } else { "ATTACK_LOCAL" };
        };

        _result = createHashMapFromArray [
            ["score", 20 + _targetOrderBonus + _targetTypeBonus + _freshnessBonus + _objectiveBonus + _proximityScore + ((_targetData get "contactCount") * 3)],
            ["reason", _reason],
            ["leashMeters", _config get "attackEngagementLeashMeters"]
        ];
    };

    case "DEFEND": {
        private _objectiveId = _groupData get "defendObjective";
        if (_objectiveId == "" || {!(_objectiveId in _objectiveIds)}) exitWith { _result };

        private _holdPos = _groupData get "orderTargetPos";
        if (count _holdPos < 2) then {
            _holdPos = _groupData get "position";
        };

        private _leashMeters = _config get "defenseEngagementLeashMeters";
        private _holdDist = _holdPos distance2D _targetPos;
        if (_holdDist > _leashMeters) exitWith { _result };

        private _localThreatBonus = switch (_targetOrder) do {
            case "ATTACK": { 18 };
            case "MOVE": { 12 };
            default { 0 };
        };

        _result = createHashMapFromArray [
            ["score", 15 + _targetOrderBonus + _targetTypeBonus + _freshnessBonus + _localThreatBonus + ((_leashMeters - _holdDist) / 25)],
            ["reason", "DEFEND_OBJECTIVE"],
            ["leashMeters", _leashMeters]
        ];
    };

    case "GARRISON": {
        private _objectiveId = _groupData get "garrisonObjective";
        if (_objectiveId == "" || {!(_objectiveId in _objectiveIds)}) exitWith { _result };

        private _holdPos = _groupData get "garrisonPosition";
        if (count _holdPos < 2) then {
            _holdPos = _groupData get "position";
        };

        private _leashMeters = _config get "garrisonEngagementLeashMeters";
        private _holdDist = _holdPos distance2D _targetPos;
        if (_holdDist > _leashMeters) exitWith { _result };

        private _localThreatBonus = switch (_targetOrder) do {
            case "ATTACK": { 18 };
            case "MOVE": { 12 };
            default { 0 };
        };

        _result = createHashMapFromArray [
            ["score", 15 + _targetOrderBonus + _targetTypeBonus + _freshnessBonus + _localThreatBonus + ((_leashMeters - _holdDist) / 25)],
            ["reason", "GARRISON_OBJECTIVE"],
            ["leashMeters", _leashMeters]
        ];
    };
};

_result
