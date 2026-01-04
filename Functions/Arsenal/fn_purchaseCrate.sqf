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
    ["heavyweapons", "Heavy Weapons Crate", 50, "Box_NATO_WpsSpecial_F", [], "Contains 2 Javelin launchers and 10 missiles"],
    
    ["explosives", "Explosives Crate", 40, "Box_NATO_AmmoOrd_F", [], "Contains various explosives and detonators"],
    
    ["specialammo", "Special Ammunition Crate", 30, "Box_NATO_Ammo_F", [], "Contains special ammunition for machine guns and sniper rifles"]
];

FLO_crates_initialized = true;