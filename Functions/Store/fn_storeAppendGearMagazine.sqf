params ["_itemsByCategory", "_seen", "_className"];

if !(isClass (configFile >> "CfgMagazines" >> _className)) exitWith {};

private _magazineCfg = configFile >> "CfgMagazines" >> _className;
private _category = if ([_magazineCfg] call FLO_fnc_storeIsMineMagazine) then {
    "mines"
} else {
    ["ammo", "misc"] select ([_magazineCfg] call FLO_fnc_storeIsItemBackedMagazine)
};

[_itemsByCategory, _seen, _className, "gear", _category] call FLO_fnc_storeAppendCatalogItem;
