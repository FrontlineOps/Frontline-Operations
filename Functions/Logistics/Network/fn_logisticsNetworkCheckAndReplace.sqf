/*
 * Function: FLO_fnc_logisticsNetworkCheckAndReplace
 * Author: Frontline Operations Development Group
 * Description:
 *   Reconciles current force composition against the saved baseline and
 *   dispatches replacement reinforcements when resources and objectives allow.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   None
 */

params ["_net"];

private _perf = createHashMapFromArray [
    ["neededCount", 0],
    ["queueBefore", 0],
    ["queueAfter", 0],
    ["collapseTargetCount", 0],
    ["frontlinePressureTargetCount", 0],
    ["targetCount", 0],
    ["advanceTargetCount", 0],
    ["hqObjective", ""],
    ["supplyNodeCount", 0],
    ["batchSize", 0],
    ["attempted", 0],
    ["created", 0],
    ["failNoTargetPool", 0],
    ["failCantAfford", 0],
    ["failNoTargetObj", 0],
    ["failSaturatedTarget", 0],
    ["failNoDeliveryObjective", 0],
    ["failNoSpawnPos", 0],
    ["failSpendResources", 0],
    ["failCreateReplacement", 0],
    ["resourcesBefore", 0],
    ["resourcesAfter", 0],
    ["refreshMs", 0],
    ["compositionMs", 0],
    ["reserveMs", 0],
    ["reserveGroundMissing", 0],
    ["reserveAirMissing", 0],
    ["reserveGroundCreated", 0],
    ["reserveAirCreated", 0],
    ["reconcileMs", 0],
    ["targetMs", 0],
    ["dispatchMs", 0],
    ["dispatchTargetPickMs", 0],
    ["dispatchDeliveryPickMs", 0],
    ["dispatchSpawnMs", 0],
    ["dispatchSpendMs", 0],
    ["dispatchCreateMs", 0],
    ["dispatchBookkeepingMs", 0],
    ["dispatchCreateGroupMs", 0],
    ["dispatchCreateTransitMs", 0],
    ["dispatchCreateOrganicMs", 0],
    ["dispatchCreateWaypointMs", 0],
    ["status", "RUN"]
];

private _phaseT0 = diag_tickTime;
[_net] call FLO_fnc_logisticsNetworkRefreshManagedSide;
private _activeSupplyNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
_net set ["_dispatchRoleCache", createHashMap];
_net set ["_dispatchBranchCache", createHashMap];
_net set ["_dispatchEnemyDistanceCache", createHashMap];
_net set ["_dispatchSourceableCache", createHashMap];
_net set ["_dispatchDeliveryObjectiveCache", createHashMap];
_perf set ["refreshMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["hqObjective", _net get "_hqObjectiveId"];
_perf set ["supplyNodeCount", count (keys _activeSupplyNodes)];

_phaseT0 = diag_tickTime;
private _initialComp = _net get "_initialComposition";
private _currentComp = [_net] call FLO_fnc_logisticsNetworkGetComposition;
private _groupCosts = _net get "GROUP_COSTS";
private _neededCounts = createHashMap;
private _neededTotal = 0;
{
    private _type = _x;
    private _target = _initialComp get _type;
    private _current = _currentComp getOrDefault [_type, 0];

    if (_current < _target) then {
        private _missing = _target - _current;
        _neededCounts set [_type, _missing];
        _neededTotal = _neededTotal + _missing;
    };
} forEach (keys _initialComp);
_perf set ["compositionMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["neededCount", _neededTotal];

_phaseT0 = diag_tickTime;
private _reserveStats = [_net] call FLO_fnc_logisticsNetworkReplenishTransportReserves;
_perf set ["reserveMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["reserveGroundMissing", _reserveStats get "groundMissing"];
_perf set ["reserveAirMissing", _reserveStats get "airMissing"];
_perf set ["reserveGroundCreated", _reserveStats get "groundCreated"];
_perf set ["reserveAirCreated", _reserveStats get "airCreated"];

if (_neededTotal == 0) exitWith {
    _perf set ["status", "AT_TARGET"];
    _net set ["_lastPerf", _perf];
    ["LOGISTICS", 3, "All group types at target strength"] call FLO_fnc_log;
};

private _queue = _net get "_reinforcementQueue";
_perf set ["queueBefore", count _queue];

_phaseT0 = diag_tickTime;
private _rebuiltQueue = [];
{
    private _remain = _neededCounts getOrDefault [_x, 0];
    if (_remain > 0) then {
        _rebuiltQueue pushBack _x;
        _neededCounts set [_x, _remain - 1];
    };
} forEach _queue;

{
    private _type = _x;
    private _missingCount = _neededCounts get _type;
    for "_i" from 1 to _missingCount do {
        _rebuiltQueue pushBack _type;
    };
} forEach (keys _neededCounts);

_queue = _rebuiltQueue;
_net set ["_reinforcementQueue", _queue];
_perf set ["reconcileMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["queueAfter", count _queue];

if (count _queue == 0) exitWith {
    _perf set ["status", "QUEUE_EMPTY"];
    _net set ["_lastPerf", _perf];
    ["LOGISTICS", 3, "No pending reinforcements after queue reconciliation"] call FLO_fnc_log;
};

private _nextDispatchAt = _net get "_nextDispatchAt";
if (time < _nextDispatchAt) exitWith {
    _perf set ["status", "WAITING"];
    _net set ["_lastPerf", _perf];
    ["LOGISTICS", 3, format [
        "Reinforcement queue pending: %1 groups | next dispatch in %2s",
        count _queue,
        round (_nextDispatchAt - time)
    ]] call FLO_fnc_log;
    _net set ["_lastUpdate", time];
};

_phaseT0 = diag_tickTime;
private _resources = FLO_SideResources get (_net get "_managedSideKey");
_perf set ["resourcesBefore", _resources call ["getResources", []]];
private _pressureTargets = [_net] call FLO_fnc_logisticsNetworkFindReinforcementTargets;
private _advanceTargets = [_net] call FLO_fnc_logisticsNetworkFindSupplyAdvanceObjectives;
private _rearTargets = [_net, 3000] call FLO_fnc_logisticsNetworkFindRearObjectives;
private _collapseTargetCount = {
    [_net, _x] call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure
} count _pressureTargets;
private _frontlinePressureTargetCount = {
    !([_net, _x] call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure)
    && {[_net, _x] call FLO_fnc_logisticsNetworkObjectiveIsFrontlinePressure}
} count _pressureTargets;
private _maneuverTargets = +_pressureTargets;
{
    if !(_x in _maneuverTargets) then {
        _maneuverTargets pushBack _x;
    };
} forEach _advanceTargets;

if (_collapseTargetCount > 0) then {
    ["LOGISTICS", 3, format [
        "Queue dispatch: collapse pressure overriding supply advance (%1 collapse, %2 advance, %3 pending)",
        _collapseTargetCount,
        count _advanceTargets,
        count _queue
    ]] call FLO_fnc_log;
} else {
    if (_frontlinePressureTargetCount > 0) then {
        ["LOGISTICS", 3, format [
            "Queue dispatch: frontline pressure overriding supply advance (%1 frontline, %2 advance, %3 background pressure, %4 pending)",
            _frontlinePressureTargetCount,
            count _advanceTargets,
            (count _pressureTargets) - _collapseTargetCount - _frontlinePressureTargetCount,
            count _queue
        ]] call FLO_fnc_log;
    } else {
        if (count _advanceTargets > 0) then {
        ["LOGISTICS", 3, format [
            "Queue dispatch: prioritizing supply-chain advance (%1 advance, %2 non-critical pressure, %3 pending)",
            count _advanceTargets,
            (count _pressureTargets) - _collapseTargetCount - _frontlinePressureTargetCount,
            count _queue
        ]] call FLO_fnc_log;
    } else {
        if (count _pressureTargets == 0) then {
            ["LOGISTICS", 3, format [
                "Queue dispatch: no pressure or advance objectives - checking rear objectives (%1 pending)",
                count _queue
            ]] call FLO_fnc_log;
        };
        };
    };
};
_perf set ["targetMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["collapseTargetCount", _collapseTargetCount];
_perf set ["frontlinePressureTargetCount", _frontlinePressureTargetCount];
_perf set ["advanceTargetCount", count _advanceTargets];
_perf set ["targetCount", (count _maneuverTargets) + (count _rearTargets)];

if ((count _maneuverTargets) + (count _rearTargets) == 0) then {
    ["LOGISTICS", 3, "No pressure, supply-advance, or rear objective targets for maneuver reinforcement dispatch"] call FLO_fnc_log;
};

private _batchMin = _net get "DISPATCH_BATCH_MIN";
private _batchMax = _net get "DISPATCH_BATCH_MAX";
private _dispatchTimeBudgetMs = _net get "DISPATCH_TIME_BUDGET_MS";
private _batchSize = _batchMin + floor random ((_batchMax - _batchMin) + 1);
if (_batchSize > count _queue) then {
    _batchSize = count _queue;
};
_perf set ["batchSize", _batchSize];

private _replaced = 0;
private _attempted = 0;
private _inboundCounts = [_net] call FLO_fnc_logisticsNetworkBuildInboundObjectiveCounts;
private _recentDispatchCounts = [_net] call FLO_fnc_logisticsNetworkBuildRecentDispatchCounts;
private _batchDispatchCounts = createHashMap;
private _dispatchBudgetHit = false;

_phaseT0 = diag_tickTime;
for "_i" from 1 to _batchSize do {
    if (count _queue == 0) exitWith {};

    private _groupType = _queue deleteAt 0;
    _attempted = _attempted + 1;

    private _cost = _groupCosts get _groupType;
    if !(_cost isEqualType 0) then {
        throw format ["[LOGISTICS] Missing numeric reinforcement cost for group type %1", _groupType];
    };
    private _targetPool = if (_groupType isEqualTo "static_aa") then {
        [_net] call FLO_fnc_logisticsNetworkGetRearAATargets
    } else {
        _maneuverTargets
    };

    if (count _targetPool == 0) then {
        if !(_groupType isEqualTo "static_aa") then {
            _targetPool = _rearTargets;
        };
    };

    if (count _targetPool == 0) then {
        _perf set ["failNoTargetPool", (_perf get "failNoTargetPool") + 1];
        _queue pushBack _groupType;
        continue;
    };

    if !(_resources call ["canAfford", [_cost, "reinforcement"]]) then {
        _perf set ["failCantAfford", (_perf get "failCantAfford") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _pickTargetT0 = diag_tickTime;
    private _requestedObjectiveId = [_net, _targetPool, _groupType, _inboundCounts, _recentDispatchCounts, _batchDispatchCounts] call FLO_fnc_logisticsNetworkPickBestTarget;
    if (_requestedObjectiveId == "" && {!(_groupType isEqualTo "static_aa")} && {(count _rearTargets) > 0}) then {
        _requestedObjectiveId = [_net, _rearTargets, _groupType, _inboundCounts, _recentDispatchCounts, _batchDispatchCounts] call FLO_fnc_logisticsNetworkPickBestTarget;
    };
    _perf set ["dispatchTargetPickMs", (_perf get "dispatchTargetPickMs") + ((diag_tickTime - _pickTargetT0) * 1000)];
    if (_requestedObjectiveId == "") then {
        if (_groupType isEqualTo "static_aa") then {
            _perf set ["failNoTargetObj", (_perf get "failNoTargetObj") + 1];
        } else {
            _perf set ["failSaturatedTarget", (_perf get "failSaturatedTarget") + 1];
        };
        _queue pushBack _groupType;
        continue;
    };

    private _deliveryObjectiveId = _requestedObjectiveId;
    private _deliveryPickT0 = diag_tickTime;
    if !(_groupType isEqualTo "static_aa") then {
        _deliveryObjectiveId = [_net, _requestedObjectiveId] call FLO_fnc_logisticsNetworkPickDeliveryObjective;
    };
    _perf set ["dispatchDeliveryPickMs", (_perf get "dispatchDeliveryPickMs") + ((diag_tickTime - _deliveryPickT0) * 1000)];
    if (_deliveryObjectiveId == "") then {
        _perf set ["failNoDeliveryObjective", (_perf get "failNoDeliveryObjective") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _spawnFindT0 = diag_tickTime;
    private _spawnData = [_net, _deliveryObjectiveId, _pressureTargets] call FLO_fnc_logisticsNetworkFindSpawnPosition;
    _perf set ["dispatchSpawnMs", (_perf get "dispatchSpawnMs") + ((diag_tickTime - _spawnFindT0) * 1000)];
    private _spawnPos = _spawnData select 0;
    private _sourceObjId = _spawnData select 1;
    if (_spawnPos isEqualTo [0, 0, 0]) then {
        _perf set ["failNoSpawnPos", (_perf get "failNoSpawnPos") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _spendT0 = diag_tickTime;
    private _spent = _resources call ["spendResources", [_cost, "reinforcement"]];
    _perf set ["dispatchSpendMs", (_perf get "dispatchSpendMs") + ((diag_tickTime - _spendT0) * 1000)];

    if (_spent) then {
        private _createT0 = diag_tickTime;
        private _newId = [_net, _groupType, _spawnPos, _deliveryObjectiveId, _sourceObjId, _requestedObjectiveId, _perf] call FLO_fnc_logisticsNetworkCreateReplacement;
        _perf set ["dispatchCreateMs", (_perf get "dispatchCreateMs") + ((diag_tickTime - _createT0) * 1000)];
        if (_newId != "") then {
            private _bookkeepingT0 = diag_tickTime;
            [_net, _groupType, _cost] call FLO_fnc_logisticsNetworkRecordReplacement;
            [_net, _requestedObjectiveId] call FLO_fnc_logisticsNetworkRecordTargetDispatch;
            _replaced = _replaced + 1;
            _inboundCounts set [_requestedObjectiveId, (_inboundCounts getOrDefault [_requestedObjectiveId, 0]) + 1];
            _recentDispatchCounts set [_requestedObjectiveId, (_recentDispatchCounts getOrDefault [_requestedObjectiveId, 0]) + 1];
            _batchDispatchCounts set [_requestedObjectiveId, (_batchDispatchCounts getOrDefault [_requestedObjectiveId, 0]) + 1];
            _perf set ["dispatchBookkeepingMs", (_perf get "dispatchBookkeepingMs") + ((diag_tickTime - _bookkeepingT0) * 1000)];

            ["LOGISTICS", 3, format [
                "Created %1 reinforcement %2 -> %3 (requested %4, cost: %5)",
                _groupType,
                _sourceObjId,
                _deliveryObjectiveId,
                _requestedObjectiveId,
                _cost
            ]] call FLO_fnc_log;
        } else {
            _perf set ["failCreateReplacement", (_perf get "failCreateReplacement") + 1];
        };
    } else {
        _perf set ["failSpendResources", (_perf get "failSpendResources") + 1];
        _queue pushBack _groupType;
    };

    if (((diag_tickTime - _phaseT0) * 1000) >= _dispatchTimeBudgetMs) exitWith {
        _dispatchBudgetHit = true;
    };
};
_perf set ["dispatchMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["attempted", _attempted];
_perf set ["created", _replaced];
_perf set ["resourcesAfter", _resources call ["getResources", []]];

_net set ["_reinforcementQueue", _queue];

private _backlogContinuation = (count _queue) > 0 && {(_attempted >= _batchSize) || {_dispatchBudgetHit}};
private _nextInterval = if (_backlogContinuation) then {
    _net get "DISPATCH_BACKLOG_RETRY_INTERVAL"
} else {
    (_net get "DISPATCH_MIN_INTERVAL") + random ((_net get "DISPATCH_MAX_INTERVAL") - (_net get "DISPATCH_MIN_INTERVAL"))
};
_net set ["_nextDispatchAt", time + _nextInterval];

["LOGISTICS", 3, format [
    "Dispatch window complete: attempted=%1 created=%2 queueRemaining=%3 nextIn=%4s budgetHit=%5",
    _attempted,
    _replaced,
    count _queue,
    round _nextInterval,
    _dispatchBudgetHit
]] call FLO_fnc_log;

if (_replaced > 0) then {
    private _stats = _net get "_stats";
    ["LOGISTICS", 3, format [
        "Replacement totals: %1 created | Total: %2 | Spent: %3",
        _replaced,
        _stats get "totalReplacements",
        _stats get "resourcesSpent"
    ]] call FLO_fnc_log;
};

_net set ["_lastUpdate", time];
_perf set ["status", if (_backlogContinuation) then { "DISPATCH_BACKLOG" } else { "DISPATCHED" }];
_net set ["_lastPerf", _perf];
