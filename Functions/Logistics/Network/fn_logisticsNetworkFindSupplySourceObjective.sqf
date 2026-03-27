/*
 * Function: FLO_fnc_logisticsNetworkFindSupplySourceObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds the closest active supply node behind a friendly delivery target by
 *   walking the owned objective graph backward from the target.
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

private _activeNodes = _net get "_activeSupplyNodes";
if ((count (keys _activeNodes)) == 0) then {
    _activeNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
};
if ((count (keys _activeNodes)) == 0) exitWith { "" };

private _maxRouteMeters = _net get "SUPPLY_CHAIN_MAX_HOP_ROUTE_METERS";
private _visited = createHashMapFromArray [[_targetObjectiveId, 0]];
private _frontier = [[_targetObjectiveId, 0, 0]];

private _bestSourceObjectiveId = "";
private _bestHops = 1e12;
private _bestRouteMeters = 1e12;
private _bestNodeDepth = -1;

while {count _frontier > 0} do {
    private _entry = _frontier deleteAt 0;
    _entry params ["_currentObjectiveId", "_hops", "_routeMeters"];

    private _currentObjective = FLO_Objectives get _currentObjectiveId;
    private _currentPos = _currentObjective get "position";

    {
        private _linkedObjectiveId = _x;
        if !(_linkedObjectiveId in FLO_Objectives) then { continue };

        private _linkedObjective = FLO_Objectives get _linkedObjectiveId;
        if ((_linkedObjective get "owner") isNotEqualTo _managedSide) then { continue };

        private _newRouteMeters = _routeMeters + (_currentPos distance2D (_linkedObjective get "position"));
        if (_newRouteMeters > _maxRouteMeters) then { continue };

        private _bestSeenRoute = if (_linkedObjectiveId in _visited) then {
            _visited get _linkedObjectiveId
        } else {
            1e12
        };
        if (_newRouteMeters >= _bestSeenRoute) then { continue };

        _visited set [_linkedObjectiveId, _newRouteMeters];

        if (
            _linkedObjectiveId != _targetObjectiveId
            && {_linkedObjectiveId in _activeNodes}
            && {!(_linkedObjectiveId in _blockedObjectives)}
        ) then {
            private _nodeInfo = _activeNodes get _linkedObjectiveId;
            private _nodeDepth = _nodeInfo get "depth";

            if (
                _hops + 1 < _bestHops
                || {
                    _hops + 1 == _bestHops
                    && {
                        _newRouteMeters < _bestRouteMeters
                        || {_newRouteMeters == _bestRouteMeters && {_nodeDepth > _bestNodeDepth}}
                    }
                }
            ) then {
                _bestSourceObjectiveId = _linkedObjectiveId;
                _bestHops = _hops + 1;
                _bestRouteMeters = _newRouteMeters;
                _bestNodeDepth = _nodeDepth;
            };
        };

        _frontier pushBack [_linkedObjectiveId, _hops + 1, _newRouteMeters];
    } forEach (_currentObjective get "linkedObjectives");
};

if (_bestSourceObjectiveId == "") then {
    private _hqObjectiveId = _net get "_hqObjectiveId";
    if (
        _hqObjectiveId != ""
        && {_hqObjectiveId != _targetObjectiveId}
        && {_hqObjectiveId in _activeNodes}
        && {!(_hqObjectiveId in _blockedObjectives)}
    ) then {
        private _hqObjective = FLO_Objectives get _hqObjectiveId;
        if (((_hqObjective get "position") distance2D (_targetObjective get "position")) <= _maxRouteMeters) then {
            _bestSourceObjectiveId = _hqObjectiveId;
        };
    };
};

_bestSourceObjectiveId
