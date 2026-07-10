params [
    ["_sideKey", "", [""]],
    ["_plannedMineCount", 0, [0]]
];

private _treasury = FLO_SideResources get _sideKey;
private _costPerMine = FLO_MinefieldConfig get "resourceCostPerMine";
private _available = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _affordableMineCount = ((floor (_available / _costPerMine)) min _plannedMineCount) max 0;
private _predictedCost = _affordableMineCount * _costPerMine;

createHashMapFromArray [
    ["plannedMineCount", _plannedMineCount],
    ["affordableMineCount", _affordableMineCount],
    ["baseAmount", _predictedCost],
    ["predictedCost", _predictedCost],
    ["resourcesBefore", _available],
    ["threshold", 0],
    ["spendType", "FORTIFICATION"]
]
