/*
 * Function: FLO_fnc_logisticsNetworkRecordDelivery
 * Author: Frontline Operations Development Group
 * Description:
 *   Records a confirmed reinforcement delivery at an objective. Successful
 *   deliveries are what promote a friendly objective into a forward supply
 *   node once local stability conditions are met.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Delivery objective ID <STRING>
 *
 * Return Value:
 *   BOOL - True when the delivery was recorded
 */

params ["_net", "_deliveryObjectiveId"];

if (_deliveryObjectiveId == "") exitWith { false };
if !(_deliveryObjectiveId in FLO_Objectives) exitWith { false };

[_net] call FLO_fnc_logisticsNetworkRefreshManagedSide;

private _managedSide = _net get "_managedSide";
private _deliveryObjective = FLO_Objectives get _deliveryObjectiveId;
if ((_deliveryObjective get "owner") isNotEqualTo _managedSide) exitWith { false };

private _deliveryCounts = _net get "_supplyNodeDeliveries";
private _wasActive = _deliveryObjectiveId in (_net get "_activeSupplyNodes");
private _deliveryCount = if (_deliveryObjectiveId in _deliveryCounts) then {
    _deliveryCounts get _deliveryObjectiveId
} else {
    0
};
private _nextDeliveryCount = _deliveryCount + 1;

_deliveryCounts set [_deliveryObjectiveId, _nextDeliveryCount];
_net set ["_supplyNodeDeliveries", _deliveryCounts];

private _activeNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
private _isActive = _deliveryObjectiveId in _activeNodes;
private _promotionSuffix = "";

if (_isActive && {!_wasActive}) then {
    _promotionSuffix = " | promoted to forward supply node";
};

if !_isActive then {
    private _minDeliveries = _net get "SUPPLY_NODE_MIN_DELIVERIES";
    if (_nextDeliveryCount >= _minDeliveries) then {
        private _friendlyCountKey = if (_managedSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
        private _friendlyCount = _deliveryObjective get _friendlyCountKey;
        private _minActiveFriendlyCount = _net get "SUPPLY_NODE_MIN_ACTIVE_FRIENDLY_COUNT";
        private _promotionDeliveryCount = _net get "SUPPLY_NODE_PROMOTION_DELIVERY_COUNT";
        private _routeInfo = _net get "_supplyRouteInfo";
        private _inRoute = _deliveryObjectiveId in _routeInfo;
        private _parentObjective = "";
        private _depth = -1;

        if (_inRoute) then {
            private _nodeInfo = _routeInfo get _deliveryObjectiveId;
            _parentObjective = _nodeInfo get "parentObjective";
            _depth = _nodeInfo get "depth";
        };

        _promotionSuffix = format [
            " | not promoted: inRoute=%1 contested=%2 friendly=%3/%4 deliveries=%5/%6 parent=%7 depth=%8",
            _inRoute,
            _deliveryObjective get "contested",
            _friendlyCount,
            _minActiveFriendlyCount,
            _nextDeliveryCount,
            _promotionDeliveryCount,
            _parentObjective,
            _depth
        ];
    };
};

["LOGISTICS", 2, format [
    "Confirmed reinforcement delivery for %1 at %2 (count=%3)%4",
    _net get "_managedSideKey",
    _deliveryObjectiveId,
    _nextDeliveryCount,
    _promotionSuffix
]] call FLO_fnc_log;

true
