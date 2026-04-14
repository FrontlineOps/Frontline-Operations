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

private _ctx = [_managedSide] call FLO_fnc_gtnSideContext;
_net set ["_managedSide", _ctx get "ownSide"];
_net set ["_managedSideKey", _ctx get "sideKey"];
_net set ["_enemySide", _ctx get "enemySide"];
