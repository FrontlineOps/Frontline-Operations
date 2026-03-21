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
    ["targetCount", 0],
    ["batchSize", 0],
    ["attempted", 0],
    ["created", 0],
    ["failNoTargetPool", 0],
    ["failCantAfford", 0],
    ["failNoTargetObj", 0],
    ["failNoSpawnPos", 0],
    ["failSpendResources", 0],
    ["failCreateReplacement", 0],
    ["resourcesBefore", 0],
    ["resourcesAfter", 0],
    ["refreshMs", 0],
    ["compositionMs", 0],
    ["reconcileMs", 0],
    ["targetMs", 0],
    ["dispatchMs", 0],
    ["status", "RUN"]
];

private _phaseT0 = diag_tickTime;
[_net] call FLO_fnc_logisticsNetworkRefreshManagedSide;
_perf set ["refreshMs", (diag_tickTime - _phaseT0) * 1000];

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
_perf set ["resourcesBefore", _resources get "_resources"];
private _targets = [_net] call FLO_fnc_logisticsNetworkFindReinforcementTargets;

if (count _targets == 0) then {
    ["LOGISTICS", 3, format [
        "Queue dispatch: no objectives under pressure - checking rear objectives (%1 pending)",
        count _queue
    ]] call FLO_fnc_log;

    private _managedObjectives = [_net, 3000] call FLO_fnc_logisticsNetworkFindRearObjectives;

    if (count _managedObjectives > 0) then {
        _targets = [selectRandom _managedObjectives];
    };
};
_perf set ["targetMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["targetCount", count _targets];

if (count _targets == 0) then {
    ["LOGISTICS", 3, "No pressure/rear objective targets for maneuver reinforcement dispatch"] call FLO_fnc_log;
};

private _batchMin = _net get "DISPATCH_BATCH_MIN";
private _batchMax = _net get "DISPATCH_BATCH_MAX";
private _batchSize = _batchMin + floor random ((_batchMax - _batchMin) + 1);
if (_batchSize > count _queue) then {
    _batchSize = count _queue;
};
_perf set ["batchSize", _batchSize];

private _replaced = 0;
private _attempted = 0;

_phaseT0 = diag_tickTime;
for "_i" from 1 to _batchSize do {
    if (count _queue == 0) exitWith {};

    private _groupType = _queue deleteAt 0;
    _attempted = _attempted + 1;

    private _cost = _groupCosts get _groupType;
    private _targetPool = if (_groupType isEqualTo "static_aa") then {
        [_net] call FLO_fnc_logisticsNetworkGetRearAATargets
    } else {
        _targets
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

    private _targetObj = [_net, _targetPool, _groupType, []] call FLO_fnc_logisticsNetworkPickBestTarget;
    if (_targetObj == "") then {
        _perf set ["failNoTargetObj", (_perf get "failNoTargetObj") + 1];
        _queue pushBack _groupType;
        continue;
    };

    private _spawnData = [_net, _targetObj, _targets] call FLO_fnc_logisticsNetworkFindSpawnPosition;
    private _spawnPos = _spawnData select 0;
    private _sourceObjId = _spawnData select 1;
    if (_spawnPos isEqualTo [0, 0, 0]) then {
        _perf set ["failNoSpawnPos", (_perf get "failNoSpawnPos") + 1];
        _queue pushBack _groupType;
        continue;
    };

    _net set ["_lastReinforcementTarget", _targetObj];

    if (_resources call ["spendResources", [_cost, "reinforcement"]]) then {
        private _newId = [_net, _groupType, _spawnPos, _targetObj, _sourceObjId] call FLO_fnc_logisticsNetworkCreateReplacement;
        if (_newId != "") then {
            [_net, _groupType, _cost] call FLO_fnc_logisticsNetworkRecordReplacement;
            _replaced = _replaced + 1;

            ["LOGISTICS", 3, format [
                "Created %1 reinforcement %2 -> %3 (cost: %4)",
                _groupType,
                _sourceObjId,
                _targetObj,
                _cost
            ]] call FLO_fnc_log;
        } else {
            _perf set ["failCreateReplacement", (_perf get "failCreateReplacement") + 1];
        };
    } else {
        _perf set ["failSpendResources", (_perf get "failSpendResources") + 1];
        _queue pushBack _groupType;
    };
};
_perf set ["dispatchMs", (diag_tickTime - _phaseT0) * 1000];
_perf set ["attempted", _attempted];
_perf set ["created", _replaced];
_perf set ["resourcesAfter", _resources get "_resources"];

_net set ["_reinforcementQueue", _queue];

private _nextInterval = (_net get "DISPATCH_MIN_INTERVAL") + random ((_net get "DISPATCH_MAX_INTERVAL") - (_net get "DISPATCH_MIN_INTERVAL"));
_net set ["_nextDispatchAt", time + _nextInterval];

["LOGISTICS", 3, format [
    "Dispatch window complete: attempted=%1 created=%2 queueRemaining=%3 nextIn=%4s",
    _attempted,
    _replaced,
    count _queue,
    round _nextInterval
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
_perf set ["status", "DISPATCHED"];
_net set ["_lastPerf", _perf];
