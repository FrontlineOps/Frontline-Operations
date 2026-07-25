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
    ["hqObjective", ""],
    ["supplyNodeCount", 0],
    ["batchSize", 0],
    ["attempted", 0],
    ["created", 0],
    ["failNoTargetPool", 0],
    ["failNoTargetObj", 0],
    ["failSaturatedTarget", 0],
    ["targetRejectNotIntegrated", 0],
    ["targetRejectSecureRatio", 0],
    ["targetRejectCollapseInboundCap", 0],
    ["targetRejectInboundCap", 0],
    ["targetRejectBatchCap", 0],
    ["failNoDeliveryObjective", 0],
    ["failNoSupplySource", 0],
    ["failSupplyChanged", 0],
    ["failSpendResources", 0],
    ["policyDenied", 0],
    ["failCreateReplacement", 0],
    ["resourcesBefore", 0],
    ["resourcesAfter", 0],
    ["refreshMs", 0],
    ["captureGrowthMs", 0],
    ["captureGrowthPending", 0],
    ["captureGrowthApplied", 0],
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
private _activeSupplyNodes = [_net] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
_perf set ["refreshMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["hqObjective", _net get "_hqObjectiveId"];
_perf set ["supplyNodeCount", count (keys _activeSupplyNodes)];

_phaseT0 = diag_tickTime;
private _captureGrowthMetrics = [_net] call FLO_fnc_logisticsNetworkProcessPendingCaptureGrowth;
_perf set ["captureGrowthMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["captureGrowthPending", _captureGrowthMetrics get "pendingObjectives"];
_perf set ["captureGrowthApplied", _captureGrowthMetrics get "appliedObjectives"];

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
private _replacementPriorityOrder = _net get "REPLACEMENT_PRIORITY_ORDER";
{
    if !(_x in _replacementPriorityOrder) then {
        throw format ["Replacement queue contains unprioritized group type %1", _x];
    };
} forEach _queue;
_queue = [_queue, [], { _replacementPriorityOrder find _x }, "ASCEND"] call BIS_fnc_sortBy;
_net set ["_reinforcementQueue", _queue];
_perf set ["reconcileMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["queueAfter", count _queue];

if (_queue isEqualTo []) exitWith {
    _perf set ["status", "QUEUE_EMPTY"];
    _net set ["_lastPerf", _perf];
    ["LOGISTICS", 3, "No pending reinforcements after queue reconciliation"] call FLO_fnc_log;
};

private _nextDispatchAtTick = _net get "_nextDispatchAtTick";
if (diag_tickTime < _nextDispatchAtTick) exitWith {
    _perf set ["status", "WAITING"];
    _net set ["_lastPerf", _perf];
    ["LOGISTICS", 4, format [
        "Reinforcement queue pending: %1 groups | next dispatch in %2s",
        count _queue,
        round (_nextDispatchAtTick - diag_tickTime)
    ]] call FLO_fnc_log;
    _net set ["_lastUpdate", time];
};

_phaseT0 = diag_tickTime;
private _resources = FLO_SideResources get (_net get "_managedSideKey");
_perf set ["resourcesBefore", _resources call ["getResources", []]];
private _targetPicture = [_net, 3000] call FLO_fnc_logisticsNetworkBuildTargetPicture;
private _pressureTargets = _targetPicture get "pressureTargets";
private _rearTargets = _targetPicture get "rearTargets";
private _maneuverTargets = _targetPicture get "maneuverTargets";
private _collapseTargetCount = _targetPicture get "collapseTargetCount";
private _frontlinePressureTargetCount = _targetPicture get "frontlinePressureTargetCount";
private _sourceBlockedObjectives = _pressureTargets select {
    [_net, _x] call FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure
};

if (_collapseTargetCount > 0) then {
    ["LOGISTICS", 3, format [
        "Queue dispatch: collapse pressure first (%1 collapse, %2 total pressure, %3 pending)",
        _collapseTargetCount,
        count _pressureTargets,
        count _queue
    ]] call FLO_fnc_log;
} else {
    if (_frontlinePressureTargetCount > 0) then {
        ["LOGISTICS", 3, format [
            "Queue dispatch: frontline pressure first (%1 frontline, %2 background pressure, %3 pending)",
            _frontlinePressureTargetCount,
            (count _pressureTargets) - _collapseTargetCount - _frontlinePressureTargetCount,
            count _queue
        ]] call FLO_fnc_log;
    } else {
        if (_pressureTargets isEqualTo []) then {
            ["LOGISTICS", 3, format [
                "Queue dispatch: no pressured objectives - checking rear objectives (%1 pending)",
                count _queue
            ]] call FLO_fnc_log;
        };
    };
};
_perf set ["targetMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["collapseTargetCount", _collapseTargetCount];
_perf set ["frontlinePressureTargetCount", _frontlinePressureTargetCount];
_perf set ["targetCount", (count _maneuverTargets) + (count _rearTargets)];

if (_maneuverTargets isEqualTo [] && {_rearTargets isEqualTo []}) then {
    ["LOGISTICS", 3, "No pressure or rear objective targets for maneuver reinforcement dispatch"] call FLO_fnc_log;
};

private _dispatchTimeBudgetMs = _net get "DISPATCH_TIME_BUDGET_MS";
private _batchSize = (count _queue) min (_net get "REPLACEMENT_DISPATCH_BATCH_SIZE");
_perf set ["batchSize", _batchSize];

private _replaced = 0;
private _attempted = 0;
private _inboundCounts = [_net] call FLO_fnc_logisticsNetworkBuildInboundObjectiveCounts;
private _recentDispatchCounts = [_net] call FLO_fnc_logisticsNetworkBuildRecentDispatchCounts;
private _batchDispatchCounts = createHashMap;
private _targetRejectionCounts = createHashMapFromArray [
    ["NOT_INTEGRATED", 0],
    ["SECURE_RATIO", 0],
    ["COLLAPSE_INBOUND_CAP", 0],
    ["INBOUND_CAP", 0],
    ["BATCH_CAP", 0]
];
private _dispatchBudgetHit = false;
private _supplyBlocked = false;

_phaseT0 = diag_tickTime;
for "_i" from 1 to _batchSize do {
    if (_queue isEqualTo [] || {_supplyBlocked}) exitWith {};

    private _groupType = _queue deleteAt 0;
    _attempted = _attempted + 1;

    private _cost = _groupCosts get _groupType;
    if (!(_cost isEqualType 0)) then {
        throw format ["[LOGISTICS] Missing numeric reinforcement cost for group type %1", _groupType];
    };
    private _throughputCost = (_net get "GROUP_THROUGHPUT_COSTS") get _groupType;
    private _targetPool = if (_groupType isEqualTo "static_aa") then {
        [_net] call FLO_fnc_logisticsNetworkGetRearAATargets
    } else {
        _maneuverTargets
    };

    if (_targetPool isEqualTo []) then {
        if (_groupType isNotEqualTo "static_aa") then {
            _targetPool = _rearTargets;
        };
    };

    private _collapseCandidates = _targetPool arrayIntersect _sourceBlockedObjectives;
    if (_groupType isNotEqualTo "static_aa" && {_collapseCandidates isNotEqualTo []}) then {
        _targetPool = _collapseCandidates;
    };
    if (_targetPool isEqualTo [] && {_groupType isNotEqualTo "static_aa"} && {_rearTargets isNotEqualTo []}) then {
        _targetPool = _rearTargets;
    };

    if (_targetPool isEqualTo []) then {
        _perf set ["failNoTargetPool", (_perf get "failNoTargetPool") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _deliveryPickT0 = diag_tickTime;
    private _sourceableTargetPool = [];
    private _deliveryByTarget = createHashMap;
    {
        private _deliveryObjectiveId = _x;
        if (_groupType isNotEqualTo "static_aa") then {
            _deliveryObjectiveId = [
                _net,
                _x,
                _throughputCost,
                _sourceBlockedObjectives
            ] call FLO_fnc_logisticsNetworkPickDeliveryObjective;
        } else {
            if (([
                _net,
                _x,
                _sourceBlockedObjectives,
                _throughputCost
            ] call FLO_fnc_logisticsNetworkFindSupplySourceObjective) == "") then {
                _deliveryObjectiveId = "";
            };
        };
        if (_deliveryObjectiveId == "") then { continue };
        _sourceableTargetPool pushBack _x;
        _deliveryByTarget set [_x, _deliveryObjectiveId];
    } forEach _targetPool;
    _perf set ["dispatchDeliveryPickMs", (_perf get "dispatchDeliveryPickMs") + ((diag_tickTime - _deliveryPickT0) * 1000)];
    if (_sourceableTargetPool isEqualTo []) then {
        _perf set ["failNoSupplySource", (_perf get "failNoSupplySource") + 1];
        _queue pushBack _groupType;
        _supplyBlocked = true;
        continue;
    };
    _targetPool = _sourceableTargetPool;

    private _pickTargetT0 = diag_tickTime;
    private _requestedObjectiveId = [
        _net,
        _targetPool,
        _groupType,
        _inboundCounts,
        _recentDispatchCounts,
        _batchDispatchCounts,
        _targetRejectionCounts
    ] call FLO_fnc_logisticsNetworkPickBestTarget;
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

    private _urgency = [_net, _requestedObjectiveId] call FLO_fnc_logisticsNetworkGetReplacementUrgency;
    private _deliveryObjectiveId = _deliveryByTarget get _requestedObjectiveId;
    if (_deliveryObjectiveId == "") then {
        _perf set ["failNoDeliveryObjective", (_perf get "failNoDeliveryObjective") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _spawnFindT0 = diag_tickTime;
    private _spawnData = [
        _net,
        _deliveryObjectiveId,
        _sourceBlockedObjectives,
        _throughputCost
    ] call FLO_fnc_logisticsNetworkFindSpawnPosition;
    _perf set ["dispatchSpawnMs", (_perf get "dispatchSpawnMs") + ((diag_tickTime - _spawnFindT0) * 1000)];
    private _spawnPos = _spawnData select 0;
    private _sourceObjId = _spawnData select 1;
    private _sourceNodeId = _spawnData select 2;
    if (_spawnPos isEqualTo [0, 0, 0]) then {
        _perf set ["failNoSupplySource", (_perf get "failNoSupplySource") + 1];
        _queue pushBack _groupType;
        _supplyBlocked = true;
        continue;
    };

    private _reservationId = format [
        "LOGISTICS:%1:%2:%3",
        _net get "_managedSideKey",
        round (diag_tickTime * 1000),
        _i
    ];
    private _spendingContext = createHashMapFromArray [
        ["strategic", _cost >= 1600],
        ["commitment", false],
        ["reserved", false],
        ["referenceId", _requestedObjectiveId]
    ];
    private _spendingDecision = [
        _resources,
        _cost,
        "REINFORCEMENT",
        _urgency,
        _spendingContext
    ] call FLO_fnc_commanderSpendingEvaluate;
    if !(_spendingDecision get "allowed") then {
        _perf set ["policyDenied", (_perf get "policyDenied") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _spendT0 = diag_tickTime;
    private _reserved = _resources call ["reserve", [
        _reservationId,
        _cost,
        "REINFORCEMENT",
        format ["%1 replacement", _groupType],
        "COMMANDER",
        _requestedObjectiveId
    ]];
    _perf set ["dispatchSpendMs", (_perf get "dispatchSpendMs") + ((diag_tickTime - _spendT0) * 1000)];

    if (_reserved) then {
        private _throughputConsumed = [_net, _sourceNodeId, _throughputCost, format ["%1 replacement", _groupType]] call FLO_fnc_logisticsNetworkConsumeThroughput;
        if (!_throughputConsumed) then {
            _resources call ["releaseReservation", [_reservationId, "Source local supplies changed before dispatch"]];
            _perf set ["failSupplyChanged", (_perf get "failSupplyChanged") + 1];
            _queue pushBack _groupType;
            _supplyBlocked = true;
            continue;
        };

        private _createT0 = diag_tickTime;
        private _newId = [_net, _groupType, _spawnPos, _deliveryObjectiveId, _sourceObjId, _requestedObjectiveId, _perf] call FLO_fnc_logisticsNetworkCreateReplacement;
        _perf set ["dispatchCreateMs", (_perf get "dispatchCreateMs") + ((diag_tickTime - _createT0) * 1000)];
        if (_newId != "") then {
            if !(_resources call ["commitReservation", [_reservationId, _cost, format ["Dispatched %1 replacement", _groupType]]]) then {
                throw format ["Failed to commit guaranteed logistics reservation %1", _reservationId];
            };
            private _bookkeepingT0 = diag_tickTime;
            [_net, _groupType, _cost] call FLO_fnc_logisticsNetworkRecordReplacement;
            [_net, _requestedObjectiveId] call FLO_fnc_logisticsNetworkRecordTargetDispatch;
            _replaced = _replaced + 1;
            _inboundCounts set [_requestedObjectiveId, (_inboundCounts getOrDefault [_requestedObjectiveId, 0]) + 1];
            _recentDispatchCounts set [_requestedObjectiveId, (_recentDispatchCounts getOrDefault [_requestedObjectiveId, 0]) + 1];
            _batchDispatchCounts set [_requestedObjectiveId, (_batchDispatchCounts getOrDefault [_requestedObjectiveId, 0]) + 1];
            _perf set ["dispatchBookkeepingMs", (_perf get "dispatchBookkeepingMs") + ((diag_tickTime - _bookkeepingT0) * 1000)];

            ["LOGISTICS", 3, format [
                "Created %1 reinforcement %2 -> %3 requested=%4 treasury=%5 localSupplies=%6",
                _groupType,
                _sourceObjId,
                _deliveryObjectiveId,
                _requestedObjectiveId,
                _cost,
                _throughputCost
            ]] call FLO_fnc_log;
        } else {
            [_net, _sourceNodeId, _throughputCost, "Replacement creation refund"] call FLO_fnc_logisticsNetworkRestoreThroughput;
            _resources call ["releaseReservation", [_reservationId, "Replacement creation failed"]];
            _perf set ["failCreateReplacement", (_perf get "failCreateReplacement") + 1];
            _queue pushBack _groupType;
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
_perf set ["targetRejectNotIntegrated", _targetRejectionCounts get "NOT_INTEGRATED"];
_perf set ["targetRejectSecureRatio", _targetRejectionCounts get "SECURE_RATIO"];
_perf set ["targetRejectCollapseInboundCap", _targetRejectionCounts get "COLLAPSE_INBOUND_CAP"];
_perf set ["targetRejectInboundCap", _targetRejectionCounts get "INBOUND_CAP"];
_perf set ["targetRejectBatchCap", _targetRejectionCounts get "BATCH_CAP"];

if ((_perf get "failSaturatedTarget") > 0) then {
    ["LOGISTICS", 4, format [
        "Dispatch target rejections side=%1 attempts=%2 notIntegrated=%3 secureRatio=%4 collapseInbound=%5 inboundCap=%6 batchCap=%7",
        _net get "_managedSideKey",
        _perf get "failSaturatedTarget",
        _perf get "targetRejectNotIntegrated",
        _perf get "targetRejectSecureRatio",
        _perf get "targetRejectCollapseInboundCap",
        _perf get "targetRejectInboundCap",
        _perf get "targetRejectBatchCap"
    ]] call FLO_fnc_log;
};

_net set ["_reinforcementQueue", _queue];

private _backlogContinuation = _queue isNotEqualTo [] && {(_attempted >= _batchSize) || {_dispatchBudgetHit}};
private _nextInterval = if (_backlogContinuation) then {
    _net get "DISPATCH_BACKLOG_RETRY_INTERVAL"
} else {
    (_net get "DISPATCH_MIN_INTERVAL") + random ((_net get "DISPATCH_MAX_INTERVAL") - (_net get "DISPATCH_MIN_INTERVAL"))
};
_net set ["_nextDispatchAtTick", diag_tickTime + _nextInterval];
_net set ["_nextDispatchAt", time + _nextInterval];

["LOGISTICS", 3, format [
    "Dispatch window complete: attempted=%1 created=%2 queueRemaining=%3 nextIn=%4s budgetHit=%5 supplyBlocked=%6",
    _attempted,
    _replaced,
    count _queue,
    round _nextInterval,
    _dispatchBudgetHit,
    _supplyBlocked
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
private _status = ["DISPATCHED", "DISPATCH_BACKLOG"] select (_backlogContinuation);
if (_supplyBlocked) then { _status = "SUPPLY_BLOCKED"; };
_perf set ["status", _status];
_net set ["_lastPerf", _perf];
