/*
 * Function: FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole
 * Author: Frontline Operations Development Group
 * Description:
 *   Describes where an owned objective currently sits in the managed side's
 *   supply chain so target and delivery scoring can stay aligned.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   HASHMAP - Role description
 */

params ["_net", "_objectiveId"];

private _roleCache = _net get "_dispatchRoleCache";
if (_objectiveId in _roleCache) exitWith { _roleCache get _objectiveId };

private _role = createHashMapFromArray [
    ["depth", -1],
    ["routeMeters", 1e12],
    ["parentObjective", ""],
    ["deliveryCount", 0],
    ["isHQ", false],
    ["isActiveNode", false],
    ["activeLinkedObjectives", []],
    ["isAdvanceCandidate", false]
];

if !(_objectiveId in FLO_Objectives) exitWith {
    _roleCache set [_objectiveId, _role];
    _role
};

private _routeInfo = _net get "_supplyRouteInfo";
private _activeNodes = _net get "_activeSupplyNodes";
if ((count (keys _routeInfo)) == 0 && {(count (keys _activeNodes)) == 0}) then {
    [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
    _routeInfo = _net get "_supplyRouteInfo";
    _activeNodes = _net get "_activeSupplyNodes";
};

if !(_objectiveId in _routeInfo) exitWith {
    _roleCache set [_objectiveId, _role];
    _role
};

private _nodeInfo = _routeInfo get _objectiveId;
private _objective = FLO_Objectives get _objectiveId;
private _isActiveNode = _objectiveId in _activeNodes;
private _activeLinkedObjectives = (_objective get "linkedObjectives") select { _x in _activeNodes };

_role set ["depth", _nodeInfo get "depth"];
_role set ["routeMeters", _nodeInfo get "routeMeters"];
_role set ["parentObjective", _nodeInfo get "parentObjective"];
_role set ["deliveryCount", _nodeInfo get "deliveryCount"];
_role set ["isHQ", _nodeInfo get "isHQ"];
_role set ["isActiveNode", _isActiveNode];
_role set ["activeLinkedObjectives", _activeLinkedObjectives];
_role set ["isAdvanceCandidate", !_isActiveNode && {count _activeLinkedObjectives > 0}];

_roleCache set [_objectiveId, _role];

_role
