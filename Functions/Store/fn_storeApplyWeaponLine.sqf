params ["_unit", "_className", "_category", ["_quantity", 1, [1]]];

private _overflow = [];
private _count = floor _quantity;

if (isNull _unit) exitWith { _overflow };
if (_className isEqualTo "") exitWith { _overflow };
if (_count < 1) exitWith { _overflow };

private _currentWeapon = switch (_category) do {
    case "primary": { primaryWeapon _unit };
    case "handgun": { handgunWeapon _unit };
    case "secondary": { secondaryWeapon _unit };
    default { "" };
};

if (_currentWeapon isNotEqualTo "") then {
    _unit removeWeapon _currentWeapon;
};

_unit addWeapon _className;

private _equippedWeapon = switch (_category) do {
    case "primary": { primaryWeapon _unit };
    case "handgun": { handgunWeapon _unit };
    case "secondary": { secondaryWeapon _unit };
    default { "" };
};

if (_equippedWeapon isNotEqualTo _className) then {
    if (_currentWeapon isNotEqualTo "") then {
        _unit addWeapon _currentWeapon;
    };

    _overflow pushBack _className;
};

for "_i" from 2 to _count do {
    _overflow pushBack _className;
};

_overflow
