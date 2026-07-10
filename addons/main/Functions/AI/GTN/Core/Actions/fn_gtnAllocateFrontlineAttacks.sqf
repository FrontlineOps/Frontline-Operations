/*
 * Function: FLO_fnc_gtnAllocateFrontlineAttacks
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Assigns available groups to the theater director's single active assault
 *   objective. No other frontline objective may receive an ATTACK order.
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
    ["remainingPool", 0],
    ["candidateBuildMs", 0],
    ["reserveBandMs", 0],
    ["signatureMs", 0],
    ["selectionMs", 0],
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
private _phase = _state get "phase";
private _objectiveId = _state get "objectiveId";
private _operationId = _state get "operationId";
_metrics set ["phase", toLower _phase];
_metrics set ["phaseObjective", _objectiveId];

if (_phase != "ASSAULT") exitWith { _metrics };
if ((_state get "attackerSideKey") != (_cmdr get "_sideKey")) exitWith { _metrics };
if (_objectiveId == "" || {_operationId == ""}) then {
    throw "FLO_fnc_gtnAllocateFrontlineAttacks: ASSAULT has no objective or operation id";
};
if !(_cmdr call ["_hasStrategicOrderBudget", []]) exitWith { _metrics };

private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _groups = FLO_virtualGroups get "_groups";
private _objectives = (_cmdr get "_worldState") call ["_getObjectives", []];
private _objective = _objectives get _objectiveId;
if ((_objective get "owner") != _enemySide) exitWith { _metrics };

private _tCandidateBuild = diag_tickTime;
private _attackCap = _cmdr call ["_getAttackCapForObjective", [_objectiveId]];
private _activeAttackCounts = (_cmdr get "_objectiveAssignmentCache") get "attackCounts";
private _attackGroupIds = (_cmdr get "_objectiveAssignmentCache") get "attackGroupIds";
private _activeAttackers = if (_objectiveId in _activeAttackCounts) then {
    _activeAttackCounts get _objectiveId
} else {
    0
};
private _deficit = (_attackCap - _activeAttackers) max 0;
private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
_metrics set ["candidateBuildMs", (diag_tickTime - _tCandidateBuild) * 1000];

if (_deficit <= 0 || {_sourceObjectives isEqualTo []}) exitWith { _metrics };
_metrics set ["candidateObjectives", 1];

private _idleStrategicOrders = ["PATROL", "DEFEND", ""];
private _poolEntries = [];
{
    private _gData = _groups get _x;
    if (isNil "_gData") then { continue };
    if !([_gData, _ownSide, ["infantry", "motorized", "mechanized", "armor"], _idleStrategicOrders] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then { continue };

    _poolEntries pushBack [
        _x,
        _gData get "homeObjective",
        _gData get "position"
    ];
} forEach _pool;

private _reserveGraphDepth = ((_cmdr get "_config") get "attackReserveGraphDepth");
private _tReserve = diag_tickTime;
private _reserveBands = [_cmdr, _sourceObjectives, _reserveGraphDepth] call FLO_fnc_gtnGetCachedReserveBands;
_metrics set ["reserveBandMs", (diag_tickTime - _tReserve) * 1000];
private _fallbackBand = _reserveGraphDepth + 1;
private _objectivePos = _objective get "position";
private _assignmentLimit = [_cmdr, "attackAssignmentsPerCycle"] call FLO_fnc_gtnGetTempoScaledAssignmentLimit;
private _stop = false;

while {!_stop && {_poolEntries isNotEqualTo []} && {_deficit > 0}} do {
    if ((_metrics get "assignedGroups") >= _assignmentLimit || {!(_cmdr call ["_hasStrategicOrderBudget", []])}) exitWith {
        _stop = true;
    };

    private _tSelection = diag_tickTime;
    private _bestIndex = -1;
    private _bestBand = 1e9;
    private _bestDistance = 1e12;

    for "_i" from 0 to ((count _poolEntries) - 1) do {
        (_poolEntries select _i) params ["_groupId", "_homeObjectiveId", "_groupPos"];
        private _band = _fallbackBand;
        if (_homeObjectiveId in _reserveBands) then {
            _band = _reserveBands get _homeObjectiveId;
        };
        private _distance = _groupPos distance2D _objectivePos;
        if (_band < _bestBand || {_band == _bestBand && {_distance < _bestDistance}}) then {
            _bestIndex = _i;
            _bestBand = _band;
            _bestDistance = _distance;
        };
    };
    _metrics set ["selectionMs", (_metrics get "selectionMs") + ((diag_tickTime - _tSelection) * 1000)];

    if (_bestIndex < 0) exitWith { _stop = true; };
    private _groupId = (_poolEntries select _bestIndex) select 0;

    private _tOrder = diag_tickTime;
    private _ordered = _cmdr call ["_orderGroupAttack", [_groupId, _objectivePos, _objectiveId, true, _operationId]];
    _metrics set ["orderMs", (_metrics get "orderMs") + ((diag_tickTime - _tOrder) * 1000)];
    _poolEntries deleteAt _bestIndex;

    if (_ordered) then {
        _deficit = _deficit - 1;
        _activeAttackers = _activeAttackers + 1;
        _activeAttackCounts set [_objectiveId, _activeAttackers];
        _attackGroupIds pushBackUnique _groupId;
        _metrics set ["assignedGroups", (_metrics get "assignedGroups") + 1];
    };
};

if ((_metrics get "assignedGroups") > 0) then {
    if (_activeAttackers > 0) then {
        _metrics set ["reinforcedObjectives", 1];
    } else {
        _metrics set ["openedObjectives", 1];
    };
};

_track set ["groupPool", _poolEntries apply { _x select 0 }];
_metrics set ["remainingPool", count (_track get "groupPool")];
_metrics set ["totalMs", (diag_tickTime - _tTotal) * 1000];

if ((_metrics get "totalMs") >= 20) then {
    diag_log format [
        "[FLO][PERF] GTN operation attack allocation %1 op=%2 objective=%3 pool=%4 assigned=%5 reserve=%6 select=%7 order=%8 total=%9",
        _cmdr get "_sideKey",
        _operationId,
        _objectiveId,
        _metrics get "poolCount",
        _metrics get "assignedGroups",
        _metrics get "reserveBandMs",
        _metrics get "selectionMs",
        _metrics get "orderMs",
        _metrics get "totalMs"
    ];
};

_metrics
