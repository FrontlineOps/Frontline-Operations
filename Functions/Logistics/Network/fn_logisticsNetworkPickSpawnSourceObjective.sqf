/*
 * Function: FLO_fnc_logisticsNetworkPickSpawnSourceObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks an active supply-chain source objective behind the defended
 *   delivery objective.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Target objective ID <STRING>
 *   2: Blocked objective IDs <ARRAY> - Default []
 *
 * Return Value:
 *   STRING - Selected source objective ID or empty string
 */

params ["_net", "_targetObjId", ["_blockedObjectives", []]];

if (_targetObjId == "") exitWith { "" };

[_net] call FLO_fnc_logisticsNetworkRefreshSupplyChain;
[_net, _targetObjId, _blockedObjectives] call FLO_fnc_logisticsNetworkFindSupplySourceObjective
