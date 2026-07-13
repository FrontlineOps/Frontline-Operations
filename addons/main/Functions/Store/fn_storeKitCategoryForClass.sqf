params ["_className"];

if !(_className isEqualType "") then {
    throw "Store kit category lookup requires a classname string";
};
if (_className == "") exitWith { "" };

if (isClass (configFile >> "CfgGlasses" >> _className)) exitWith { "facewear" };

if (isClass (configFile >> "CfgMagazines" >> _className)) exitWith {
    private _cfg = configFile >> "CfgMagazines" >> _className;
    if ([_cfg] call FLO_fnc_storeIsMineMagazine) exitWith { "mines" };
    ["ammo", "misc"] select ([_cfg] call FLO_fnc_storeIsItemBackedMagazine)
};

if (isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
    private _cfg = configFile >> "CfgVehicles" >> _className;
    ["", "backpacks"] select (getNumber (_cfg >> "isBackpack") == 1)
};

if (isClass (configFile >> "CfgWeapons" >> _className)) exitWith {
    [_className] call FLO_fnc_storeCategoryForWeapon
};

""
