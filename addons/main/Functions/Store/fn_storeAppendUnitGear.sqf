params ["_itemsByCategory", "_seen", "_unitClass"];

if !(isClass (configFile >> "CfgVehicles" >> _unitClass)) exitWith {};

private _unitCfg = configFile >> "CfgVehicles" >> _unitClass;

private _weapons = [];
_weapons append getArray (_unitCfg >> "weapons");
_weapons append getArray (_unitCfg >> "respawnWeapons");

{
    [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendGearWeapon;
} forEach _weapons;

private _linkedItems = [];
_linkedItems append getArray (_unitCfg >> "linkedItems");
_linkedItems append getArray (_unitCfg >> "respawnLinkedItems");
_linkedItems append getArray (_unitCfg >> "items");
_linkedItems append getArray (_unitCfg >> "respawnItems");

{
    [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendGearWeapon;
} forEach _linkedItems;

private _magazines = [];
_magazines append getArray (_unitCfg >> "magazines");
_magazines append getArray (_unitCfg >> "respawnMagazines");

{
    [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendGearMagazine;
} forEach _magazines;

[_itemsByCategory, _seen, _unitCfg] call FLO_fnc_storeAppendContainerCargoItems;

[_itemsByCategory, _seen, getText (_unitCfg >> "uniformClass"), "gear", "uniforms"] call FLO_fnc_storeAppendCatalogItem;

private _backpack = getText (_unitCfg >> "backpack");
[_itemsByCategory, _seen, _backpack, "gear", "backpacks"] call FLO_fnc_storeAppendCatalogItem;

if ((_backpack isNotEqualTo "") && {isClass (configFile >> "CfgVehicles" >> _backpack)}) then {
    [_itemsByCategory, _seen, configFile >> "CfgVehicles" >> _backpack] call FLO_fnc_storeAppendContainerCargoItems;
};
