/*
    Function: FLO_fnc_finalizeCrate
    
    Description: Finalizes crate placement and adds items to the crate
    
    Parameter(s):
        _crate - The crate object
        _pos - The final position for the crate
        _dir - The final direction for the crate
        _items - Array of items to be added to the crate
        
    Returns:
        None
*/
params ["_crate", "_pos", "_dir", "_items"];

// Make crate visible
_crate hideObject false;
_crate enableSimulation true;

// Set position
_crate setPosASL _pos;
_crate setDir _dir;

// Mark this crate to be saved by the mission save system
_crate setVariable ["FLO_save_crate", true, true];

// Add items
clearWeaponCargoGlobal _crate;
clearMagazineCargoGlobal _crate;
clearItemCargoGlobal _crate;
clearBackpackCargoGlobal _crate;

{
    private ["_item", "_count"];
    
    if (_x isEqualType []) then {
        _x params ["_i", "_c"];
        _item = _i;
        _count = _c;
    } else {
        _item = _x;
        // Default counts if only classname provided
        if (isClass (configFile >> "CfgMagazines" >> _item)) then {
            _count = 10;
        } else {
            if (isClass (configFile >> "CfgWeapons" >> _item)) then {
                _count = 2; // 2 Launchers/Rifles per crate
            } else {
                if (isClass (configFile >> "CfgVehicles" >> _item)) then {
                    _count = 5; // Backpacks
                } else {
                    _count = 10; // Generic items
                };
            };
        };
    };
    
    if (isClass (configFile >> "CfgWeapons" >> _item)) then {
        _crate addWeaponCargoGlobal [_item, _count];
    } else {
        if (isClass (configFile >> "CfgMagazines" >> _item)) then {
            _crate addMagazineCargoGlobal [_item, _count];
        } else {
            if (isClass (configFile >> "CfgVehicles" >> _item)) then {
                _crate addBackpackCargoGlobal [_item, _count];
            } else {
                _crate addItemCargoGlobal [_item, _count];
            };
        };
    };
} forEach _items;

// Make draggable with ACE
[_crate, true, [0, 2, 0], 0] remoteExec ["ace_dragging_fnc_setDraggable", 0, _crate];

// Allow damage after a delay
[{
    params ["_crate"];
    _crate allowDamage true;
}, [_crate], 5] call CBA_fnc_waitAndExecute;
