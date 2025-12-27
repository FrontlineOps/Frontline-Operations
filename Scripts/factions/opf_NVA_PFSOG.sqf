// OPFOR North Vietnamese Army Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_AT_Team"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Weapons_Team")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "vn_o_wheeled_z157_01",
    "vn_o_wheeled_z157_02",
    "vn_o_car_01_01",
    "vn_o_car_03_01",
    "vn_o_car_02_01"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "vn_o_wheeled_btr40_mg_01",
    "vn_o_wheeled_btr40_mg_02",
    "vn_o_wheeled_z157_mg_01",
    "vn_o_wheeled_btr40_01"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "vn_o_armor_type63_01",
    "vn_o_armor_m41_01",
    "vn_o_armor_pt76a_01",
    "vn_o_armor_pt76b_01",
    "vn_o_armor_t54b_01"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "vn_o_wheeled_z157_01",
    "vn_o_wheeled_z157_02",
    "vn_o_wheeled_btr40_01"
];

// Transport Air Vehicles
East_Air_Transport = [
    "vn_o_air_mi2_01_01",
    "vn_o_air_mi2_01_02"
];

// Armed Helicopters
East_Air_Heli = [
    "vn_o_air_mi2_04_01",
    "vn_o_air_mi2_04_02",
    "vn_o_air_mi2_05_01"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "vn_o_air_mig19_cap",
    "vn_o_air_mig19_cas",
    "vn_o_air_mig21_cap",
    "vn_o_air_mig21_cas"
];

// Artillery Units
East_Ground_Artillery = [
    "vn_o_vc_static_mortar_type53",
    "vn_o_vc_static_mortar_type63",
    "vn_o_nva_static_d44"
];

// Drone Units
East_Air_Drone = [];

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "vn_o_men_nva_01", "vn_o_men_nva_01",         // Regular rifleman
    "vn_o_men_nva_07", "vn_o_men_nva_07",         // Automatic Rifleman
    "vn_o_men_nva_06", "vn_o_men_nva_06",         // Grenadier
    
    // Support roles (medium frequency)
    "vn_o_men_nva_04",                            // Team Leader
    "vn_o_men_nva_03",                            // Squad Leader
    "vn_o_men_nva_10",                            // Marksman
    
    // Specialists (low frequency)
    "vn_o_men_nva_14",                            // AT Specialist
    "vn_o_men_nva_11",                            // Machine Gunner
    "vn_o_men_nva_08"                             // Medic
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "vn_o_men_nva_04"
];

// Officer Units
East_Units_Officers = [
    "vn_o_men_nva_65_01"
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