params ["_className", "_category"];

if !(_className isEqualType "" && {_category isEqualType ""}) then {
    throw "Store kit display-name lookup requires string arguments";
};

private _cfg = switch (_category) do {
    case "ammo";
    case "mines": { configFile >> "CfgMagazines" >> _className };
    case "misc": {
        if (isClass (configFile >> "CfgWeapons" >> _className)) then {
            configFile >> "CfgWeapons" >> _className
        } else {
            configFile >> "CfgMagazines" >> _className
        }
    };
    case "backpacks": { configFile >> "CfgVehicles" >> _className };
    case "facewear": { configFile >> "CfgGlasses" >> _className };
    default { configFile >> "CfgWeapons" >> _className };
};

private _name = getText (_cfg >> "displayName");
if (_name == "") then { _name = _className; };
_name
