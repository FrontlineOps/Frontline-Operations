params ["_className", "_category", "_entryKind"];

if (_entryKind isEqualTo "supply") exitWith { FLO_StoreSupplyShipmentCost };

if (_entryKind isEqualTo "recruit") exitWith {
    private _text = toLower format [
        "%1 %2",
        _className,
        getText (configFile >> "CfgVehicles" >> _className >> "displayName")
    ];
    private _price = 100;
    if ((_text find "medic") >= 0) then { _price = _price + 50 };
    if ((_text find "engineer") >= 0) then { _price = _price + 75 };
    if (((_text find "at") >= 0) || {(_text find "missile") >= 0}) then { _price = _price + 125 };
    _price
};

if (_entryKind isEqualTo "vehicle") exitWith {
    private _legacyPrice = [_className] call FLO_fnc_storeLegacyVehiclePrice;
    if (_legacyPrice > -1) exitWith { _legacyPrice };

    switch (_category) do {
        case "cars": { 500 };
        case "armor": { 3500 };
        case "helis": { 4500 };
        case "planes": { 8000 };
        case "naval": { 800 };
        case "static": { 700 };
        default { 1000 };
    }
};

if ((toLower _className) in FLO_StoreFreeItemClasses) exitWith { 0 };

private _base = switch (_category) do {
    case "primary": { 40 };
    case "handgun": { 25 };
    case "secondary": { 650 };
    case "uniforms": { 40 };
    case "vests": { 120 };
    case "headgear": { 40 };
    case "facewear": { 20 };
    case "backpacks": { 80 };
    case "attachments": { 75 };
    case "ammo": { 10 };
    case "mines": { 140 };
    case "misc": { 25 };
    default { 50 };
};

private _mass = 0;

if (isClass (configFile >> "CfgWeapons" >> _className)) then {
    private _cfg = configFile >> "CfgWeapons" >> _className;
    _mass = getNumber (_cfg >> "ItemInfo" >> "mass");
    if (_mass <= 0) then {
        _mass = getNumber (_cfg >> "WeaponSlotsInfo" >> "mass");
    };
};

if (isClass (configFile >> "CfgMagazines" >> _className)) then {
    _mass = getNumber (configFile >> "CfgMagazines" >> _className >> "mass");
};

if (isClass (configFile >> "CfgVehicles" >> _className)) then {
    _mass = getNumber (configFile >> "CfgVehicles" >> _className >> "maximumLoad");
};

5 max ((ceil ((_base + (ceil (_mass / 6))) / 5)) * 5)
