/* Derives one virtual group's public rank from persistent experience. */
params [["_experience", 0, [0]]];

if (_experience < 0 || {_experience > 100}) then {
    private _message = format ["Invalid group combat experience %1", _experience];
    ["GTN_COMBAT", 1, _message] call FLO_fnc_log;
    throw _message;
};
if (_experience < 25) exitWith { "GREEN" };
if (_experience < 55) exitWith { "REGULAR" };
if (_experience < 80) exitWith { "VETERAN" };
"ELITE"
