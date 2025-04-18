// OPFOR Syrian Armed Forces Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_Rifle_squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_Patrol_section"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_AT_section")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "LOP_SYR_Ural_open",
    "LOP_SYR_UAZ_Open",
    "LOP_SLA_BTR70",
    "LOP_SYR_BTR80",
    "LOP_SYR_UAZ_DshKM",
    "LOP_SYR_UAZ_SPG",
    "LOP_IRA_Landrover_M2",
    "LOP_IRA_Landrover_SPG9",
    "LOP_SYR_UAZ"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "LOP_SLA_BTR70",
    "LOP_SYR_BTR80",
    "LOP_SYR_UAZ_DshKM",
    "LOP_SYR_UAZ_SPG",
    "LOP_IRA_Landrover_M2",
    "LOP_IRA_Landrover_SPG9",
    "LOP_SYR_UAZ"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "LOP_SYR_ZSU234",
    "LOP_ISTS_OPF_BMP2",
    "LOP_SYR_BMP2",
    "LOP_SYR_BMP1",
    "LOP_SYR_T55",
    "LOP_SYR_T72BA"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "LOP_SYR_Ural_open",
    "LOP_SYR_UAZ_Open"
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
    "LOP_SYR_Infantry_Corpsman", "LOP_SYR_Infantry_Corpsman",   // Medic
    "LOP_SYR_Infantry_Rifleman", "LOP_SYR_Infantry_Rifleman",   // Rifleman
    "LOP_SYR_Infantry_GL", "LOP_SYR_Infantry_GL",               // Grenadier
    
    // Support roles (medium frequency)
    "LOP_SYR_Infantry_TL",                                     // Team Leader
    "LOP_SYR_Infantry_SL",                                     // Squad Leader
    "LOP_SYR_Infantry_Marksman",                              // Marksman
    
    // Specialists (low frequency)
    "LOP_SYR_Infantry_AT",                                    // AT Specialist
    "LOP_SYR_Infantry_AT_Asst",                              // AT Assistant
    "LOP_SYR_Infantry_MG",                                    // Machine Gunner
    "LOP_SYR_Infantry_Engineer"                               // Engineer
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "LOP_SYR_Infantry_TL"
];

// Officer Units
East_Units_Officers = [
    "LOP_SYR_Infantry_SL"
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