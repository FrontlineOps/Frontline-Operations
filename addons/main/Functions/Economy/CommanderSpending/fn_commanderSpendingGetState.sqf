/* Builds the current side-neutral commander treasury posture from authoritative state. */
params ["_treasury"];

private _policy = _treasury get "COMMANDER_SPENDING_POLICY";
private _balance = _treasury get "_balance";
private _committed = [_treasury] call FLO_fnc_sideResourcesGetCommitted;
private _available = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _incomeCycle = _treasury get "_lastIncome";
private _incomeInterval = _treasury get "UPDATE_INTERVAL";
if !(_incomeInterval isEqualType 0 && {_incomeInterval > 0}) then {
    throw format ["Invalid %1 commander income interval: %2", _treasury get "_sideKey", _incomeInterval];
};
private _incomePerMinute = (_incomeCycle * 60) / _incomeInterval;

private _reserveFloor = (_policy get "reserveMinimum")
    max (round (_balance * (_policy get "reserveBalanceFraction")))
    max (round (_incomePerMinute * ((_policy get "reserveIncomeSeconds") / 60)));
private _emergencyReserve = _policy get "emergencyReserve";
private _developmentIncomeBasis = (
    _incomePerMinute * ((_policy get "developmentIncomeHorizonSeconds") / 60)
) max (_policy get "developmentBootstrapIncome");
private _balancedRunway = (_policy get "balancedRunwayMinimum")
    max (_incomePerMinute * ((_policy get "balancedRunwaySeconds") / 60));
private _surplusFloor = _reserveFloor + _balancedRunway;
private _posture = "SURPLUS";
if (_available <= _emergencyReserve) then {
    _posture = "EMERGENCY";
} else {
    if (_available <= _reserveFloor) then {
        _posture = "CONSERVE";
    } else {
        if (_available <= _surplusFloor) then {
            _posture = "BALANCED";
        };
    };
};

createHashMapFromArray [
    ["sideKey", _treasury get "_sideKey"],
    ["posture", _posture],
    ["balance", _balance],
    ["committed", _committed],
    ["available", _available],
    ["incomeCycle", _incomeCycle],
    ["incomePerMinute", round _incomePerMinute],
    ["reserveFloor", _reserveFloor],
    ["emergencyReserve", _emergencyReserve],
    ["surplusFloor", _surplusFloor],
    ["developmentIncomeBasis", _developmentIncomeBasis]
]
