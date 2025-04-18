// OPFOR CSAT Woodland Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfSentry"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam_AT"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam_AA"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Support" >> "O_T_support_Mort"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Support" >> "O_T_support_MG"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfSquad_Weapons")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [ "B_GEN_Offroad_01_gen_F","B_GEN_Van_02_vehicle_F","B_GEN_Van_02_transport_F", "B_GEN_Offroad_01_covered_F", "O_T_LSV_02_unarmed_F","O_T_MRAP_02_ghex_F","O_T_Truck_03_transport_ghex_F", "O_Truck_02_fuel_F",  "O_T_Quadbike_01_ghex_F","O_T_UGV_01_ghex_F", "O_T_Truck_02_transport_F","O_T_Truck_02_transport_F","O_T_Quadbike_01_ghex_F"]; 

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [ "O_T_APC_Wheeled_02_rcws_v2_ghex_F",  "O_T_MRAP_02_gmg_ghex_F",  "O_T_MRAP_02_hmg_ghex_F","O_T_LSV_02_AT_F" ,"O_T_LSV_02_armed_F","O_T_UGV_01_rcws_ghex_F"]; 

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [ "O_T_APC_Tracked_02_AA_ghex_F",  "O_T_APC_Tracked_02_cannon_ghex_F",  "O_T_MBT_02_cannon_ghex_F","O_T_MBT_04_cannon_F" ]; 

// Transport Ground Vehicles
East_Ground_Transport = ["O_T_MRAP_02_ghex_F",  "O_T_Truck_03_transport_ghex_F","O_T_Truck_02_transport_F", "O_T_LSV_02_unarmed_F"]; 

// Transport Air Vehicles
East_Air_Transport = ["O_Heli_Light_02_unarmed_F","O_Heli_Transport_04_covered_F"];

// Armed Helicopters
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F",  "O_Heli_Attack_02_dynamicLoadout_F"]; 

// Fixed-Wing Aircraft
East_Air_Jet = ["O_T_VTOL_02_infantry_dynamicLoadout_F", "O_Plane_CAS_02_dynamicLoadout_F"];

// Artillery Units
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// Drone Units
East_Air_Drone = ["O_UAV_01_F"];

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "O_T_Soldier_F", "O_T_Soldier_F", "O_T_Soldier_F",     // Regular rifleman
    "O_T_Soldier_AR_F", "O_T_Soldier_AR_F",                // Autorifleman
    "O_T_Soldier_GL_F", "O_T_Soldier_GL_F",                // Grenadier
    
    // Support roles (medium frequency)
    "O_T_Medic_F", "O_T_Medic_F",                         // Medic
    "O_T_Soldier_M_F",                                     // Marksman
    "O_T_Soldier_TL_F",                                    // Team Leader
    
    // Specialists (low frequency)
    "O_T_Soldier_LAT_F",                                   // Light AT
    "O_T_Soldier_AT_F",                                    // AT Specialist
    "O_T_Soldier_Exp_F"                                    // Explosive Specialist
];

// Fire Observer Units for Artillery
East_FireObserver = ["O_T_Soldier_TL_F"];

// Officer Units
East_Units_Officers = ["O_officer_F","O_T_Officer_F"];

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