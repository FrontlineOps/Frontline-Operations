// OPFOR Afghan Armed Forces Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySection"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAT"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAA"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionMG"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySquad"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySquad")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "CUP_O_LR_Transport_TKA",
    "CUP_O_Ural_TKA",
    "CUP_O_UAZ_Open_TKA",
    "CUP_O_LR_MG_TKM",
    "CUP_O_LR_MG_TKM",
    "CUP_O_Hilux_AGS30_TK_INS",
    "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_M2_TK_INS",
    "CUP_O_Hilux_SPG9_TK_INS",
    "CUP_O_BTR40_MG_TKM",
    "CUP_O_MTLB_pk_TK_MILITIA"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "CUP_O_LR_MG_TKM",
    "CUP_O_LR_MG_TKM",
    "CUP_O_Hilux_AGS30_TK_INS",
    "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_M2_TK_INS",
    "CUP_O_Hilux_SPG9_TK_INS",
    "CUP_O_BTR40_MG_TKM",
    "CUP_O_MTLB_pk_TK_MILITIA"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "CUP_O_BTR80_TK",
    "CUP_O_BTR80A_TK",
    "CUP_O_BMP1P_TKA",
    "CUP_O_BMP2_TKA",
    "CUP_O_BMP2_TKA",
    "CUP_O_ZSU23_Afghan_TK",
    "CUP_O_ZSU23_TK",
    "CUP_O_BMP2_ZU_TKA",
    "CUP_O_T55_TK",
    "CUP_O_T72_TKA",
    "CUP_O_T72_TKA"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "CUP_O_LR_Transport_TKA",
    "CUP_O_Ural_TKA",
    "CUP_O_UAZ_Open_TKA"
];

// Transport Air Vehicles
East_Air_Transport = [
    "CUP_O_UH1H_TKA",
    "CUP_O_Mi17_TK"
];

// Armed Helicopters
East_Air_Heli = [
    "CUP_O_UH1H_gunship_TKA",
    "CUP_O_Mi24_D_Dynamic_TK"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "CUP_O_Su25_Dyn_TKA"
];

// Artillery Units
East_Ground_Artillery = [
    "O_MBT_02_arty_F"
];

// Drone Units
East_Air_Drone = [
    "O_UAV_01_F"
];

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "CUP_O_TK_Soldier", "CUP_O_TK_Soldier",           // Regular rifleman
    "CUP_O_TK_Soldier_AR", "CUP_O_TK_Soldier_AR",     // Autorifleman
    "CUP_O_TK_Soldier_GL", "CUP_O_TK_Soldier_GL",     // Grenadier
    
    // Support roles (medium frequency)
    "CUP_O_TK_Soldier_SL",                           // Squad Leader
    "CUP_O_TK_Soldier_MG",                           // Machine Gunner
    "CUP_O_TK_Sniper",                               // Sniper
    
    // Specialists (low frequency)
    "CUP_O_TK_Soldier_AT",                           // AT Specialist
    "CUP_O_TK_Soldier_HAT",                          // Heavy AT
    "CUP_O_TK_Engineer",                             // Engineer
    "CUP_O_TK_Soldier_Backpack"                      // Support
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "CUP_O_TK_Soldier_SL"
];

// Officer Units
East_Units_Officers = [
    "CUP_O_TK_Officer"
];

/*
 * OPFOR Virtualization Objective Configuration
 * This section defines how many of each unit type should spawn at different objective types
 * These are the default settings that will be used by the virtualization system
*/

// Structure: [objective type, [[group type, count], [group type, count], ...]]
OPFOR_Objective_Groups = [
    // Support objectives - mix of infantry and light vehicles
    ["o_support", [
        ["infantry", 3], 
        ["motorized", 2]
    ]],
    
    // Neutral support objectives - lighter security
    ["n_support", [
        ["infantry", 2], 
        ["motorized", 1]
    ]],
    
    // Installation objectives - mix of infantry and heavy vehicles
    ["o_installation", [
        ["infantry", 4], 
        ["mechanized", 2],
        ["armor", 1]
    ]],
    
    // Neutral installation objectives
    ["n_installation", [
        ["infantry", 3], 
        ["mechanized", 1]
    ]],
    
    // Anti-air objectives - AA vehicles and infantry
    ["o_antiair", [
        ["infantry", 2],
        ["motorized", 1],
        ["air", 1]
    ]],
    
    // Service objectives - light vehicles and infantry
    ["o_service", [
        ["infantry", 2],
        ["motorized", 2]
    ]],
    
    // Power plant objectives - infantry defense
    ["loc_Power", [
        ["infantry", 3],
        ["motorized", 1]
    ]],
    
    // Ruins objectives - light infantry presence
    ["loc_Ruin", [
        ["infantry", 1]
    ]],
    
    // Recon objectives - small infantry and light vehicles
    ["o_recon", [
        ["infantry", 2],
        ["motorized", 1],
        ["helicopter", 1]
    ]],
    
    // Infantry objectives - heavier infantry presence
    ["o_inf", [
        ["infantry", 4],
        ["motorized", 1]
    ]]
];

/*
 * Group Type Unit/Vehicle Counts
 * Defines how many physical units/vehicles should be in each type of group
 */
OPFOR_Group_Counts = [
    ["infantry", 10],          // Number of individual soldiers
    ["motorized", 2],         // Number of armed vehicles (MRAP, GMG, etc.)
    ["mechanized", 2],        // Number of APCs/IFVs
    ["armor", 2],             // Number of tanks
    ["helicopter", 1],        // Number of helicopters
    ["jet", 1],               // Number of jets
    ["air", 1],               // Number of aircraft
    ["artillery", 1]          // Number of artillery pieces
];

/*
 * Configure activation distance for the virtualization system
 * This is the distance in meters that a player needs to be from a virtual group for it to physically spawn in the game
 */ 
OPFOR_Virtualization_Distance = 2000;