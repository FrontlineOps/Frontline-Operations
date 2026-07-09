/*
 * Function: FLO_fnc_logisticsNetworkObjectiveIsFrontlinePressure
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns true when an owned pressured objective sits on the current
 *   frontline or immediately beyond it, so normal enemy pressure on that
 *   branch can override deeper supply-chain expansion.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   BOOL - True when the objective is frontline pressure
 */

params ["_net", "_objectiveId"];

if (_objectiveId == "") exitWith { false };

private _objective = FLO_Objectives get _objectiveId;
private _managedSide = _net get "_managedSide";
if ((_objective get "owner") isNotEqualTo _managedSide) exitWith { false };

private _enemyCountKey = ["opforCount", "bluforCount"] select (_managedSide isEqualTo east);
if ((_objective get _enemyCountKey) <= 0) exitWith { false };

private _role = [_net, _objectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
if ((_role get "depth") < 0) exitWith { false };

(_role get "isActiveNode")
|| { _role get "isAdvanceCandidate" }
|| { (_role get "activeLinkedObjectives") isNotEqualTo [] }
