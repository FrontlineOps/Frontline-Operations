/*
 * Function: FLO_fnc_logisticsNetworkPickDeliveryObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Chooses a friendly staging objective for a pressured sector so maneuver
 *   reinforcements are delivered near the front instead of directly into the
 *   hottest contested objective.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Requested objective ID <STRING>
 *   2: Required Local Supplies <NUMBER>
 *   3: Objective IDs that cannot act as sources <ARRAY>
 *
 * Return Value:
 *   STRING - Delivery objective ID
 */

params [
    "_net",
    "_requestedObjectiveId",
    ["_requiredThroughput", 0, [0]],
    ["_blockedObjectives", [], [[]]]
];

if (_requestedObjectiveId == "") exitWith { "" };

private _deliveryCache = _net get "_dispatchDeliveryObjectiveCache";
private _sortedBlocked = +_blockedObjectives;
_sortedBlocked sort true;
private _cacheKey = format ["%1:%2:%3", _requestedObjectiveId, _requiredThroughput, _sortedBlocked joinString ","];
if (_cacheKey in _deliveryCache) exitWith { _deliveryCache get _cacheKey };

private _objectives = FLO_Objectives;
private _requestedObjective = _objectives get _requestedObjectiveId;
private _requestedPos = _requestedObjective get "position";
private _managedSide = _net get "_managedSide";
private _enemySide = _net get "_enemySide";
private _friendlyCountKey = ["bluforCount", "opforCount"] select (_managedSide isEqualTo east);
private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);
private _sourceableCache = _net get "_dispatchSourceableCache";
private _requestedSourceKey = format ["%1:%2:%3", _requestedObjectiveId, _requiredThroughput, _sortedBlocked joinString ","];
private _requestedCanSource = if (_requestedSourceKey in _sourceableCache) then {
    _sourceableCache get _requestedSourceKey
} else {
    private _canSource = (
        [_net, _requestedObjectiveId, _blockedObjectives, _requiredThroughput]
        call FLO_fnc_logisticsNetworkFindSupplySourceObjective
    ) != "";
    _sourceableCache set [_requestedSourceKey, _canSource];
    _canSource
};

private _candidateIds = [];
{
    private _linkedId = _x;
    private _linkedObjective = _objectives get _linkedId;
    if ((_linkedObjective get "owner") isEqualTo _managedSide && {!(_linkedId in _candidateIds)}) then {
        _candidateIds pushBack _linkedId;
    };
} forEach (_requestedObjective get "linkedObjectives");

{
    private _linkedObjective = _objectives get _x;
    {
        private _secondHopId = _x;
        if (_secondHopId == _requestedObjectiveId) then { continue };

        private _secondHopObjective = _objectives get _secondHopId;
        if ((_secondHopObjective get "owner") isEqualTo _managedSide && {!(_secondHopId in _candidateIds)}) then {
            _candidateIds pushBack _secondHopId;
        };
    } forEach (_linkedObjective get "linkedObjectives");
} forEach (_requestedObjective get "linkedObjectives");

_candidateIds = _candidateIds - [_requestedObjectiveId];
_candidateIds = _candidateIds select {
    private _sourceKey = format ["%1:%2:%3", _x, _requiredThroughput, _sortedBlocked joinString ","];
    if (_sourceKey in _sourceableCache) then {
        _sourceableCache get _sourceKey
    } else {
        private _canSource = (
            [_net, _x, _blockedObjectives, _requiredThroughput]
            call FLO_fnc_logisticsNetworkFindSupplySourceObjective
        ) != "";
        _sourceableCache set [_sourceKey, _canSource];
        _canSource
    }
};
if (_candidateIds isEqualTo []) exitWith {
    private _fallbackObjectiveId = ["", _requestedObjectiveId] select (_requestedCanSource);
    _deliveryCache set [_cacheKey, _fallbackObjectiveId];
    _fallbackObjectiveId
};

private _enemyObjectiveIds = (keys _objectives) select {
    ((_objectives get _x) get "owner") isEqualTo _enemySide
};
if (_enemyObjectiveIds isEqualTo []) exitWith {
    private _fallbackObjectiveId = if (_requestedCanSource) then {
        _requestedObjectiveId
    } else {
        _candidateIds select 0
    };
    _deliveryCache set [_cacheKey, _fallbackObjectiveId];
    _fallbackObjectiveId
};

private _minEnemyDistance = _net get "REINFORCEMENT_DELIVERY_MIN_ENEMY_DISTANCE";
private _quietCandidates = [];
private _fallbackCandidates = [];
private _enemyDistanceCache = _net get "_dispatchEnemyDistanceCache";

{
    private _candidateId = _x;
    private _candidateObjective = _objectives get _candidateId;
    private _candidatePos = _candidateObjective get "position";
    private _distToRequested = _candidatePos distance2D _requestedPos;
    private _friendlyCount = _candidateObjective get _friendlyCountKey;
    private _enemyCount = _candidateObjective get _enemyCountKey;
    private _priority = _candidateObjective get "priority";
    private _nearestEnemyDist = if (_candidateId in _enemyDistanceCache) then {
        _enemyDistanceCache get _candidateId
    } else {
        private _resolvedDist = 1e12;
        {
            private _enemyPos = (_objectives get _x) get "position";
            private _dist = _candidatePos distance2D _enemyPos;
            if (_dist < _resolvedDist) then {
                _resolvedDist = _dist;
            };
        } forEach _enemyObjectiveIds;
        _enemyDistanceCache set [_candidateId, _resolvedDist];
        _resolvedDist
    };

    private _row = [_candidateId, _distToRequested, _nearestEnemyDist, _friendlyCount, _enemyCount, _priority];
    if (_enemyCount == 0 && {_nearestEnemyDist >= _minEnemyDistance}) then {
        _quietCandidates pushBack _row;
    } else {
        _fallbackCandidates pushBack _row;
    };
} forEach _candidateIds;

private _candidateRows = [_fallbackCandidates, _quietCandidates] select (_quietCandidates isNotEqualTo []);
if (_candidateRows isEqualTo []) exitWith {
    private _fallbackObjectiveId = if (_requestedCanSource) then {
        _requestedObjectiveId
    } else {
        _candidateIds select 0
    };
    _deliveryCache set [_cacheKey, _fallbackObjectiveId];
    _fallbackObjectiveId
};

private _bestObjectiveId = if (_requestedCanSource) then { _requestedObjectiveId } else { _candidateIds select 0 };
private _bestScore = -1e12;

{
    _x params ["_candidateId", "_distToRequested", "_nearestEnemyDist", "_friendlyCount", "_enemyCount", "_priority"];

    private _score = (5000 - (_distToRequested min 5000))
        + ((_nearestEnemyDist min 3500) * 0.25)
        - (_friendlyCount * 35)
        - (_enemyCount * 450)
        + (_priority * 15);

    if (_score > _bestScore) then {
        _bestScore = _score;
        _bestObjectiveId = _candidateId;
    };
} forEach _candidateRows;

_deliveryCache set [_cacheKey, _bestObjectiveId];

_bestObjectiveId
