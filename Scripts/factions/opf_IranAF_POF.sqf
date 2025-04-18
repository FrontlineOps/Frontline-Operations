// OPFOR Iranian Armed Forces Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_AATeam")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "LOP_IRAN_UAZ",
    "LOP_IRAN_Ural",
    "LOP_IRAN_UAZ_Open",
    "LOP_IRAN_KAMAZ_Transport",
    "LOP_IRAN_UAZ_DshKM",
    "LOP_IRAN_UAZ_AGS",
    "LOP_IRAN_UAZ_SPG"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "LOP_IRAN_UAZ_DshKM",
    "LOP_IRAN_UAZ_AGS",
    "LOP_IRAN_UAZ_SPG",
    "LOP_IRAN_M113_W",
    "LOP_IRAN_BTR60",
    "LOP_IRAN_M113_W"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "LOP_IRAN_BMP1",
    "LOP_IRAN_BMP2",
    "LOP_IRAN_M113_W",
    "LOP_IRAN_BTR60",
    "LOP_IRAN_T72BA",
    "LOP_IRAN_ZSU234"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "LOP_IRAN_UAZ",
    "LOP_IRAN_Ural",
    "LOP_IRAN_UAZ_Open",
    "LOP_IRAN_KAMAZ_Transport"
];

// Transport Air Vehicles
East_Air_Transport = [
    "LOP_IRAN_CH47F",
    "LOP_IRAN_UH1Y"
];

// Armed Helicopters
East_Air_Heli = [
    "LOP_IRAN_AH1Z_CS",
    "LOP_IRAN_AH1Z_GS",
    "LOP_IRAN_UH1Y_Armed"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "LOP_IRAN_MIG21Bis"
];

// Artillery Units
East_Ground_Artillery = [
    "LOP_IRAN_BM21",
    "LOP_IRAN_2S1"
];

// Drone Units
East_Air_Drone = [
    "O_UAV_01_F",
    "O_UAV_02_dynamicLoadout_F"
];

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "LOP_IRAN_Infantry_Rifleman", "LOP_IRAN_Infantry_Rifleman",     // Regular rifleman
    "LOP_IRAN_Infantry_AR", "LOP_IRAN_Infantry_AR",                 // Autorifleman
    "LOP_IRAN_Infantry_GL", "LOP_IRAN_Infantry_GL",                 // Grenadier
    
    // Support roles (medium frequency)
    "LOP_IRAN_Infantry_TL",                                         // Team Leader
    "LOP_IRAN_Infantry_SL",                                         // Squad Leader
    "LOP_IRAN_Infantry_Marksman",                                   // Marksman
    
    // Specialists (low frequency)
    "LOP_IRAN_Infantry_AT",                                         // AT Specialist
    "LOP_IRAN_Infantry_AA",                                         // AA Specialist
    "LOP_IRAN_Infantry_Corpsman"                                    // Medic
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "LOP_IRAN_Infantry_SL"
];

// Officer Units
East_Units_Officers = [
    "LOP_IRAN_Infantry_Officer"
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
    ["infantry", 8],           // Number of individual soldiers
    ["motorized", 2],         // Number of armed vehicles (MRAP, GMG, etc.)
    ["mechanized", 1],        // Number of APCs/IFVs
    ["armor", 1],             // Number of tanks
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