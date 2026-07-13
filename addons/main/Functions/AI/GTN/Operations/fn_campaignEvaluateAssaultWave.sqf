/* Updates one operation's progress/loss ledger and returns the next wave quota. */
params [
    "_director",
    "_cmdr",
    ["_operationId", "", [""]],
    ["_activeGroupIds", [], [[]]]
];

private _decision = createHashMapFromArray [
    ["quota", 0],
    ["activeCount", 0],
    ["activeTarget", 0],
    ["packageTarget", 0],
    ["committedTotal", 0],
    ["remainingPackage", 0],
    ["losses", 0],
    ["lossRatio", 0],
    ["arrivedCount", 0],
    ["nearestDistance", -1],
    ["defenderCount", 0],
    ["openingCommit", false],
    ["openingTimeoutSeconds", 0],
    ["status", "INACTIVE"],
    ["culminated", false]
];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
if ((_operation get "phase") != "ASSAULT") then {
    throw format ["Cannot evaluate ASSAULT wave for %1 in phase %2", _operationId, _operation get "phase"];
};
if ((_operation get "assaultPackageTarget") <= 0) then {
    _operation = [_director, _operationId] call FLO_fnc_campaignInitializeAssaultState;
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _objectiveId = _operation get "objectiveId";
private _worldObjectives = ((_cmdr get "_worldState") call ["_getObjectives", []]);
private _objective = _worldObjectives get _objectiveId;
private _targetPos = _objective get "position";
private _targetRadius = _objective get "radius";
private _activeCount = 0;
private _arrivedCount = 0;
private _nearestDistance = 1e12;

{
    private _groupData = _groups get _x;
    if ((_groupData get "commanderOrder") != "ATTACK") then {
        throw format ["Operation %1 cache contains non-ATTACK group %2", _operationId, _x];
    };
    if ((_groupData get "campaignOperationId") != _operationId) then {
        throw format ["Operation %1 cache contains foreign group %2", _operationId, _x];
    };

    _activeCount = _activeCount + 1;
    private _distance = (_groupData get "position") distance2D _targetPos;
    _nearestDistance = _nearestDistance min _distance;
    if (_distance <= _targetRadius) then {
        _arrivedCount = _arrivedCount + 1;
    };
} forEach _activeGroupIds;

private _packageTarget = (_operation get "assaultPackageTarget") max _activeCount;
private _activeTarget = _operation get "assaultActiveTarget";
private _committed = (_operation get "assaultCommittedTotal") max _activeCount;
_operation set ["assaultPackageTarget", _packageTarget];
_operation set ["assaultCommittedTotal", _committed];

private _losses = (_committed - _activeCount) max 0;
private _lossRatio = _losses / (_packageTarget max 1);
private _defenderCount = [
    _objective get "enemyCount",
    _objective get "friendlyCount"
] select ((_objective get "owner") == (_cmdr get "_enemySide"));
private _contested = _objective get "contested";
private _now = dateToNumber date;
private _madeProgress = false;

private _lastProgressAt = _operation get "assaultLastProgressAtDateNum";
if (_lastProgressAt < 0) then {
    _lastProgressAt = _now;
    _operation set ["assaultLastProgressAtDateNum", _now];
};
private _bestDistance = _operation get "assaultBestDistance";
if (_activeCount > 0 && {_nearestDistance <= (_bestDistance - 250)}) then {
    _madeProgress = true;
};
if (_arrivedCount > (_operation get "assaultLastArrivedCount")) then {
    _madeProgress = true;
};
private _lastDefenderCount = _operation get "assaultLastEnemyCount";
if (_lastDefenderCount >= 0 && {_defenderCount < _lastDefenderCount}) then {
    _madeProgress = true;
};
if (_contested && {!(_operation get "assaultLastContested")}) then {
    _madeProgress = true;
};

if (_activeCount > 0) then {
    _operation set ["assaultBestDistance", _bestDistance min _nearestDistance];
};
_operation set ["assaultLastArrivedCount", _arrivedCount];
_operation set ["assaultLastEnemyCount", _defenderCount];
_operation set ["assaultLastContested", _contested];
_operation set ["assaultLosses", _losses];
if (_madeProgress) then {
    _lastProgressAt = _now;
    _operation set ["assaultLastProgressAtDateNum", _now];
    _operation set ["assaultPauseUntilDateNum", -1];
    _operation set ["assaultPauseCount", 0];
    _operation set ["assaultStatus", "ADVANCING"];
};

private _config = _director get "_config";
private _noProgressSeconds = [_lastProgressAt, _now] call FLO_fnc_dateNumberDeltaSeconds;
private _remainingPackage = (_packageTarget - _committed) max 0;
private _openingCommit = (_operation get "assaultWaveSequence") == 0;
private _openingTimeoutSeconds = (_config get "assaultOpeningCommitMinimumSeconds") max (
    (_cmdr get "_updateInterval") * ((_config get "operationMaximumCount") + 1)
);

_decision set ["activeCount", _activeCount];
_decision set ["activeTarget", _activeTarget];
_decision set ["packageTarget", _packageTarget];
_decision set ["committedTotal", _committed];
_decision set ["remainingPackage", _remainingPackage];
_decision set ["losses", _losses];
_decision set ["lossRatio", _lossRatio];
_decision set ["arrivedCount", _arrivedCount];
_decision set ["nearestDistance", [-1, round _nearestDistance] select (_activeCount > 0)];
_decision set ["defenderCount", _defenderCount];
_decision set ["openingCommit", _openingCommit];
_decision set ["openingTimeoutSeconds", _openingTimeoutSeconds];

if ((_objective get "owner") == (_cmdr get "_ownSide")) exitWith {
    _operation set ["assaultStatus", "OBJECTIVE_SECURED"];
    _decision set ["status", "OBJECTIVE_SECURED"];
    _decision
};

private _openingEligibleAt = _operation get "assaultOpeningEligibleAtDateNum";
if (_openingEligibleAt < 0) then {
    throw format ["Operation %1 has no ASSAULT opening eligibility time", _operationId];
};
private _openingDelayRemaining = [_now, _openingEligibleAt] call FLO_fnc_dateNumberDeltaSeconds;
if (_openingCommit && {_openingDelayRemaining > 0}) exitWith {
    _operation set ["assaultStatus", "SHAPING"];
    _decision set ["status", "SHAPING"];
    _decision
};

private _openingElapsedSeconds = [_openingEligibleAt, _now] call FLO_fnc_dateNumberDeltaSeconds;
if (
    _openingCommit
    && {_activeCount < _activeTarget}
    && {_openingElapsedSeconds >= _openingTimeoutSeconds}
) exitWith {
    _operation set ["assaultStatus", "CULMINATED"];
    _decision set ["status", "CULMINATED"];
    _decision set ["culminated", true];
    _director call ["_completeOperation", [_operationId, "ATTACKER_FAILED", "ASSAULT_OPENING_MASS_FAILED"]];
    ["CAMPAIGN", 2, format [
        "Operation %1 opening mass failed: active=%2 target=%3 committed=%4 elapsed=%5s limit=%6s",
        _operationId,
        _activeCount,
        _activeTarget,
        _committed,
        round _openingElapsedSeconds,
        round _openingTimeoutSeconds
    ]] call FLO_fnc_log;
    _decision
};

private _culminationReason = "";
if (_committed >= _packageTarget && {_activeCount == 0}) then {
    _culminationReason = "PACKAGE_EXHAUSTED";
};
if (
    _culminationReason == ""
    && {_lossRatio >= (_config get "assaultLossCulminationRatio")}
    && {_noProgressSeconds >= (_config get "assaultNoProgressSeconds")}
) then {
    _culminationReason = "LOSS_LIMIT";
};

private _pauseUntil = _operation get "assaultPauseUntilDateNum";
private _pauseRemaining = if (_pauseUntil < 0) then { 0 } else {
    [_now, _pauseUntil] call FLO_fnc_dateNumberDeltaSeconds
};
if (
    _culminationReason == ""
    && {(_operation get "assaultPauseCount") > 0}
    && {_pauseRemaining <= 0}
    && {_noProgressSeconds >= ((_config get "assaultNoProgressSeconds") + (_config get "assaultReorganizationSeconds"))}
) then {
    _culminationReason = "REORGANIZATION_FAILED";
};

if (_culminationReason != "") exitWith {
    _operation set ["assaultStatus", "CULMINATED"];
    _decision set ["status", "CULMINATED"];
    _decision set ["culminated", true];
    _director call ["_completeOperation", [_operationId, "ATTACKER_FAILED", "ASSAULT_CULMINATED"]];
    ["CAMPAIGN", 2, format [
        "Operation %1 culminated (%2): committed=%3 active=%4 losses=%5 ratio=%6 noProgress=%7s",
        _operationId,
        _culminationReason,
        _committed,
        _activeCount,
        _losses,
        _lossRatio,
        round _noProgressSeconds
    ]] call FLO_fnc_log;
    _decision
};

if (_pauseRemaining > 0) exitWith {
    _operation set ["assaultStatus", "REORGANIZING"];
    _decision set ["status", "REORGANIZING"];
    _decision
};

if (
    _lossRatio >= (_config get "assaultLossPauseRatio")
    && {_noProgressSeconds >= (_config get "assaultNoProgressSeconds")}
    && {(_operation get "assaultPauseCount") == 0}
) exitWith {
    _operation set ["assaultPauseCount", 1];
    _operation set [
        "assaultPauseUntilDateNum",
        [_now, _config get "assaultReorganizationSeconds"] call FLO_fnc_dateNumberAddSeconds
    ];
    _operation set ["assaultStatus", "REORGANIZING"];
    _decision set ["status", "REORGANIZING"];
    ["CAMPAIGN", 2, format [
        "Operation %1 paused after %2/%3 package losses without progress",
        _operationId,
        _losses,
        _packageTarget
    ]] call FLO_fnc_log;
    _decision
};

private _nextWaveAt = _operation get "assaultNextWaveAtDateNum";
private _waveCooldownRemaining = [_now, _nextWaveAt] call FLO_fnc_dateNumberDeltaSeconds;
private _activeDeficit = (_activeTarget - _activeCount) max 0;
if (_remainingPackage <= 0 || {_activeDeficit <= 0} || {_waveCooldownRemaining > 0}) exitWith {
    private _status = ["ENGAGED", "PACKAGE_COMMITTED"] select (_remainingPackage <= 0);
    _operation set ["assaultStatus", _status];
    _decision set ["status", _status];
    _decision
};

private _quota = if (_openingCommit) then {
    _activeDeficit min _remainingPackage
} else {
    (_operation get "assaultWaveSize") min _activeDeficit min _remainingPackage
};
_operation set ["assaultStatus", "WAVE_READY"];
_decision set ["quota", _quota];
_decision set ["status", "WAVE_READY"];
[_operation] call FLO_fnc_campaignValidateAssaultState;
_decision
