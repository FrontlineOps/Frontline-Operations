/*
 * Function: FLO_fnc_logisticsNetworkCreate
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes a logistics network object, restores saved state when present,
 *   and starts its main dispatch loop.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Side context override <SIDE> - Default sideUnknown
 *   2: Saved state override <HASHMAP|BOOL> - Default false
 *
 * Return Value:
 *   None
 */

params ["_net", ["_sideContext", sideUnknown], ["_savedStateOverride", false]];

if (_sideContext in [east, west]) then {
    _net set ["_sideContext", _sideContext];
    [_net, _sideContext] call FLO_fnc_logisticsNetworkSetManagedSide;
} else {
    [_net] call FLO_fnc_logisticsNetworkRefreshManagedSide;
};

if (_savedStateOverride isEqualType createHashMap) then {
    private _stats = _savedStateOverride getOrDefault ["stats", createHashMap];
    if !(_stats isEqualType createHashMap) then {
        _stats = createHashMap;
    };
    if !("totalReplacements" in _stats) then { _stats set ["totalReplacements", 0]; };
    if !("resourcesSpent" in _stats) then { _stats set ["resourcesSpent", 0]; };
    if !("byType" in _stats) then { _stats set ["byType", createHashMap]; };
    if !("captureGrowthAppliedGroups" in _stats) then { _stats set ["captureGrowthAppliedGroups", 0]; };
    if !("captureGrowthEvents" in _stats) then { _stats set ["captureGrowthEvents", 0]; };

    _net set ["_initialComposition", _savedStateOverride getOrDefault ["initialComposition", createHashMap]];
    _net set ["_stats", _stats];
    _net set ["_lastReinforcementTarget", _savedStateOverride getOrDefault ["lastReinforcementTarget", ""]];
    _net set ["_recentReinforcementDispatches", []];
    _net set ["_reinforcementQueue", _savedStateOverride getOrDefault ["reinforcementQueue", []]];

    private _savedNextDispatchAt = _savedStateOverride getOrDefault ["nextDispatchAt", -1];
    private _maxAllowedDelay = _net get "DISPATCH_MAX_INTERVAL";
    if (_savedNextDispatchAt > time && {(_savedNextDispatchAt - time) <= _maxAllowedDelay}) then {
        _net set ["_nextDispatchAt", _savedNextDispatchAt];
    } else {
        private _minInterval = _net get "DISPATCH_MIN_INTERVAL";
        private _maxInterval = _net get "DISPATCH_MAX_INTERVAL";
        _net set ["_nextDispatchAt", time + (_minInterval + random (_maxInterval - _minInterval))];
    };

    _net set ["_lastUpdate", time];

    ["LOGISTICS", 3, format [
        "Restored from save: %1 total replacements",
        ((_net get "_stats") get "totalReplacements")
    ]] call FLO_fnc_log;
} else {
    _net set ["_stats", createHashMapFromArray [
        ["totalReplacements", 0],
        ["resourcesSpent", 0],
        ["byType", createHashMap],
        ["captureGrowthAppliedGroups", 0],
        ["captureGrowthEvents", 0]
    ]];
    _net set ["_lastReinforcementTarget", ""];
    _net set ["_recentReinforcementDispatches", []];
    _net set ["_reinforcementQueue", []];

    private _minInterval = _net get "DISPATCH_MIN_INTERVAL";
    private _maxInterval = _net get "DISPATCH_MAX_INTERVAL";
    _net set ["_nextDispatchAt", time + (_minInterval + random (_maxInterval - _minInterval))];
    _net set ["_lastUpdate", time];
};

[_net] call FLO_fnc_logisticsNetworkStartMainLoop;
