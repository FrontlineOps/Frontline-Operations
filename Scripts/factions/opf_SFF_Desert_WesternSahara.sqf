// OPFOR SFF Desert Western Sahara Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "OPF_SFIA_lxWS" >> "Infantry" >> "OSFIA_InfTeam_lxWS"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_SFIA_lxWS" >> "Infantry" >> "OSFIA_InfTeam_lxWS"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_SFIA_lxWS" >> "Infantry" >> "OSFIA_InfSquad_lxWS")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "O_SFIA_Truck_02_covered_lxWS",
    "I_C_Offroad_02_AT_F",
    "I_C_Offroad_02_LMG_F",
    "O_SFIA_Offroad_lxWS",
    "I_C_Offroad_02_unarmed_F",
    "O_SFIA_Truck_02_transport_lxWS",
    "I_C_Offroad_02_LMG_F",
    "O_T_Quadbike_01_ghex_F"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "O_SFIA_Offroad_armed_lxWS",
    "I_C_Offroad_02_LMG_F",
    "I_C_Offroad_02_AT_F",
    "O_SFIA_Offroad_AT_lxWS",
    "I_C_Offroad_02_LMG_F",
    "O_SFIA_Truck_02_aa_lxWS",
    "O_SFIA_Truck_02_MRL_lxWS"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "O_SFIA_APC_Tracked_02_30mm_lxWS",
    "O_SFIA_APC_Wheeled_02_hmg_lxWS",
    "O_SFIA_Truck_02_aa_lxWS"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "O_SFIA_Offroad_lxWS",
    "O_SFIA_Truck_02_transport_lxWS",
    "O_SFIA_Truck_02_covered_lxWS"
];

// Transport Air Vehicles
East_Air_Transport = [
    "O_Heli_Light_02_dynamicLoadout_F",
    "O_Heli_Transport_04_covered_F"
];

// Armed Helicopters
East_Air_Heli = [
    "O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS"
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
    "O_SFIA_soldier_lxWS", "O_SFIA_soldier_lxWS",           // Regular rifleman
    "O_SFIA_Soldier_AR_lxWS", "O_SFIA_Soldier_AR_lxWS",     // Autorifleman
    "O_SFIA_Soldier_GL_lxWS", "O_SFIA_Soldier_GL_lxWS",     // Grenadier
    
    // Support roles (medium frequency)
    "O_SFIA_sharpshooter_lxWS",                            // Sharpshooter
    "O_SFIA_Soldier_TL_lxWS",                              // Team Leader
    "O_SFIA_Soldier_universal_lxWS",                       // Universal Soldier
    
    // Specialists (low frequency)
    "O_SFIA_soldier_aa_lxWS",                             // AA Specialist
    "O_SFIA_soldier_at_lxWS",                             // AT Specialist
    "O_SFIA_medic_lxWS",                                  // Medic
    "O_SFIA_exp_lxWS",                                    // Explosive Specialist
    "O_SFIA_repair_lxWS"                                  // Repair Specialist
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "O_SFIA_Soldier_TL_lxWS"
];

// Officer Units
East_Units_Officers = [
    "O_SFIA_officer_lxWS"
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