/* Calculates the currently reservable budget for one new operation role. */
params [
    "_director",
    ["_sideKey", "", [""]],
    ["_priorityRole", "SUPPORTING_EFFORT", [""]],
    ["_availableOverride", -1, [0]],
    ["_capRemainingOverride", -1, [0]]
];

if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["FLO_fnc_campaignCalculateOperationBudget: invalid side %1", _sideKey];
};
if !(_priorityRole in ["MAIN_EFFORT", "SUPPORTING_EFFORT"]) then {
    throw format ["FLO_fnc_campaignCalculateOperationBudget: invalid role %1", _priorityRole];
};

private _treasury = FLO_SideResources get _sideKey;
private _config = _director get "_config";
private _available = _availableOverride;
if (_available < 0) then {
    _available = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
};

private _operationCommitted = 0;
{
    private _reservation = _y;
    if ((_reservation get "category") == "OPERATION") then {
        _operationCommitted = _operationCommitted + (_reservation get "remaining");
    };
} forEach (_treasury get "_reservations");

private _capRemaining = _capRemainingOverride;
if (_capRemaining < 0) then {
    _capRemaining = (floor ((_treasury get "_balance") * (_config get "operationCommitmentFraction"))) - _operationCommitted;
};

private _main = _priorityRole == "MAIN_EFFORT";
private _fraction = [
    _config get "operationSupportBudgetFraction",
    _config get "operationMainBudgetFraction"
] select _main;
private _minimum = [
    _config get "operationSupportBudgetMinimum",
    _config get "operationMainBudgetMinimum"
] select _main;
private _maximum = [
    _config get "operationSupportBudgetMaximum",
    _config get "operationMainBudgetMaximum"
] select _main;

private _budget = round (_available * _fraction);
_budget = ((_budget max _minimum) min _maximum) min _available min (_capRemaining max 0);
if (_budget < _minimum) exitWith { 0 };
private _spendingDecision = [
    _treasury,
    _budget,
    "OPERATION",
    "OPERATIONAL",
    createHashMapFromArray [
        ["strategic", true],
        ["commitment", true],
        ["reserved", false],
        ["referenceId", _priorityRole]
    ]
] call FLO_fnc_commanderSpendingEvaluate;
if !(_spendingDecision get "allowed") exitWith { 0 };
_budget
