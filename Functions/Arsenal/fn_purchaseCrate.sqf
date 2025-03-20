/*
    Function: FLO_fnc_purchaseCrate
    
    Description: Creates a system for purchasing limited equipment crates at FOBs and OPs
                 These crates contain special equipment not available in the arsenal
    
    Parameter(s):
        None
        
    Returns:
        None
*/

if (isNil "FLO_crates_initialized") then {
    FLO_crates_initialized = false;
};

if (FLO_crates_initialized) exitWith {};

// Define available crate types with their contents and costs
FLO_availableCrates = [
    // Format: [ID, Name, Cost, Type of Box, Items Array, Description]
    ["heavyweapons", "Heavy Weapons Crate", 50, "Box_NATO_WpsSpecial_F", [
        ["launch_B_Titan_short_F", 2],  // 2x Javelin launchers
        ["Titan_AT", 10]                // 10x Javelin missiles
    ], "Contains 2 Javelin launchers and 10 missiles"],
    
    ["explosives", "Explosives Crate", 40, "Box_NATO_AmmoOrd_F", [
        ["SatchelCharge_Remote_Mag", 4],
        ["DemoCharge_Remote_Mag", 8],
        ["ClaymoreDirectionalMine_Remote_Mag", 6],
        ["ACE_Clacker", 2]
    ], "Contains various explosives and detonators"],
    
    ["specialammo", "Special Ammunition Crate", 30, "Box_NATO_Ammo_F", [
        ["150Rnd_762x54_Box", 5],
        ["130Rnd_338_Mag", 5],
        ["7Rnd_408_Mag", 10]
    ], "Contains special ammunition for machine guns and sniper rifles"]
];

// Start the system
[] call FLO_fnc_initCrateSystem;