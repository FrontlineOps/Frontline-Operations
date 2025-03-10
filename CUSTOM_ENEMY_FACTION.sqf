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
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "SpecOps" >> "HAF_SniperTeam"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_EOD"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_GMG"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_MG"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_Mort"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_ENG"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_Raven_F" >> "Infantry" >> "I_Raven_InfSquad"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_Raven_F" >> "Infantry" >> "I_Raven_InfTeam")
];
// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = ["I_MRAP_03_F"]; 
// Light Military Ground Vehicles
East_Ground_Vehicles_Light = ["I_MRAP_03_F", "I_MRAP_03_gmg_F", "I_MRAP_03_hmg_F", "I_A_Truck_02_aa_lxWS", "I_APC_Wheeled_03_cannon_F", "Aegis_I_Raven_APC_Wheeled_04_export_F", "I_Raven_MRAP_02_HMG_F", "I_Raven_MRAP_02_GMG_F"];
// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = ["I_MBT_03_cannon_F", "I_LT_01_cannon_F", "I_LT_01_AT_F", "I_LT_01_AA_F", "I_APC_tracked_03_cannon_v2_F"]; 
// Transport Ground Vehicles
East_Ground_Transport = ["I_MRAP_03_F", "I_Truck_02_transport_F", "I_Truck_02_covered_F", "Aegis_I_Raven_Truck_02_F"]; 
// Transport Air Vehicles
East_Air_Transport = ["I_Heli_Transport_02_F", "Aegis_I_Heli_Transport_02_Heavy_F", "I_Heli_Light_01_F", "I_Heli_light_03_unarmed_F"];
// Armed Helicopters
East_Air_Heli = ["I_Heli_Attack_03_F", "I_Heli_Light_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F", "Aegis_I_Raven_Heli_Attack_04_F"]; 
// Fixed-Wing Aircraft
East_Air_Jet = ["I_Plane_Fighter_04_F", "I_Plane_Fighter_03_dynamicLoadout_F"]; 
// Artillery Units
East_Ground_Artillery = ["O_R_MBT_02_arty_F"]; 
// Drone Units
East_Air_Drone = ["I_UAV_02_lxWS", "I_UAV_01_F"]; 
// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "I_soldier_F", "I_soldier_F", "I_soldier_F", "I_soldier_F",  // Regular rifleman
    "I_Soldier_AR_F", "I_Soldier_AR_F",                          // Autorifleman
    "I_Soldier_CQ_F", "I_Soldier_CQ_F",                          // CQB specialist
    "I_Soldier_GL_F", "I_Soldier_GL_F",                          // Grenadier
    
    // Support roles (medium frequency)
    "I_medic_F", "I_medic_F",                                    // Medic
    "Aegis_I_Soldier_MG_F", "Aegis_I_Soldier_MG_F",              // Machine gunner
    "I_Soldier_M_F",                                             // Marksman
    "I_Soldier_A_F",                                             // Ammo bearer
    
    // Specialists (low frequency)
    "I_Soldier_LAT_F",                                           // Light AT
    "I_Soldier_LAT2_F",                                          // Light AT
    "I_Soldier_AT_F",                                            // AT Specialist
    "I_Soldier_AA_F",                                            // AA Specialist
    "Aegis_I_HeavyGunner_F"                                     // Heavy gunner
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
 * Configure activation distance for the virtualization system
 * This is the distance in meters that a player needs to be from a virtual group for it to physically spawn in the game
 */ 
OPFOR_Virtualization_Distance = 2000;