/*
    Function: FLO_fnc_purchaseCrate
    
    Description: Creates a system for purchasing limited equipment crates at FOBs and OPs
                 These crates contain special equipment not available in the arsenal
    
    Parameter(s):
        None
        
    Returns:
        None
*/
FLO_crates_initialized = false;

// Define available crate types with their contents and costs
FLO_availableCrates = [
    // Format: [ID, Name, Cost, Type of Box, Items Array, Description]
    ["heavyweapons", "Heavy Weapons Crate", 50, "Box_NATO_WpsSpecial_F", 
        if (!isNil "FLO_arsenal_heavyItems") then {FLO_arsenal_heavyItems} else {[]}, 
        "Contains faction-specific heavy weaponry (Launchers) and ammo"]
];

FLO_crates_initialized = true;