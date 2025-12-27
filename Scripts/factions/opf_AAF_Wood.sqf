// OPFOR AAF Woodland Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSentry"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "I_MRAP_03_F",
    "I_MRAP_03_gmg_F",
    "I_Truck_02_covered_F",
    "I_Truck_02_ammo_F",
    "I_Truck_02_fuel_F",
    "I_Truck_02_transport_F"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "I_MRAP_03_hmg_F",
    "I_MRAP_03_gmg_F",
    "I_APC_Wheeled_03_cannon_F",
    "I_LT_01_cannon_F",
    "I_LT_01_AA_F"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "I_APC_tracked_03_cannon_F",
    "I_MBT_03_cannon_F"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "I_MRAP_03_F",
    "I_Truck_02_covered_F",
    "I_Truck_02_transport_F"
];

// Transport Air Vehicles
East_Air_Transport = [
    "I_Heli_Transport_02_F",
    "I_Heli_light_03_unarmed_F"
];

// Armed Helicopters
East_Air_Heli = [
    "I_Heli_light_03_dynamicLoadout_F"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "I_Plane_Fighter_03_dynamicLoadout_F",
    "I_Plane_Fighter_04_F"
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
    "I_Soldier_F", "I_Soldier_F",                         // Regular rifleman
    "I_Soldier_AR_F", "I_Soldier_AR_F",                  // Autorifleman
    "I_Soldier_GL_F", "I_Soldier_GL_F",                  // Grenadier
    
    // Support roles (medium frequency)
    "I_Soldier_M_F",                                     // Marksman
    "I_Soldier_LAT2_F",                                 // Light AT
    "I_Soldier_TL_F",                                   // Team Leader
    
    // Specialists (low frequency)
    "I_Soldier_SL_F",                                   // Squad Leader
    "I_engineer_F",                                     // Engineer
    "I_medic_F",                                        // Medic
    "I_Soldier_lite_F"                                  // Light Infantry
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "I_Soldier_SL_F"
];

// Officer Units
East_Units_Officers = [
    "I_officer_F"
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