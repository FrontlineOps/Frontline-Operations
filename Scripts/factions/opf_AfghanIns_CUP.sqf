// OPFOR Afghan Insurgents Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_Group"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_AATeam")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "CUP_O_Hilux_unarmed_TK_INS",
    "CUP_O_V3S_Open_TKM",
    "CUP_O_Hilux_UB32_TK_INS",
    "CUP_O_Hilux_M2_TK_INS",
    "CUP_O_V3S_Refuel_TKM",
    "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_metis_TK_INS"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "CUP_O_Hilux_M2_TK_INS",
    "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_UB32_TK_INS",
    "CUP_O_Hilux_SPG9_TK_INS",
    "CUP_O_Hilux_metis_TK_INS"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "CUP_O_BMP2_CHDKZ",
    "CUP_O_BMP2_CHDKZ",
    "Opf_I_I_Offroad_01_AT_F",
    "CUP_O_Hilux_SPG9_TK_INS",
    "Opf_I_I_Offroad_01_armed_F",
    "CUP_O_Hilux_UB32_TK_INS"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "CUP_O_Hilux_unarmed_TK_INS",
    "CUP_O_V3S_Open_TKM"
];

// Transport Air Vehicles
East_Air_Transport = [];

// Armed Helicopters
East_Air_Heli = [
    "O_Heli_Light_02_dynamicLoadout_F"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "O_Heli_Light_02_dynamicLoadout_F"
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
    "CUP_O_TK_INS_Soldier", "CUP_O_TK_INS_Soldier",           // Regular rifleman
    "CUP_O_TK_INS_Soldier_MG", "CUP_O_TK_INS_Soldier_MG",     // Machine Gunner
    "CUP_O_TK_INS_Soldier_GL", "CUP_O_TK_INS_Soldier_GL",     // Grenadier
    
    // Support roles (medium frequency)
    "CUP_O_TK_INS_Soldier_TL",                               // Team Leader
    "CUP_O_TK_INS_Soldier_AR",                               // Automatic Rifleman
    "CUP_O_TK_INS_Sniper",                                   // Sniper
    
    // Specialists (low frequency)
    "CUP_O_TK_INS_Soldier_AT",                               // AT Specialist
    "CUP_O_TK_INS_Soldier_Enfield",                          // Rifleman (Enfield)
    "CUP_O_TK_INS_Soldier_FNFAL"                             // Rifleman (FNFAL)
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "CUP_O_TK_INS_Soldier_TL"
];

// Officer Units
East_Units_Officers = [
    "Opf_I_I_Soldier_Base_unarmed_F"
];

/*
 * OPFOR Virtualization Objective Configuration
 * This section defines how many of each unit type should spawn at different objective types
 * These are the default settings that will be used by the virtualization system
*/

/*
 * OPFOR Virtualization Objective Configuration
 * Subtypes: "capital", "city", "village", "local", "marine", "cluster"
 */
OPFOR_Objective_Groups = [
    ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["air", 1], ["armor", 1], ["artillery", 1]]],
    ["city", [["infantry", 7], ["motorized", 2]]],
    ["village", [["infantry", 3]]],
    ["local", [["infantry", 6], ["motorized", 2], ["mechanized", 1]]],
    ["marine", [["infantry", 3], ["motorized", 1]]],
    ["cluster", [["infantry", 2]]]
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