/*
 * Function: FLO_fnc_sideResourcesCalculateCost
 * Author: Frontline Operations Development Group
 * Description:
 *   Calculates the effective resource cost and thresholds for a spending type.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *   1: Base amount <NUMBER>
 *   2: Spending type <STRING>
 *
 * Return Value:
 *   [cost, threshold, efficiencyLoss, efficiency] <ARRAY>
 *
 * Example:
 *   private _costData = [_resourceObj, 12, "reinforcement"] call FLO_fnc_sideResourcesCalculateCost;
 */

params ["_resourceObj", "_amount", "_type"];

private _spendingTypes = _resourceObj get "SPENDING_TYPES";
private _typeData = _spendingTypes get _type;
_typeData params ["_multiplier", "_threshold", "_efficiencyLoss"];

private _efficiencies = _resourceObj get "_efficiencies";
private _efficiency = _efficiencies get _type;
private _cost = _amount * _multiplier * (1 / _efficiency);

[_cost, _threshold, _efficiencyLoss, _efficiency]
