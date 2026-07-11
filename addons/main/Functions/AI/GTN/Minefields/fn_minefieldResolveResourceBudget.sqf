params [
    ["_sideKey", "", [""]],
    ["_plannedMineCount", 0, [0]],
    ["_objectiveId", "", [""]]
];

private _treasury = FLO_SideResources get _sideKey;
private _network = FLO_Logistics_Networks get _sideKey;
private _costPerMine = FLO_MinefieldConfig get "resourceCostPerMine";
private _available = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _urgency = [_network, _objectiveId] call FLO_fnc_logisticsNetworkGetReplacementUrgency;
private _spendingDecision = [
    _treasury,
    _costPerMine,
    "FORTIFICATION",
    _urgency,
    createHashMapFromArray [
        ["strategic", false],
        ["commitment", false],
        ["reserved", false],
        ["referenceId", _objectiveId]
    ]
] call FLO_fnc_commanderSpendingEvaluate;
private _policyMineCount = floor ((_spendingDecision get "maximumAmount") / _costPerMine);
private _affordableMineCount = ((floor (_available / _costPerMine)) min _policyMineCount min _plannedMineCount) max 0;
private _predictedCost = _affordableMineCount * _costPerMine;

createHashMapFromArray [
    ["plannedMineCount", _plannedMineCount],
    ["affordableMineCount", _affordableMineCount],
    ["baseAmount", _predictedCost],
    ["predictedCost", _predictedCost],
    ["resourcesBefore", _available],
    ["threshold", _spendingDecision get "requiredReserve"],
    ["urgency", _urgency],
    ["policyReason", _spendingDecision get "reason"],
    ["spendType", "FORTIFICATION"]
]
