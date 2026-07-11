params ["_itemsByCategory", "_seen", "_containerCfg"];

private _transportMagazinesCfg = _containerCfg >> "TransportMagazines";
private _directMagazine = getText (_transportMagazinesCfg >> "magazine");
[_itemsByCategory, _seen, _directMagazine] call FLO_fnc_storeAppendGearMagazine;

{
    [_itemsByCategory, _seen, getText (_x >> "magazine")] call FLO_fnc_storeAppendGearMagazine;
} forEach ("true" configClasses _transportMagazinesCfg);

private _transportItemsCfg = _containerCfg >> "TransportItems";
private _directItem = getText (_transportItemsCfg >> "name");

if (isClass (configFile >> "CfgMagazines" >> _directItem)) then {
    [_itemsByCategory, _seen, _directItem] call FLO_fnc_storeAppendGearMagazine;
} else {
    [_itemsByCategory, _seen, _directItem] call FLO_fnc_storeAppendGearWeapon;
};

{
    private _itemClass = getText (_x >> "name");

    if (isClass (configFile >> "CfgMagazines" >> _itemClass)) then {
        [_itemsByCategory, _seen, _itemClass] call FLO_fnc_storeAppendGearMagazine;
    } else {
        [_itemsByCategory, _seen, _itemClass] call FLO_fnc_storeAppendGearWeapon;
    };
} forEach ("true" configClasses _transportItemsCfg);

private _transportWeaponsCfg = _containerCfg >> "TransportWeapons";
private _directWeapon = getText (_transportWeaponsCfg >> "weapon");
[_itemsByCategory, _seen, _directWeapon] call FLO_fnc_storeAppendGearWeapon;

{
    [_itemsByCategory, _seen, getText (_x >> "weapon")] call FLO_fnc_storeAppendGearWeapon;
} forEach ("true" configClasses _transportWeaponsCfg);
