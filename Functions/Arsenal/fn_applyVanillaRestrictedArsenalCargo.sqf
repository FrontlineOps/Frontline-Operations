/*
    Function: FLO_fnc_applyVanillaRestrictedArsenalCargo

    Description:
        Applies the FLO restricted arsenal whitelist to a vanilla arsenal object
        without registering another scroll action.

    Arguments:
        0: Arsenal object <OBJECT>

    Return:
        true when cargo was applied, false for null object
*/

params [["_box", objNull, [objNull]]];

if (isNull _box) exitWith { false };

private _allowedItems = FLO_arsenal_allowedItems;

private _weapons = _allowedItems select {
    _x isKindOf ["Rifle", configFile >> "CfgWeapons"] ||
    {_x isKindOf ["Launcher", configFile >> "CfgWeapons"]} ||
    {_x isKindOf ["Pistol", configFile >> "CfgWeapons"]}
};
private _items = _allowedItems select {
    _x isKindOf ["ItemCore", configFile >> "CfgWeapons"] ||
    {_x isKindOf ["Equipment", configFile >> "CfgWeapons"]} ||
    {_x isKindOf ["Uniform_Base", configFile >> "CfgWeapons"]} ||
    {_x isKindOf ["VestItem", configFile >> "CfgWeapons"]} ||
    {_x isKindOf ["HeadgearItem", configFile >> "CfgWeapons"]}
};
private _magazines = _allowedItems select {
    _x isKindOf ["CA_Magazine", configFile >> "CfgMagazines"]
};
private _backpacks = _allowedItems select {
    _x isKindOf ["Bag_Base", configFile >> "CfgVehicles"]
};

[_box, true, true] call BIS_fnc_removeVirtualWeaponCargo;
[_box, true, true] call BIS_fnc_removeVirtualItemCargo;
[_box, true, true] call BIS_fnc_removeVirtualMagazineCargo;
[_box, true, true] call BIS_fnc_removeVirtualBackpackCargo;

[_box, _weapons, true, false] call BIS_fnc_addVirtualWeaponCargo;
[_box, _items, true, false] call BIS_fnc_addVirtualItemCargo;
[_box, _magazines, true, false] call BIS_fnc_addVirtualMagazineCargo;
[_box, _backpacks, true, false] call BIS_fnc_addVirtualBackpackCargo;

true
