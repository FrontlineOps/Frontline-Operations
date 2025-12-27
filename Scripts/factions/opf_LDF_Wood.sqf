// OPFOR Livonian Defense Force (Woodland) Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSentry"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSquad"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam_AA")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "I_E_Offroad_01_F",
    "I_E_Van_02_transport_F", 
    "I_E_Offroad_01_covered_F", 
    "I_E_Truck_02_transport_F", 
    "I_E_Truck_02_fuel_F", 
    "I_E_Truck_02_F", 
    "I_E_Truck_02_MRL_F"
]; 

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "I_E_UGV_01_rcws_F",           // Armed UGV
    "O_G_Offroad_01_armed_F",      // Armed Offroad
    "O_G_Offroad_01_AT_F",         // AT Offroad
    "I_E_Offroad_01_armed_F"       // LDF Armed Offroad
]; 

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "I_E_APC_tracked_03_cannon_F",  // Tracked APC
    "I_E_APC_Wheeled_03_cannon_F"   // Wheeled APC
]; 

// Transport Ground Vehicles
East_Ground_Transport = [
    "I_E_Van_02_transport_F",
    "I_E_Offroad_01_F", 
    "I_E_Offroad_01_covered_F",
    "I_E_Truck_02_F", 
    "I_E_Truck_02_transport_F"
]; 

// Transport Air Vehicles
East_Air_Transport = [
    "I_Heli_Transport_02_F",           // Heavy Transport Helicopter
    "I_E_Heli_light_03_unarmed_F"      // Light Transport Helicopter
];

// Armed Helicopters
East_Air_Heli = [
    "I_E_Heli_light_03_dynamicLoadout_F"  // Armed Light Helicopter
]; 

// Fixed-Wing Aircraft
East_Air_Jet = [
    "I_Plane_Fighter_03_dynamicLoadout_F",  // L-159 ALCA
    "I_Plane_Fighter_04_F"                  // Gripen
];

// Artillery Units
East_Ground_Artillery = [
    "I_E_Truck_02_MRL_F",                  // MRL Truck
    "I_E_Mortar_01_F"                      // Mortar
];

// Drone Units
East_Air_Drone = [
    "I_E_UGV_01_F",                        // UGV
    "I_E_UAV_01_F"                         // AR-2 Darter
]; 

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "I_E_Soldier_F", "I_E_Soldier_F",           // Regular rifleman
    "I_E_Soldier_AR_F", "I_E_Soldier_AR_F",     // Automatic Rifleman
    "I_E_Soldier_GL_F", "I_E_Soldier_GL_F",     // Grenadier
    
    // Support roles (medium frequency)
    "I_E_Soldier_TL_F",                         // Team Leader
    "I_E_Soldier_SL_F",                         // Squad Leader
    "I_E_soldier_M_F",                          // Marksman
    
    // Specialists (low frequency)
    "I_E_Soldier_LAT2_F",                       // AT Specialist
    "I_E_Soldier_AR_F",                         // Machine Gunner
    "I_E_Medic_F",                              // Medic
    "I_E_Soldier_Exp_F",                        // Engineer
    "I_E_RadioOperator_F"                       // Radio Operator
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "I_E_RadioOperator_F"
];

// Officer Units
East_Units_Officers = [
    "I_E_Officer_F"
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