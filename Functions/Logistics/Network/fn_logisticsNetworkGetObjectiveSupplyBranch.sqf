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

private _branchCache = _net get "_dispatchBranchCache";
if (_objectiveId in _branchCache) exitWith { _branchCache get _objectiveId };

private _routeInfo = _net get "_supplyRouteInfo";
if !(_objectiveId in _routeInfo) exitWith {
    _branchCache set [_objectiveId, ""];
    ""
};

private _hqObjectiveId = _net get "_hqObjectiveId";
if (_objectiveId isEqualTo _hqObjectiveId) exitWith {
    _branchCache set [_objectiveId, _hqObjectiveId];
    _hqObjectiveId
};

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

_branchCache set [_objectiveId, _branchObjectiveId];

_branchObjectiveId
