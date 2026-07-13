params [
    "_treasury",
    ["_remainingCost", 0, [0]]
];

if (_remainingCost <= 0) then {
    throw format ["Development funding remaining cost must be positive, got %1", _remainingCost];
};

private _state = [_treasury] call FLO_fnc_commanderSpendingGetState;
private _posture = _state get "posture";
if !(_posture in ["EMERGENCY", "CONSERVE", "BALANCED", "SURPLUS"]) then {
    throw format ["Invalid commander posture for Development funding: %1", _posture];
};
if (_posture == "EMERGENCY") exitWith { 0 };

private _policy = _treasury get "COMMANDER_SPENDING_POLICY";
private _protectedFloor = _state get "reserveFloor";
private _budget = _remainingCost;
if (_posture == "CONSERVE") then {
    _protectedFloor = _state get "emergencyReserve";
    private _incomeBasis = (_state get "incomeCycle") max (_policy get "bootstrapWindowBudget");
    _budget = (_policy get "developmentFundingMinimums") get "CONSERVE";
    _budget = _budget max (round (_incomeBasis * ((_policy get "developmentFundingFractions") get "CONSERVE")));
};
if (_posture == "BALANCED") then {
    private _incomeBasis = (_state get "incomeCycle") max (_policy get "bootstrapWindowBudget");
    _budget = (_policy get "developmentFundingMinimums") get "BALANCED";
    _budget = _budget max (round (_incomeBasis * ((_policy get "developmentFundingFractions") get "BALANCED")));
};

private _fundingRoom = ((_state get "available") - _protectedFloor) max 0;
(_remainingCost min _budget) min _fundingRoom
