/* Derives the public rank label from persistent experience. */
params [["_experience", 0, [0]]];

if (_experience < 0 || {_experience > 100}) then {
    throw format ["Invalid formation experience %1", _experience];
};
if (_experience < 25) exitWith { "GREEN" };
if (_experience < 55) exitWith { "REGULAR" };
if (_experience < 80) exitWith { "VETERAN" };
"ELITE"
