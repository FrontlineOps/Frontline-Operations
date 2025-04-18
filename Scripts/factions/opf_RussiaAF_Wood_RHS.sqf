// OPFOR Russian Armed Forces (Woodland) Faction Definition - RHS
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_fireteam"),
(configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_section_AT"),
(configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_section_AA"),
(configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_squad_mg_sniper"),
(configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_squad_2mg")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = ["rhs_tigr_sts_msv","rhs_tigr_msv", "rhs_gaz66o_msv", "rhs_gaz66_repair_msv", "rhs_gaz66_vdv"]; 

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [ "rhs_btr60_vmf", "rhs_tigr_sts_msv"]; 

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [ "rhs_zsu234_aa",  "rhs_Ob_681_2", "rhs_bmp2_tv", "rhs_bmp1_tv","rhs_t72be_tv","rhs_t80bvk", "rhs_t90sm_tv"]; 

// Transport Ground Vehicles
East_Ground_Transport = ["rhs_tigr_msv",  "rhs_gaz66_msv", "rhs_gaz66o_msv"]; 

// Transport Air Vehicles
East_Air_Transport = ["rhs_ka60_c","RHS_Mi8mt_vvsc", "RHS_Mi8MTV3_heavy_vvsc"];

// Armed Helicopters
East_Air_Heli = ["RHS_Ka52_vvsc",  "RHS_Mi24P_vdv"]; 

// Fixed-Wing Aircraft
East_Air_Jet = ["rhs_mig29sm_vvsc", "RHS_Su25SM_vvsc"];

// Artillery Units
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// Drone Units
East_Air_Drone = ["O_UAV_01_F"]; 

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "rhs_vdv_flora_rifleman", "rhs_vdv_flora_rifleman", "rhs_vdv_flora_rifleman",  // Regular rifleman
    "rhs_vdv_flora_machinegunner", "rhs_vdv_flora_machinegunner",                  // Machine gunner
    "rhs_vdv_flora_grenadier", "rhs_vdv_flora_grenadier",                          // Grenadier
    
    // Support roles (medium frequency)
    "rhs_vdv_flora_medic", "rhs_vdv_flora_medic",                                  // Medic
    "rhs_vdv_flora_marksman",                                                       // Marksman
    "rhs_vdv_flora_efreitor",                                                       // Squad Leader
    
    // Specialists (low frequency)
    "rhs_vdv_flora_LAT",                                                           // Light AT
    "rhs_vdv_flora_at",                                                            // AT Specialist
    "rhs_vdv_flora_engineer"                                                       // Engineer
];

// Fire Observer Units for Artillery
East_FireObserver = ["rhs_vdv_des_officer"];

// Officer Units
East_Units_Officers = ["rhs_vdv_des_officer", "rhs_vdv_flora_officer"];

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