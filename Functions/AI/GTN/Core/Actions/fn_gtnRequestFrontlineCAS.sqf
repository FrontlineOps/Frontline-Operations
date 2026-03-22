/*
 * Function: FLO_fnc_gtnRequestFrontlineCAS
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Requests one opportunistic CAS mission for the best-supported active
 *   frontline attack objective. Uses maintained GTN state, objective analysis,
 *   and per-objective locks to avoid air spam.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAP>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["assetAvailable", false],
    ["candidateCount", 0],
    ["eligibleCount", 0],
    ["lockedCount", 0],
    ["requestedCount", 0],
    ["selectedObjective", ""],
    ["selectedScore", 0]
];

if (isNil "_cmdr") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
if !(_ws call ["_isAssetAvailable", ["cas"]]) exitWith { _metrics };
_metrics set ["assetAvailable", true];

private _frontlineObjectives = _ws call ["_getFrontlineEnemyObjectives", []];
if ((count (keys _frontlineObjectives)) == 0) exitWith { _metrics };

private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _cmdr get "_ownSide";
private _activeAttackCounts = createHashMap;

{
    private _gData = _y;
    if ((_gData get "side") != _ownSide) then { continue };
    if ((_gData get "currentOrder") != "ATTACK") then { continue };

    private _attackObjective = _gData get "attackObjective";
    if (_attackObjective == "") then { continue };

    private _activeAttackCount = if (_attackObjective in _activeAttackCounts) then {
        _activeAttackCounts get _attackObjective
    } else {
        0
    };
    _activeAttackCounts set [_attackObjective, _activeAttackCount + 1];
} forEach _groups;

if ((count (keys _activeAttackCounts)) == 0) exitWith { _metrics };

private _locks = _cmdr get "_frontlineCASLocks";
private _lockSeconds = ((_cmdr get "_config") get "frontlineCASObjectiveLockSeconds");
private _minAttackers = ((_cmdr get "_config") get "frontlineCASMinAttackers");
private _minScore = ((_cmdr get "_config") get "frontlineCASMinScore");

private _expiredLocks = [];
{
    private _objectiveId = _x;
    private _lockedUntil = _locks get _objectiveId;
    if (_lockedUntil <= diag_tickTime || !(_objectiveId in _frontlineObjectives)) then {
        _expiredLocks pushBack _objectiveId;
    };
} forEach (keys _locks);
{ _locks deleteAt _x; } forEach _expiredLocks;

private _bestObjectiveId = "";
private _bestObjectivePos = [];
private _bestScore = -1e12;

{
    private _objectiveId = _x;
    _metrics set ["candidateCount", (_metrics get "candidateCount") + 1];

    if !(_objectiveId in _activeAttackCounts) then { continue };

    private _activeAttackers = _activeAttackCounts get _objectiveId;
    if (_activeAttackers < _minAttackers) then { continue };

    if (_objectiveId in _locks) then {
        _metrics set ["lockedCount", (_metrics get "lockedCount") + 1];
        continue;
    };

    private _objective = _frontlineObjectives get _objectiveId;
    private _analysis = _ws call ["_getObjectiveAnalysis", [_objectiveId]];
    if (isNil "_analysis") then { continue };

    _metrics set ["eligibleCount", (_metrics get "eligibleCount") + 1];

    private _priority = _objective get "priority";
    private _attackCap = _cmdr call ["_getAttackCapForObjective", [_objectiveId]];
    private _casPressure = _analysis get "totalDefensePower";
    private _score = (_activeAttackers * 18) + (_priority * 0.5) + (_casPressure / 40);

    if ((_objective get "contested")) then {
        _score = _score + 20;
    };

    if ((_analysis get "hasArmor")) then {
        _score = _score + 40;
    };

    if ((_analysis get "hasAA")) then {
        _score = _score - 15;
    };

    if (_attackCap > 0) then {
        _score = _score + (linearConversion [_minAttackers, _attackCap max _minAttackers, _activeAttackers, 0, 20, true]);
    };

    if (_score > _bestScore) then {
        _bestObjectiveId = _objectiveId;
        _bestObjectivePos = _objective get "position";
        _bestScore = _score;
    };
} forEach (keys _frontlineObjectives);

if (_bestObjectiveId == "" || {_bestScore < _minScore}) exitWith { _metrics };

private _success = _cmdr call ["_requestCAS", [_bestObjectivePos, "CAS"]];
if (_success) then {
    _locks set [_bestObjectiveId, diag_tickTime + _lockSeconds];
    _metrics set ["requestedCount", 1];
    _metrics set ["selectedObjective", _bestObjectiveId];
    _metrics set ["selectedScore", _bestScore];

    ["GTN", 3, format[
        "Frontline CAS requested for %1 (score=%2, attackers=%3)",
        _bestObjectiveId,
        round _bestScore,
        _activeAttackCounts get _bestObjectiveId
    ]] call FLO_fnc_log;
};

_metrics
