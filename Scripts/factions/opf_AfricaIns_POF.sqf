// OPFOR African Insurgents Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_AATeam")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "LOP_AFR_OPF_Offroad",
    "LOP_AFR_OPF_Truck",
    "I_G_Van_01_transport_F",
    "I_G_Van_02_transport_F",
    "LOP_AFR_OPF_BTR60",
    "LOP_AFR_OPF_Offroad_AT",
    "LOP_AFR_OPF_Offroad_M2",
    "LOP_AFR_OPF_Nissan_PKM",
    "I_C_Offroad_02_AT_F",
    "I_C_Offroad_02_LMG_F",
    "O_G_Offroad_01_AT_F",
    "O_G_Offroad_01_armed_F"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "LOP_AFR_OPF_BTR60",
    "LOP_AFR_OPF_Offroad_AT",
    "LOP_AFR_OPF_Offroad_M2",
    "LOP_AFR_OPF_Nissan_PKM",
    "I_C_Offroad_02_AT_F",
    "I_C_Offroad_02_LMG_F",
    "O_G_Offroad_01_AT_F",
    "O_G_Offroad_01_armed_F"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "LOP_AFR_OPF_T34",
    "LOP_ChDKZ_BMP1",
    "LOP_AFR_OPF_M113_W",
    "LOP_AFR_OPF_BTR60"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "LOP_AFR_OPF_Offroad",
    "LOP_AFR_OPF_Truck",
    "I_G_Van_01_transport_F",
    "I_G_Van_02_transport_F"
];

// Transport Air Vehicles
East_Air_Transport = [
    "rhsgref_ins_Mi8amt"
];

// Armed Helicopters
East_Air_Heli = [
    "rhsgref_ins_Mi8amt"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "rhsgref_ins_Mi8amt"
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
    "LOP_AFRCiv_Soldier", "LOP_AFRCiv_Soldier",           // Regular rifleman
    "LOP_AFRCiv_Soldier_AR", "LOP_AFRCiv_Soldier_AR",     // Autorifleman
    "LOP_AFRCiv_Soldier_IED", "LOP_AFRCiv_Soldier_IED",   // IED Specialist
    
    // Support roles (medium frequency)
    "LOP_AFRCiv_Soldier_SL",                              // Squad Leader
    "LOP_AFRCiv_Soldier_AT",                              // AT Specialist
    "LOP_AFRCiv_Soldier_Marksman",                        // Marksman
    
    // Specialists (low frequency)
    "LOP_AFRCiv_Soldier_Medic",                           // Medic
    "LOP_AFR_OPF_Infantry_Driver",                        // Driver
    "LOP_AFR_OPF_Infantry_SL"                             // Section Leader
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "LOP_AFR_OPF_Infantry_SL"
];

// Officer Units
East_Units_Officers = [
    "LOP_AFR_OPF_Infantry_SL"
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
