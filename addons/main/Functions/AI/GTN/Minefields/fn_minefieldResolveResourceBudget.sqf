/*
 * Function: FLO_fnc_minefieldResolveResourceBudget
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves how many planned mines a side commander can afford this cycle
 *   using the shared side-resource system.
 *
 * Arguments:
 * 0: Side key <STRING>
 * 1: Planned mine count <SCALAR>
 *
 * Return Value:
 * HASHMAP
 */

params [
    ["_sideKey", ""],
    ["_plannedMineCount", 0]
];

private _resourceObj = FLO_SideResources get _sideKey;
private _spendType = FLO_MinefieldConfig get "resourceSpendType";
private _costPerMine = FLO_MinefieldConfig get "resourceCostPerMine";
private _resourcesBefore = _resourceObj get "_resources";
private _spendingTypeData = (_resourceObj get "SPENDING_TYPES") get _spendType;
_spendingTypeData params ["_multiplier", "_threshold"];
private _efficiency = (_resourceObj get "_efficiencies") get _spendType;

private _affordableMineCount = 0;
private _baseAmount = 0;
private _predictedCost = 0;

if (_plannedMineCount > 0 && {_resourcesBefore >= _threshold}) then {
    private _maxAffordableBaseAmount = floor ((_resourcesBefore * _efficiency) / _multiplier);
    _affordableMineCount = ((floor (_maxAffordableBaseAmount / _costPerMine)) min _plannedMineCount) max 0;
    _baseAmount = _affordableMineCount * _costPerMine;

    if (_baseAmount > 0) then {
        _predictedCost = ([_resourceObj, _baseAmount, _spendType] call FLO_fnc_sideResourcesCalculateCost) select 0;
    };
};

createHashMapFromArray [
    ["plannedMineCount", _plannedMineCount],
    ["affordableMineCount", _affordableMineCount],
    ["baseAmount", _baseAmount],
    ["predictedCost", _predictedCost],
    ["resourcesBefore", _resourcesBefore],
    ["threshold", _threshold],
    ["spendType", _spendType]
]
