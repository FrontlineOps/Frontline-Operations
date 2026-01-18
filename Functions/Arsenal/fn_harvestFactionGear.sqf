/*
    Function: FLO_fnc_harvestFactionGear
    
    Description:
        Harvests all weapons, items, magazines, uniforms, vests, and backpacks 
        from the defined player faction units.
        
    Returns:
        Array - List of all unique classnames
*/

private _harvestedGear = [];
private _processedUnits = [];

// List of variables to check
private _unitVars = [
    "F_Officer", 
    "F_Assault_Eng", "F_Assault_TL", "F_Assault_SL", "F_Assault_Eod",
    "F_Assault_Mrk", "F_Assault_AT", "F_Assault_Amm", "F_Assault_Mg", 
    "F_Assault_Med", "F_Assault_Uav", 
    "F_Recon_Snp", "F_Recon_Sct", 
    "F_Recon_TL", "F_Recon_Mrk", "F_Recon_AT", "F_Recon_Mg", 
    "F_Recon_Eod", "F_Recon_Med", "F_Recon_Eng", 
    "F_Diver_TL", "F_Diver_Rfl", "F_Diver_Eod"
];

// Helper to extract items from a container class (like a pre-configured backpack)
private _fnc_processContainer = {
    params ["_containerClass"];
    
    if (_containerClass == "") exitWith {};
    
    private _cfgContent = configFile >> "CfgVehicles" >> _containerClass;
    if (!isClass _cfgContent) exitWith {};
    
    // TransportMagazines
    private _transportMagazines = "true" configClasses (_cfgContent >> "TransportMagazines");
    {
        _harvestedGear pushBack (getText (_x >> "magazine"));
    } forEach _transportMagazines;
    
    // TransportItems
    private _transportItems = "true" configClasses (_cfgContent >> "TransportItems");
    {
        _harvestedGear pushBack (getText (_x >> "name"));
    } forEach _transportItems;
    
    // TransportWeapons
    private _transportWeapons = "true" configClasses (_cfgContent >> "TransportWeapons");
    {
        private _wep = getText (_x >> "weapon");
        if (_wep != "") then {
            [_wep] call _fnc_processWeapon;
        };
    } forEach _transportWeapons;

    // TransportBackpacks (Nested backpacks - rare but possible)
    private _transportBackpacks = "true" configClasses (_cfgContent >> "TransportBackpacks");
    {
        private _bag = getText (_x >> "backpack");
        if (_bag != "") then {
            _harvestedGear pushBack _bag;
            [_bag] call _fnc_processContainer;
        };
    } forEach _transportBackpacks;
};

// Helper to harvest a weapon and its linked items (attachments)
private _fnc_processWeapon = {
    params ["_weaponClass"];
    
    if (_weaponClass == "") exitWith {};
    _harvestedGear pushBack _weaponClass;
    
    private _cfgWeapon = configFile >> "CfgWeapons" >> _weaponClass;
    if (isClass _cfgWeapon) then {
        // Harvest LinkedItems (Optics, Pointers, Muzzles)
        private _linkedItems = "true" configClasses (_cfgWeapon >> "LinkedItems");
        {
            private _item = getText (_x >> "item");
            if (_item != "") then { _harvestedGear pushBack _item; };
        } forEach _linkedItems;
    };
};

{
    // Check if variable exists and is a string (classname)
    if (!isNil _x) then {
        private _unitClass = missionNamespace getVariable [_x, ""];
        
        if (_unitClass != "" && {isClass (configFile >> "CfgVehicles" >> _unitClass)}) then {
            // Avoid processing same class multiple times
            if !(_unitClass in _processedUnits) then {
                _processedUnits pushBack _unitClass;
                
                private _cfg = configFile >> "CfgVehicles" >> _unitClass;
                
                // --- Weapons ---
                private _weapons = getArray (_cfg >> "weapons");
                {
                    [_x] call _fnc_processWeapon;
                } forEach _weapons;
                
                // --- Magazines ---
                private _magazines = getArray (_cfg >> "magazines");
                {
                    if (_x != "") then { _harvestedGear pushBack _x; };
                } forEach _magazines;
                
                // --- Items (Inventory) ---
                private _items = getArray (_cfg >> "items");
                {
                    if (_x != "") then { _harvestedGear pushBack _x; };
                } forEach _items;
                
                // --- Linked Items (Vest, Helmet, etc.) ---
                private _linkedItems = getArray (_cfg >> "linkedItems");
                {
                    if (_x != "") then { _harvestedGear pushBack _x; };
                } forEach _linkedItems;
                
                // --- Uniform ---
                private _uniform = getText (_cfg >> "uniformClass");
                if (_uniform != "") then { _harvestedGear pushBack _uniform; };
                
                // --- Backpack ---
                private _backpack = getText (_cfg >> "backpack");
                if (_backpack != "") then { 
                    _harvestedGear pushBack _backpack; 
                    
                    // Also check if the backpack implies extra items (pre-configured)
                    [_backpack] call _fnc_processContainer;
                };
            };
        };
    };
} forEach _unitVars;

// Remove duplicates and empty strings
_harvestedGear = _harvestedGear select {_x != ""};
_harvestedGear = _harvestedGear arrayIntersect _harvestedGear;

["ARSENAL", 3, format ["Harvested Gear: %1", _harvestedGear]] call FLO_fnc_log;

_harvestedGear