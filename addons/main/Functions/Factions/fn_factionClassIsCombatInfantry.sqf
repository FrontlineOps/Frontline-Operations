/* Returns whether a public unit class is suitable for commander infantry pools. */
params ["_unitClass", ["_factionClass", "", [""]]];

if !(_unitClass isEqualType "") then {
    throw "Combat infantry eligibility requires a classname string";
};
if (_unitClass == "") exitWith { false };

private _cfg = configFile >> "CfgVehicles" >> _unitClass;
if !(isClass _cfg) exitWith { false };
if (getNumber (_cfg >> "scope") < 2) exitWith { false };
if !(_unitClass isKindOf "CAManBase") exitWith { false };
if (_factionClass != "" && {toLower (getText (_cfg >> "faction")) != toLower _factionClass}) exitWith { false };
if (toLower (getText (_cfg >> "simulation")) != "soldier") exitWith { false };

private _identity = toLower format [
    "%1 %2 %3 %4 %5 %6",
    _unitClass,
    getText (_cfg >> "displayName"),
    getText (_cfg >> "vehicleClass"),
    getText (_cfg >> "editorCategory"),
    getText (_cfg >> "editorSubcategory"),
    getText (_cfg >> "role")
];
private _rejected = false;
{
    if (_identity find _x >= 0) exitWith { _rejected = true; };
} forEach ["virtual", "story", "character", "survivor", "civilian", "pilot", "crew", "unarmed"];
if (_rejected) exitWith { false };

private _weapons = [];
_weapons append getArray (_cfg >> "weapons");
_weapons append getArray (_cfg >> "respawnWeapons");
private _hasCombatWeapon = false;
{
    private _weaponCfg = configFile >> "CfgWeapons" >> _x;
    if !(isClass _weaponCfg) then { continue };
    private _weaponType = getNumber (_weaponCfg >> "type");
    if (
        ((floor (_weaponType / 1)) mod 2) > 0
        || {((floor (_weaponType / 2)) mod 2) > 0}
        || {((floor (_weaponType / 4)) mod 2) > 0}
    ) exitWith {
        _hasCombatWeapon = true;
    };
} forEach _weapons;

_hasCombatWeapon
