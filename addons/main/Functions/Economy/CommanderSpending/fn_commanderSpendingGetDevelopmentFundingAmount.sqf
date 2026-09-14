params [
    "_treasury",
    ["_remainingCost", 0, [0]]
];

if (!finite _remainingCost || {_remainingCost <= 0}) then {
    throw format ["Development funding remaining cost must be positive, got %1", _remainingCost];
};

private _state = [_treasury] call FLO_fnc_commanderSpendingGetState;
private _posture = _state get "posture";
if !(_posture in ["EMERGENCY", "CONSERVE", "BALANCED", "SURPLUS"]) then {
    throw format ["Invalid commander posture for Development funding: %1", _posture];
};
// Construction never spends recovery capital or the next replacement batch.
if (_posture in ["EMERGENCY", "CONSERVE"]) exitWith { 0 };
private _fundingRoom = _state get "developmentAvailable";
private _budget = _remainingCost;
if (_posture == "BALANCED") then {
    _budget = floor ((_state get "developmentIncomeBasis") * (((_treasury get "COMMANDER_SPENDING_POLICY") get "developmentFundingFractions") get "BALANCED"));
};
(_remainingCost min _budget) min _fundingRoom
