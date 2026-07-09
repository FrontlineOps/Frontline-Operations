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

if (!(_amount isEqualType 0)) then {
    throw format ["[SIDE_RES] Invalid base amount for %1 spending: %2", _type, _amount];
};

private _spendingTypes = _resourceObj get "SPENDING_TYPES";
private _typeData = _spendingTypes get _type;
if !(_typeData isEqualType [] && {(count _typeData) == 3}) then {
    throw format ["[SIDE_RES] Missing cost definition for spending type %1", _type];
};
_typeData params ["_multiplier", "_threshold", "_efficiencyLoss"];

if (!(_multiplier isEqualType 0) && {_threshold isEqualType 0} && {_efficiencyLoss isEqualType 0}) then {
    throw format ["[SIDE_RES] Invalid cost definition for spending type %1: %2", _type, _typeData];
};

private _efficiencies = _resourceObj get "_efficiencies";
private _efficiency = _efficiencies get _type;
if (!(_efficiency isEqualType 0)) then {
    throw format ["[SIDE_RES] Invalid efficiency for spending type %1: %2", _type, _efficiency];
};
if (_efficiency <= 0) then {
    throw format ["[SIDE_RES] Non-positive efficiency for spending type %1: %2", _type, _efficiency];
};

private _cost = _amount * _multiplier * (1 / _efficiency);

[_cost, _threshold, _efficiencyLoss, _efficiency]
