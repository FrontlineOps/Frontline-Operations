// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

// CUSTOM_ENEMY_FACTION.sqf
// Defines the OPFOR faction units and equipment for the mission
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
East_Ground_Vehicles_Ambient = ["I_MRAP_03_F"]; 
// Light Military Ground Vehicles
East_Ground_Vehicles_Light = ["I_MRAP_03_F", "I_MRAP_03_gmg_F", "I_MRAP_03_hmg_F", "I_APC_Wheeled_03_cannon_F"];
// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = ["I_MBT_03_cannon_F", "I_LT_01_cannon_F", "I_LT_01_AT_F", "I_LT_01_AA_F", "I_APC_tracked_03_cannon_v2_F"]; 
// Transport Ground Vehicles
East_Ground_Transport = ["I_MRAP_03_F", "I_Truck_02_transport_F", "I_Truck_02_covered_F"]; 
// Transport Air Vehicles
East_Air_Transport = ["I_Heli_Transport_02_F", "Aegis_I_Heli_Transport_02_Heavy_F", "I_Heli_Light_01_F", "I_Heli_light_03_unarmed_F"];
// Armed Helicopters
East_Air_Heli = ["I_Heli_Attack_03_F", "I_Heli_Light_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F"]; 
// Fixed-Wing Aircraft
East_Air_Jet = ["I_Plane_Fighter_04_F", "I_Plane_Fighter_03_dynamicLoadout_F"]; 
// Artillery Units
East_Ground_Artillery = ["O_MBT_02_arty_F"]; 
// Drone Units
East_Air_Drone = ["I_UAV_01_F"]; 
// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "I_soldier_F", "I_soldier_F", "I_soldier_F", "I_soldier_F",  // Regular rifleman
    "I_Soldier_AR_F", "I_Soldier_AR_F",                          // Autorifleman
    "I_Soldier_CQ_F", "I_Soldier_CQ_F",                          // CQB specialist
    "I_Soldier_GL_F", "I_Soldier_GL_F",                          // Grenadier
    
    // Support roles (medium frequency)
    "I_medic_F", "I_medic_F",                                    // Medic
    "I_Soldier_MG_F", "I_Soldier_MG_F",              // Machine gunner
    "I_Soldier_M_F",                                             // Marksman
    "I_Soldier_A_F",                                             // Ammo bearer
    
    // Specialists (low frequency)
    "I_Soldier_LAT_F",                                           // Light AT
    "I_Soldier_LAT2_F",                                          // Light AT
    "I_Soldier_AT_F",                                            // AT Specialist
    "I_Soldier_AA_F"                                             // AA Specialist
];
// Fire Observer Units for Artillery
East_FireObserver = ["I_RadioOperator_F"];
// Officer Units
East_Units_Officers = ["I_officer_F"];

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
    ["artillery", 1]         // Number of artillery pieces (Probably always keep this at 1)
];

/*
 * Configure activation distance for the virtualization system
 * This is the distance in meters that a player needs to be from a virtual group for it to physically spawn in the game
 */ 
OPFOR_Virtualization_Distance = 2000;