/*
 * Function: FLO_fnc_logisticsNetworkGetObjectiveSupplyBranch
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves the first-hop supply branch for an objective on the managed
 *   side's owned supply route graph. Used to spread reinforcement pressure
 *   across distinct sectors instead of repeatedly feeding one branch.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   STRING - Branch objective ID or empty string
 */

params ["_net", "_objectiveId"];

if (_objectiveId == "") exitWith { "" };

private _routeInfo = _net get "_supplyRouteInfo";
if !(_objectiveId in _routeInfo) exitWith { "" };

private _hqObjectiveId = _net get "_hqObjectiveId";
if (_objectiveId isEqualTo _hqObjectiveId) exitWith { _hqObjectiveId };

private _branchObjectiveId = _objectiveId;
private _parentObjectiveId = ((_routeInfo get _branchObjectiveId) get "parentObjective");

while {_parentObjectiveId != "" && {_parentObjectiveId isNotEqualTo _hqObjectiveId}} do {
    _branchObjectiveId = _parentObjectiveId;
    if !(_branchObjectiveId in _routeInfo) exitWith {
        _branchObjectiveId = _objectiveId;
        _parentObjectiveId = "";
    };

    _parentObjectiveId = ((_routeInfo get _branchObjectiveId) get "parentObjective");
};

_branchObjectiveId
