params ["_treasury", ["_amount", 0, [0]]];

if (_amount < 0) then {
    throw format ["Affordability amount cannot be negative: %1", _amount];
};

([_treasury] call FLO_fnc_sideResourcesGetAvailable) >= _amount
