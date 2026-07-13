/*
 * Function: FLO_fnc_gtnAllocateFrontlineAttacks
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Assigns a track's available groups to its exact campaign operation.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Track <HASHMAP>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params ["_cmdr", "_track"];

private _metrics = createHashMapFromArray [
    ["phase", ""],
    ["phaseObjective", ""],
    ["poolCount", 0],
    ["candidateObjectives", 0],
    ["assignedGroups", 0],
    ["openedObjectives", 0],
    ["reinforcedObjectives", 0],
    ["startingAttackers", 0],
    ["replacementOrders", 0],
    ["preflightSkipped", false],
    ["remainingPool", 0],
    ["candidateBuildMs", 0],
    ["nearestSelectionMs", 0],
    ["orderMs", 0],
    ["totalMs", 0]
];

private _tTotal = diag_tickTime;
private _pool = +(_track get "groupPool");
_metrics set ["poolCount", count _pool];
_metrics set ["remainingPool", count _pool];
if (_pool isEqualTo []) exitWith { _metrics };

private _director = _cmdr get "_campaignDirector";
if (isNil "_director") then {
    throw "FLO_fnc_gtnAllocateFrontlineAttacks: commander has no campaign director";
};

private _state = _director call ["_getState", []];
private _operations = _state get "operations";
private _phase = _track get "phase";
private _objectiveId = _track get "phaseObjectiveId";
private _operationId = _track get "phaseOperationId";
_metrics set ["phase", _phase];
_metrics set ["phaseObjective", _objectiveId];

if (_phase != "assault") exitWith { _metrics };
if (_objectiveId == "" || {_operationId == ""}) then {
    throw "FLO_fnc_gtnAllocateFrontlineAttacks: ASSAULT has no objective or operation id";
};
if !(_operationId in _operations) then {
    throw format ["FLO_fnc_gtnAllocateFrontlineAttacks: track operation %1 is missing", _operationId];
};
private _operation = _operations get _operationId;
if (
    (_operation get "phase") != "ASSAULT"
    || {(_operation get "objectiveId") != _objectiveId}
    || {(_operation get "attackerSideKey") != (_cmdr get "_sideKey")}
) then {
    throw format ["FLO_fnc_gtnAllocateFrontlineAttacks: stale track binding %1/%2", _operationId, _objectiveId];
};
if !(_cmdr call ["_hasStrategicOrderBudget", []]) exitWith { _metrics };

private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _objectives = (_cmdr get "_worldState") call ["_getObjectives", []];
private _objective = _objectives get _objectiveId;
if ((_objective get "owner") != _enemySide) exitWith { _metrics };
if (([_objectiveId, _objective] call FLO_fnc_campaignResolveAssaultLandAnchor) isEqualTo []) exitWith {
    ["CAMPAIGN", 2, format [
        "Operation %1 withdrawing before dispatch: objective %2 has no ground-assault anchor",
        _operationId,
        _objectiveId
    ]] call FLO_fnc_log;
    _director call ["_completeOperation", [_operationId, "NO_TARGET", "NO_LAND_ASSAULT_ANCHOR"]];
    _track set ["groupPool", []];
    _metrics set ["preflightSkipped", true];
    _metrics set ["remainingPool", 0];
    _metrics set ["totalMs", (diag_tickTime - _tTotal) * 1000];
    _metrics
};

private _tCandidateBuild = diag_tickTime;
private _attackCap = _operation get "assaultActiveTarget";
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";
private _activeAttackCounts = _assignmentCache get "attackCounts";
private _attackCountsByOperation = _assignmentCache get "attackCountsByOperation";
private _attackGroupsByOperation = _assignmentCache get "attackGroupsByOperation";
private _attackGroupIds = _assignmentCache get "attackGroupIds";
private _activeAttackers = if (_operationId in _attackCountsByOperation) then {
    _attackCountsByOperation get _operationId
} else {
    0
};
private _startingAttackers = _activeAttackers;
_metrics set ["startingAttackers", _startingAttackers];
private _deficit = (_attackCap - _activeAttackers) max 0;
private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
_metrics set ["candidateBuildMs", (diag_tickTime - _tCandidateBuild) * 1000];

if (_deficit <= 0 || {_sourceObjectives isEqualTo []}) exitWith { _metrics };
_metrics set ["candidateObjectives", 1];

private _idleStrategicOrders = ["PATROL", "DEFEND", ""];
private _poolEntries = [];
{
    private _gData = _groups get _x;
    if (isNil "_gData") then {
        throw format ["FLO_fnc_gtnAllocateFrontlineAttacks: pool group %1 is missing", _x];
    };
    if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };

    _poolEntries pushBack _x;
} forEach _pool;

private _decision = _track get "assaultWaveDecision";
private _quota = _decision get "quota";
private _assignmentLimit = [_cmdr, "attackAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
private _strategicBudgetRemaining = _cmdr get "_strategicOrderBudgetRemaining";
if (
    _quota <= 0
    || {(count _poolEntries) < _quota}
    || {_assignmentLimit < _quota}
    || {_strategicBudgetRemaining < _quota}
) exitWith {
    _track set ["groupPool", []];
    _metrics set ["preflightSkipped", true];
    _metrics set ["remainingPool", 0];
    _metrics set ["totalMs", (diag_tickTime - _tTotal) * 1000];
    ["GTN", 3, format [
        "Operation %1 wave preflight held: quota=%2 eligible=%3 assignmentLimit=%4 strategicBudget=%5",
        _operationId,
        _quota,
        count _poolEntries,
        _assignmentLimit,
        _strategicBudgetRemaining
    ]] call FLO_fnc_log;
    _metrics
};

private _approachSourcePos = _track get "frontSectorAnchorPos";
private _approachRoutes = [
    _director,
    _objectiveId,
    _objective,
    _approachSourcePos,
    _poolEntries,
    _groups
] call FLO_fnc_campaignBuildAssaultApproachLanes;
private _stop = false;

while {!_stop && {_poolEntries isNotEqualTo []} && {_deficit > 0}} do {
    if ((_metrics get "assignedGroups") >= _assignmentLimit || {!(_cmdr call ["_hasStrategicOrderBudget", []])}) exitWith {
        _stop = true;
    };

    private _tSelection = diag_tickTime;
    private _groupId = _poolEntries deleteAt 0;
    _metrics set ["nearestSelectionMs", (_metrics get "nearestSelectionMs") + ((diag_tickTime - _tSelection) * 1000)];

    private _tOrder = diag_tickTime;
    private _approachRoute = _approachRoutes get _groupId;
    private _ordered = _cmdr call ["_orderGroupAttack", [_groupId, _approachRoute, _objectiveId, true, _operationId]];
    _metrics set ["orderMs", (_metrics get "orderMs") + ((diag_tickTime - _tOrder) * 1000)];

    if (_ordered) then {
        _deficit = _deficit - 1;
        _activeAttackers = _activeAttackers + 1;
        _activeAttackCounts set [_objectiveId, _activeAttackers];
        _attackCountsByOperation set [_operationId, _activeAttackers];
        private _operationGroups = if (_operationId in _attackGroupsByOperation) then {
            _attackGroupsByOperation get _operationId
        } else {
            []
        };
        _operationGroups pushBack _groupId;
        _attackGroupsByOperation set [_operationId, _operationGroups];
        _attackGroupIds pushBackUnique _groupId;
        _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
    };
};

if ((_metrics get "assignedGroups") > 0) then {
    private _openingComplete = !(_decision get "openingCommit") || {_activeAttackers >= _attackCap};
    [_director, _operationId, _metrics get "assignedGroups", _openingComplete] call FLO_fnc_campaignCommitAssaultWave;
    if (_startingAttackers > 0) then {
        _metrics set ["reinforcedObjectives", 1];
        _metrics set ["replacementOrders", _metrics get "assignedGroups"];
    } else {
        _metrics set ["openedObjectives", 1];
    };
};

_track set ["groupPool", _poolEntries];
_metrics set ["remainingPool", count (_track get "groupPool")];
_metrics set ["totalMs", (diag_tickTime - _tTotal) * 1000];

if ((_metrics get "totalMs") >= 20) then {
    diag_log format [
        "[FLO][PERF] GTN operation attack allocation %1 op=%2 objective=%3 pool=%4 assigned=%5 nearest=%6 order=%7 total=%8",
        _cmdr get "_sideKey",
        _operationId,
        _objectiveId,
        _metrics get "poolCount",
        _metrics get "assignedGroups",
        _metrics get "nearestSelectionMs",
        _metrics get "orderMs",
        _metrics get "totalMs"
    ];
};

_metrics
