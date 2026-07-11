/*
 * Function: FLO_fnc_logisticsNetworkSetManagedSide
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies normalized managed-side context to a logistics network object.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Managed side <SIDE>
 *
 * Return Value:
 *   None
 */

params ["_net", "_managedSide"];

private _previousManagedSide = _net get "_managedSide";
_net set ["_managedSide", _managedSide];
_net set ["_managedSideKey", [_managedSide] call FLO_fnc_sideKey];
_net set ["_enemySide", [_managedSide] call FLO_fnc_opposingSide];

if (_previousManagedSide isNotEqualTo _managedSide) then {
    [_net] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
};
