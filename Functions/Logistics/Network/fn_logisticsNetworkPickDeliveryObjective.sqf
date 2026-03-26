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
 *
 * Return Value:
 *   STRING - Delivery objective ID
 */

params ["_net", "_requestedObjectiveId"];

if (_requestedObjectiveId == "") exitWith { "" };

private _objectives = FLO_Objectives;
private _requestedObjective = _objectives get _requestedObjectiveId;
private _requestedPos = _requestedObjective get "position";
private _managedSide = _net get "_managedSide";
private _enemySide = _net get "_enemySide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
private _enemyCountKey = if (_managedSide isEqualTo east) then { "bluforCount" } else { "opforCount" };
private _requestedRole = [_net, _requestedObjectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;

if (
    (_requestedRole get "isAdvanceCandidate")
    && {!(_requestedObjective get "contested")}
    && {(_requestedObjective get _enemyCountKey) <= 0}
) exitWith {
    _requestedObjectiveId
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
if (count _candidateIds == 0) exitWith { _requestedObjectiveId };

private _enemyObjectiveIds = (keys _objectives) select {
    ((_objectives get _x) get "owner") isEqualTo _enemySide
};
if (count _enemyObjectiveIds == 0) exitWith { _requestedObjectiveId };

private _minEnemyDistance = _net get "REINFORCEMENT_DELIVERY_MIN_ENEMY_DISTANCE";
private _quietCandidates = [];
private _fallbackCandidates = [];

{
    private _candidateId = _x;
    private _candidateObjective = _objectives get _candidateId;
    private _candidatePos = _candidateObjective get "position";
    private _distToRequested = _candidatePos distance2D _requestedPos;
    private _friendlyCount = _candidateObjective get _friendlyCountKey;
    private _enemyCount = _candidateObjective get _enemyCountKey;
    private _priority = _candidateObjective get "priority";
    private _nearestEnemyDist = 1e12;

    {
        private _enemyPos = (_objectives get _x) get "position";
        private _dist = _candidatePos distance2D _enemyPos;
        if (_dist < _nearestEnemyDist) then {
            _nearestEnemyDist = _dist;
        };
    } forEach _enemyObjectiveIds;

    private _row = [_candidateId, _distToRequested, _nearestEnemyDist, _friendlyCount, _enemyCount, _priority];
    if (_enemyCount == 0 && {_nearestEnemyDist >= _minEnemyDistance}) then {
        _quietCandidates pushBack _row;
    } else {
        _fallbackCandidates pushBack _row;
    };
} forEach _candidateIds;

private _candidateRows = if (count _quietCandidates > 0) then { _quietCandidates } else { _fallbackCandidates };
if (count _candidateRows == 0) exitWith { _requestedObjectiveId };

private _bestObjectiveId = _requestedObjectiveId;
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

_bestObjectiveId
