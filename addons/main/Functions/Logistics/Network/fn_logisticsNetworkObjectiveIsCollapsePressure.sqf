/*
 * Function: FLO_fnc_logisticsNetworkObjectiveIsCollapsePressure
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns true when an owned pressured objective is deteriorating badly
 *   enough to override normal supply-chain advance doctrine.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   BOOL - True when the objective is in collapse pressure
 */

params ["_net", "_objectiveId"];

if (_objectiveId == "") exitWith { false };

private _objective = FLO_Objectives get _objectiveId;
private _managedSide = _net get "_managedSide";
if ((_objective get "owner") isNotEqualTo _managedSide) exitWith { false };

private _friendlyCountKey = ["bluforCount", "opforCount"] select (_managedSide isEqualTo east);
private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);

private _friendlyCount = _objective get _friendlyCountKey;
private _enemyCount = _objective get _enemyCountKey;
if (_enemyCount <= 0) exitWith { false };
if !(_objective get "contested") exitWith { false };

(_friendlyCount / _enemyCount) < (_net get "REINFORCEMENT_OBJECTIVE_CONTESTED_COLLAPSE_FORCE_RATIO")
