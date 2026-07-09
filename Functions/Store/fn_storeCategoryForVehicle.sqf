params ["_className"];

private _cfg = configFile >> "CfgVehicles" >> _className;
if !(isClass _cfg) exitWith { "" };
if ((getNumber (_cfg >> "scope")) < 1) exitWith { "" };
if ((getNumber (_cfg >> "isBackpack")) isEqualTo 1) exitWith { "backpacks" };
if (_className isKindOf "CAManBase") exitWith { "" };
if (_className isKindOf "StaticWeapon") exitWith { "static" };
if (_className isKindOf "Tank") exitWith { "armor" };
if (_className isKindOf "Car") exitWith { "cars" };
if (_className isKindOf "Helicopter") exitWith { "helis" };
if (_className isKindOf "Plane") exitWith { "planes" };
if (_className isKindOf "Ship") exitWith { "naval" };
if (_className isKindOf "AllVehicles") exitWith { "other" };

""
