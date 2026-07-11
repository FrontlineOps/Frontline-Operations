params ["_treasury"];

private _available = (_treasury get "_balance") - ([_treasury] call FLO_fnc_sideResourcesGetCommitted);
if (_available < -0.001) then {
    throw format ["Treasury %1 has overcommitted funds: %2", _treasury get "_sideKey", _available];
};

_available max 0
