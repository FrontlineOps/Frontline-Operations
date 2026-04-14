/*
 * Function: FLO_fnc_logisticsNetworkEnsureSupplyChainFresh
 * Author: Frontline Operations Development Group
 * Description:
 *   Refreshes the supply chain only when cached state is dirty, stale, or
 *   missing. This keeps the zero-change case cheap on hosted and dedicated
 *   sessions.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Force refresh <BOOL> - Default false
 *
 * Return Value:
 *   HASHMAP - Active supply nodes keyed by objective ID
 */

params [
    ["_net", nil],
    ["_forceRefresh", false, [true]]
];

if (isNil "_net") exitWith { createHashMap };

private _activeNodes = _net get "_activeSupplyNodes";
private _lastRefreshAt = _net get "_lastSupplyChainRefreshAt";
private _softInterval = _net get "SUPPLY_CHAIN_SOFT_REFRESH_INTERVAL";
private _shouldRefresh = _forceRefresh
    || {_net get "_supplyChainDirty"}
    || {_net get "_objectiveSideIndexDirty"}
    || {_lastRefreshAt < 0}
    || {(diag_tickTime - _lastRefreshAt) >= _softInterval};

if (_shouldRefresh) exitWith {
    [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain
};

_activeNodes
