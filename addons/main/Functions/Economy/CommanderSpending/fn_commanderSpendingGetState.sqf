/* Builds the current side-neutral commander treasury posture from authoritative state. */
params ["_treasury"];

private _policy = _treasury get "COMMANDER_SPENDING_POLICY";
private _balance = _treasury get "_balance";
private _committed = [_treasury] call FLO_fnc_sideResourcesGetCommitted;
private _available = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _incomeCycle = _treasury get "_lastIncome";
private _windowSeconds = _policy get "windowSeconds";
private _now = dateToNumber date;
private _recentCommanderSpend = 0;
private _recentByCategory = createHashMap;
private _recentCountByCategory = createHashMap;

{
    if ((_x get "actor") != "COMMANDER") then { continue };
    if !((_x get "kind") in ["COMMIT", "DEBIT"]) then { continue };
    private _ageSeconds = [(_x get "dateNum"), _now] call FLO_fnc_dateNumberDeltaSeconds;
    if (_ageSeconds < 0 || {_ageSeconds > _windowSeconds}) then { continue };

    private _amount = _x get "amount";
    private _category = _x get "category";
    _recentCommanderSpend = _recentCommanderSpend + _amount;
    private _categorySpend = if (_category in _recentByCategory) then {
        _recentByCategory get _category
    } else {
        0
    };
    _recentByCategory set [_category, _categorySpend + _amount];
    private _categoryCount = if (_category in _recentCountByCategory) then {
        _recentCountByCategory get _category
    } else {
        0
    };
    _recentCountByCategory set [_category, _categoryCount + 1];
} forEach (_treasury get "_ledger");

private _reserveFloor = (_policy get "reserveMinimum")
    max (round (_balance * (_policy get "reserveBalanceFraction")))
    max (round (_incomeCycle * (_policy get "reserveIncomeCycles")));
private _emergencyReserve = _policy get "emergencyReserve";
private _baseWindowBudget = _incomeCycle max (_policy get "bootstrapWindowBudget");
private _balancedRunway = (_policy get "balancedRunwayMinimum") max (_incomeCycle * 2);
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
    ["incomePerMinute", round ((_incomeCycle * 60) / (_treasury get "UPDATE_INTERVAL"))],
    ["reserveFloor", _reserveFloor],
    ["emergencyReserve", _emergencyReserve],
    ["surplusFloor", _surplusFloor],
    ["recentCommanderSpend", _recentCommanderSpend],
    ["recentByCategory", _recentByCategory],
    ["recentCountByCategory", _recentCountByCategory],
    ["baseWindowBudget", _baseWindowBudget],
    ["windowSeconds", _windowSeconds]
]
