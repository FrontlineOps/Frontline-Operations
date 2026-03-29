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

_deliveryCounts set [_deliveryObjectiveId, _deliveryCount + 1];
_net set ["_supplyNodeDeliveries", _deliveryCounts];

private _activeNodes = [_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
private _isActive = _deliveryObjectiveId in _activeNodes;

["LOGISTICS", 2, format [
    "Confirmed reinforcement delivery for %1 at %2 (count=%3)%4",
    _net get "_managedSideKey",
    _deliveryObjectiveId,
    _deliveryCount + 1,
    if (_isActive && {!_wasActive}) then { " | promoted to forward supply node" } else { "" }
]] call FLO_fnc_log;

true
