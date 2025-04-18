// OPFOR ISIS Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_AATeam")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "LOP_ISTS_Landrover",
    "LOP_ISTS_Truck",
    "LOP_ISTS_M998_D_4DR",
    "LOP_ISTS_Offroad",
    "LOP_ISTS_Landrover_M2",
    "LOP_ISTS_Offroad_M2",
    "LOP_ISTS_BMP2"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "LOP_ISTS_Landrover_M2",
    "LOP_ISTS_Offroad_M2",
    "LOP_ISTS_M1025_W_M2",
    "LOP_ISTS_M1025_W_Mk19",
    "LOP_ISTS_BTR60",
    "LOP_ISTS_M113_W"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "LOP_ISTS_BMP1",
    "LOP_ISTS_BMP2",
    "LOP_ISTS_T72BA",
    "LOP_ISTS_T72BB",
    "LOP_ISTS_ZSU234"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "LOP_ISTS_Landrover",
    "LOP_ISTS_Truck",
    "LOP_ISTS_M998_D_4DR",
    "LOP_ISTS_Offroad"
];

// Transport Air Vehicles
East_Air_Transport = [
    "LOP_ISTS_Mi8MT_Cargo"
];

// Armed Helicopters
East_Air_Heli = [
    "LOP_ISTS_Mi8MTV3_FAB",
    "LOP_ISTS_Mi8MTV3_UPK23"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "LOP_ISTS_Mi8MTV3_FAB"
];

// Artillery Units
East_Ground_Artillery = [
    "LOP_ISTS_BM21",
    "LOP_ISTS_2S1"
];

// Drone Units
East_Air_Drone = [
    "O_UAV_01_F"
];

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "LOP_ISTS_Infantry_Rifleman", "LOP_ISTS_Infantry_Rifleman",     // Regular rifleman
    "LOP_ISTS_Infantry_AR", "LOP_ISTS_Infantry_AR",                 // Autorifleman
    "LOP_ISTS_Infantry_GL", "LOP_ISTS_Infantry_GL",                 // Grenadier
    
    // Support roles (medium frequency)
    "LOP_ISTS_Infantry_TL",                                         // Team Leader
    "LOP_ISTS_Infantry_SL",                                         // Squad Leader
    "LOP_ISTS_Infantry_Marksman",                                   // Marksman
    
    // Specialists (low frequency)
    "LOP_ISTS_Infantry_AT",                                         // AT Specialist
    "LOP_ISTS_Infantry_AA",                                         // AA Specialist
    "LOP_ISTS_Infantry_Corpsman"                                    // Medic
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "LOP_ISTS_Infantry_SL"
];

// Officer Units
East_Units_Officers = [
    "LOP_ISTS_Infantry_TL"
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