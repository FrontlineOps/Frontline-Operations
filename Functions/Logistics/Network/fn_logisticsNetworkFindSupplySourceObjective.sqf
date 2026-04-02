/*
 * Function: FLO_fnc_logisticsNetworkFindSupplySourceObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds the closest active supply node at or behind a friendly delivery
 *   target by walking the cached supply-route parent chain back toward HQ.
 *   The search prefers unblocked active nodes, but if every reachable active
 *   node is in the blocked set it falls back to the nearest active node
 *   instead of failing the dispatch outright.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Delivery target objective ID <STRING>
 *   2: Blocked objective IDs <ARRAY> - Default []
 *
 * Return Value:
 *   STRING - Source objective ID or empty string
 */

params ["_net", "_targetObjectiveId", ["_blockedObjectives", []]];

if (_targetObjectiveId == "") exitWith { "" };
if !(_targetObjectiveId in FLO_Objectives) exitWith { "" };

private _targetObjective = FLO_Objectives get _targetObjectiveId;
private _managedSide = _net get "_managedSide";
if ((_targetObjective get "owner") isNotEqualTo _managedSide) exitWith { "" };

private _routeInfo = _net get "_supplyRouteInfo";
private _activeNodes = _net get "_activeSupplyNodes";
if ((count (keys _routeInfo)) == 0 && {(count (keys _activeNodes)) == 0}) then {
    _activeNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
    _routeInfo = _net get "_supplyRouteInfo";
};
if ((count (keys _activeNodes)) == 0) exitWith { "" };
if !(_targetObjectiveId in _routeInfo) exitWith { "" };

private _maxRouteMeters = _net get "SUPPLY_CHAIN_MAX_HOP_ROUTE_METERS";
private _currentObjectiveId = _targetObjectiveId;
private _currentObjective = _targetObjective;
private _routeMeters = 0;
private _sourceObjectiveId = _targetObjectiveId;
private _resolvedSourceObjectiveId = "";
private _fallbackSourceObjectiveId = "";
private _searchComplete = false;

while {_sourceObjectiveId != "" && {!_searchComplete}} do {
    if !(_sourceObjectiveId in FLO_Objectives) exitWith {
        _sourceObjectiveId = "";
    };

    private _sourceObjective = FLO_Objectives get _sourceObjectiveId;
    _routeMeters = _routeMeters + ((_currentObjective get "position") distance2D (_sourceObjective get "position"));
    if (_routeMeters > _maxRouteMeters) exitWith {
        _sourceObjectiveId = "";
    };

    if (_sourceObjectiveId in _activeNodes) then {
        if (_fallbackSourceObjectiveId == "") then {
            _fallbackSourceObjectiveId = _sourceObjectiveId;
        };

        if !(_sourceObjectiveId in _blockedObjectives) then {
            _resolvedSourceObjectiveId = _sourceObjectiveId;
            _searchComplete = true;
        };
    };

    if (!_searchComplete) then {
        if !(_sourceObjectiveId in _routeInfo) exitWith {
            _sourceObjectiveId = "";
        };

        _currentObjectiveId = _sourceObjectiveId;
        _currentObjective = _sourceObjective;
        _sourceObjectiveId = ((_routeInfo get _currentObjectiveId) get "parentObjective");
    };
};

if (_resolvedSourceObjectiveId != "") then {
    _resolvedSourceObjectiveId
} else {
    _fallbackSourceObjectiveId
}
