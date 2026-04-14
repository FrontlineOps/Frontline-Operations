/*
    Function: FLO_fnc_isHeavyWeapon
    
    Description:
        Determines if a classname represents a "Heavy Weapon" (Launcher)
        that should be restricted to the heavy weapons crate.
        
        Uses configuration values (Damage/Guidance) to detect heavy weapons        
    Parameter(s):
        _weapon - Classname to check [String]
        
    Returns:
        Boolean - True if heavy weapon
*/
params ["_weapon"];

if (_weapon == "") exitWith {false};

private _cfgWeapon = configFile >> "CfgWeapons" >> _weapon;
if (!isClass _cfgWeapon) exitWith {false};

// Check for Guidance Capability
// Weapons capable of locking targets (Titan, Javelin, Metis, Vorona, Igla, Stinger)
if (getNumber (_cfgWeapon >> "lockingTarget") == 1) exitWith {true};

// Check Ammo Damage Threshold
// If unguided, check if the projectile yields high damage (checking the default magazine)
private _magazines = getArray (_cfgWeapon >> "magazines");
if (count _magazines == 0) exitWith {false};

// Check the first magazine's ammo
private _firstMag = _magazines select 0;
if (_firstMag == "") exitWith {false};

private _ammo = getText (configFile >> "CfgMagazines" >> _firstMag >> "ammo");
if (_ammo == "") exitWith {false};

// Get Hit value (Direct Hit Damage)
private _hit = getNumber (configFile >> "CfgAmmo" >> _ammo >> "hit");

// Threshold: 150
// Standard Rifle: ~10-15
// .50 Cal: ~35-50
// 40mm HEDP: ~50-80 (Explosive focus)
// Light AT: ~80-150
// Heavy AT: >150 (Titan ~800, RPG-32 ~350, PCML ~500)
if (_hit > 150) exitWith {true};

false