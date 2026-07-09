params ["_className"];

private _cfg = configFile >> "CfgWeapons" >> _className;
if !(isClass _cfg) exitWith { "" };

private _weaponType = getNumber (_cfg >> "type");
if (((floor (_weaponType / 1)) mod 2) > 0) exitWith { "primary" };
if (((floor (_weaponType / 2)) mod 2) > 0) exitWith { "handgun" };
if (((floor (_weaponType / 4)) mod 2) > 0) exitWith { "secondary" };

private _itemType = _className call BIS_fnc_itemType;
private _group = _itemType select 0;
private _kind = _itemType select 1;

if (_kind isEqualTo "Uniform") exitWith { "uniforms" };
if (_kind isEqualTo "Vest") exitWith { "vests" };
if (_kind isEqualTo "Headgear") exitWith { "headgear" };
if (_kind in ["AccessoryMuzzle", "AccessoryPointer", "AccessorySights", "AccessoryBipod"]) exitWith { "attachments" };
if (_kind in ["Binocular", "LaserDesignator"]) exitWith { "misc" };
if (_group in ["Item", "Equipment", "Mine", "Magazine"]) exitWith { "misc" };

""
