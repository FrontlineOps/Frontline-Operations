/*
 * Function: FLO_fnc_logisticsNetworkRefreshSupplyChain
 * Author: Frontline Operations Development Group
 * Description:
 *   Rebuilds the managed side's active supply-node chain from the elected HQ
 *   across owned linked objectives. Objectives only become forward supply
 *   nodes after confirmed deliveries and sufficient local stability.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - Active supply nodes keyed by objective ID
 */

params ["_net"];

_net set ["_targetPicture", createHashMap];
_net set ["_dispatchRoleCache", createHashMap];
_net set ["_dispatchBranchCache", createHashMap];
_net set ["_dispatchEnemyDistanceCache", createHashMap];
_net set ["_dispatchSourceableCache", createHashMap];
_net set ["_dispatchDeliveryObjectiveCache", createHashMap];

private _managedSide = _net get "_managedSide";
private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
private _deliveryCounts = _net get "_supplyNodeDeliveries";
private _resetFriendlyCount = _net get "SUPPLY_NODE_RESET_FRIENDLY_COUNT";
private _minDeliveries = _net get "SUPPLY_NODE_MIN_DELIVERIES";
private _promotionDeliveryCount = _net get "SUPPLY_NODE_PROMOTION_DELIVERY_COUNT";
private _minActiveFriendlyCount = _net get "SUPPLY_NODE_MIN_ACTIVE_FRIENDLY_COUNT";

{
    private _objectiveId = _x;
    if !(_objectiveId in FLO_Objectives) then {
        _deliveryCounts deleteAt _objectiveId;
        continue;
    };

    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") isNotEqualTo _managedSide || {(_objective get _friendlyCountKey) < _resetFriendlyCount}) then {
        _deliveryCounts deleteAt _objectiveId;
    };
} forEach (keys _deliveryCounts);

_net set ["_supplyNodeDeliveries", _deliveryCounts];

[_net] call FLO_fnc_logisticsNetworkRefreshObjectiveSideIndex;
private _hqObjectiveId = [_net] call FLO_fnc_logisticsNetworkPickHQObjective;
_net set ["_hqObjectiveId", _hqObjectiveId];

private _routeInfo = createHashMap;
private _activeNodes = createHashMap;

if (_hqObjectiveId == "") exitWith {
    _net set ["_supplyRouteInfo", _routeInfo];
    _net set ["_activeSupplyNodes", _activeNodes];
    _net set ["_lastSupplyNodeSignature", ""];
    _activeNodes
};

private _hqInfo = createHashMapFromArray [
    ["depth", 0],
    ["routeMeters", 0],
    ["parentObjective", ""],
    ["deliveryCount", 0],
    ["isHQ", true]
];

_routeInfo set [_hqObjectiveId, _hqInfo];
_activeNodes set [_hqObjectiveId, createHashMapFromArray [
    ["depth", _hqInfo get "depth"],
    ["routeMeters", _hqInfo get "routeMeters"],
    ["parentObjective", _hqInfo get "parentObjective"],
    ["deliveryCount", _hqInfo get "deliveryCount"],
    ["isHQ", _hqInfo get "isHQ"]
]];

private _frontier = [[_hqObjectiveId, 0, 0]];
private _frontierIndex = 0;

while {_frontierIndex < count _frontier} do {
    private _entry = _frontier select _frontierIndex;
    _frontierIndex = _frontierIndex + 1;
    _entry params ["_currentObjectiveId", "_depth", "_routeMeters"];

    private _currentObjective = FLO_Objectives get _currentObjectiveId;
    private _currentPos = _currentObjective get "position";

    {
        private _linkedObjectiveId = _x;
        if !(_linkedObjectiveId in FLO_Objectives) then { continue };

        private _linkedObjective = FLO_Objectives get _linkedObjectiveId;
        if ((_linkedObjective get "owner") isNotEqualTo _managedSide) then { continue };

        private _newRouteMeters = _routeMeters + (_currentPos distance2D (_linkedObjective get "position"));
        private _bestSeenRoute = if (_linkedObjectiveId in _routeInfo) then {
            (_routeInfo get _linkedObjectiveId) get "routeMeters"
        } else {
            1e12
        };
        if (_newRouteMeters >= _bestSeenRoute) then { continue };

        private _deliveryCount = if (_linkedObjectiveId in _deliveryCounts) then {
            _deliveryCounts get _linkedObjectiveId
        } else {
            0
        };

        private _nodeInfo = createHashMapFromArray [
            ["depth", _depth + 1],
            ["routeMeters", _newRouteMeters],
            ["parentObjective", _currentObjectiveId],
            ["deliveryCount", _deliveryCount],
            ["isHQ", false]
        ];

        _routeInfo set [_linkedObjectiveId, _nodeInfo];
        _frontier pushBack [_linkedObjectiveId, _depth + 1, _newRouteMeters];

        private _friendlyCount = _linkedObjective get _friendlyCountKey;
        if (
            _deliveryCount >= _minDeliveries
            && {!(_linkedObjective get "contested")}
            && {
                _friendlyCount >= _minActiveFriendlyCount
                || {_deliveryCount >= _promotionDeliveryCount}
            }
        ) then {
            _activeNodes set [_linkedObjectiveId, createHashMapFromArray [
                ["depth", _nodeInfo get "depth"],
                ["routeMeters", _nodeInfo get "routeMeters"],
                ["parentObjective", _nodeInfo get "parentObjective"],
                ["deliveryCount", _nodeInfo get "deliveryCount"],
                ["isHQ", _nodeInfo get "isHQ"]
            ]];
        };
    } forEach (_currentObjective get "linkedObjectives");
};

_net set ["_supplyRouteInfo", _routeInfo];
_net set ["_activeSupplyNodes", _activeNodes];

private _nodeIds = keys _activeNodes;
_nodeIds sort true;
private _signature = format ["%1|%2", _hqObjectiveId, _nodeIds joinString ","];
if (_signature != (_net get "_lastSupplyNodeSignature")) then {
    _net set ["_lastSupplyNodeSignature", _signature];
    ["LOGISTICS", 3, format [
        "Supply chain %1: HQ=%2 activeNodes=%3",
        _net get "_managedSideKey",
        _hqObjectiveId,
        _nodeIds
    ]] call FLO_fnc_log;
};

_activeNodes
