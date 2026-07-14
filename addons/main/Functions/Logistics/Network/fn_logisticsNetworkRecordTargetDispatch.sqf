/*
 * Function: FLO_fnc_logisticsNetworkRecordTargetDispatch
 * Author: Frontline Operations Development Group
 * Description:
 *   Records a successful reinforcement dispatch against an objective so
 *   subsequent picks can penalize recently serviced targets.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   BOOL - True when recorded
 */

params ["_net", "_objectiveId"];

if (_objectiveId == "") exitWith { false };

private _history = _net get "_recentReinforcementDispatches";
_history pushBack [_objectiveId, diag_tickTime + (_net get "REINFORCEMENT_RECENT_TARGET_WINDOW")];

_net set ["_recentReinforcementDispatches", _history];
_net set ["_lastReinforcementTarget", _objectiveId];

true
