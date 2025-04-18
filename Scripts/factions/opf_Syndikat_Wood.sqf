// OPFOR Syndikat Woodland Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaShockTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaFireTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaCombatGroup")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "I_G_Offroad_01_armed_F",
    "I_C_Offroad_02_AT_F",
    "I_C_Offroad_02_LMG_F",
    "I_C_Offroad_02_unarmed_F",
    "I_C_Offroad_02_unarmed_F",
    "I_C_Van_01_transport_F",
    "I_C_Van_02_transport_F",
    "O_T_Quadbike_01_ghex_F"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "I_G_Offroad_01_armed_F",
    "I_C_Offroad_02_LMG_F",
    "I_C_Offroad_02_AT_F",
    "I_G_Offroad_01_armed_F",
    "I_C_Offroad_02_LMG_F"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "I_E_APC_tracked_03_cannon_F",
    "I_C_Offroad_02_AT_F",
    "I_G_Offroad_01_armed_F"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "I_C_Van_01_transport_F",
    "I_C_Van_02_transport_F",
    "I_C_Offroad_02_unarmed_F"
];

// Transport Air Vehicles
East_Air_Transport = [
    "I_C_Heli_Light_01_civil_F"
];

// Armed Helicopters
East_Air_Heli = [
    "I_C_Heli_Light_01_civil_F"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "I_C_Heli_Light_01_civil_F"
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
    "I_C_Soldier_Para_1_F", "I_C_Soldier_Para_1_F",     // Regular rifleman
    "I_C_Soldier_Para_2_F", "I_C_Soldier_Para_2_F",     // Militia
    "I_C_Soldier_Para_3_F", "I_C_Soldier_Para_3_F",     // Rebel
    
    // Support roles (medium frequency)
    "I_C_Soldier_Para_4_F",                            // Leader
    "I_C_Soldier_Para_5_F",                           // Medic
    "I_C_Soldier_Para_6_F",                           // Scout
    
    // Specialists (low frequency)
    "I_C_Soldier_Para_7_F",                           // Marksman
    "I_C_Soldier_Para_8_F"                            // Engineer
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "I_C_Soldier_Para_4_F"
];

// Officer Units
East_Units_Officers = [
    "I_C_Soldier_Para_4_F"
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