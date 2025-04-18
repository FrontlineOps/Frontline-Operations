// OPFOR Russian Armed Forces (Desert) Faction Definition
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Predefined Groups from the config
// Used as the primary groups for the virtualization system
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad_2mg"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad_sniper"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_section_mg")
];

// Ambient/Civilian-Like Ground Vehicles
East_Ground_Vehicles_Ambient = [
    "rhs_uaz_open_msv",
    "rhs_uaz_msv",
    "RHS_Ural_Open_MSV_01",
    "RHS_Ural_MSV_01"
];

// Light Military Ground Vehicles
East_Ground_Vehicles_Light = [
    "rhs_tigr_m_msv",
    "rhs_tigr_sts_msv",
    "rhs_btr80_msv",
    "rhs_btr80a_msv"
];

// Heavy Ground Vehicles and Tanks
East_Ground_Vehicles_Heavy = [
    "rhs_bmp2d_msv",
    "rhs_bmp3_late_msv",
    "rhs_t72bd_tv",
    "rhs_t80uk",
    "rhs_t90sm_tv"
];

// Transport Ground Vehicles
East_Ground_Transport = [
    "RHS_Ural_Open_MSV_01",
    "RHS_Ural_MSV_01",
    "rhs_btr80_msv",
    "rhs_kamaz5350_msv"
];

// Transport Air Vehicles
East_Air_Transport = [
    "RHS_Mi8mt_Cargo_vvs",
    "RHS_Mi8MTV3_heavy_vvs",
    "RHS_Mi24V_vvs"
];

// Armed Helicopters
East_Air_Heli = [
    "RHS_Mi24P_vvs",
    "RHS_Mi24V_vvs",
    "RHS_Mi28N_vvs",
    "RHS_Ka52_vvs"
];

// Fixed-Wing Aircraft
East_Air_Jet = [
    "RHS_Su25SM_vvs",
    "rhs_mig29sm_vvs",
    "RHS_T50_vvs_generic_ext",
    "RHS_Su25SM3_vvs"
];

// Artillery Units
East_Ground_Artillery = [
    "rhs_2s3_tv",
    "RHS_BM21_MSV_01",
    "rhs_D30_msv"
];

// Drone Units
East_Air_Drone = [
    "rhs_pchela1t_vvs"
];

// Individual Infantry Units
East_Units = [
    // Regular infantry (high frequency)
    "rhs_msv_emr_rifleman", "rhs_msv_emr_rifleman",     // Regular rifleman
    "rhs_msv_emr_arifleman", "rhs_msv_emr_arifleman",   // Automatic Rifleman
    "rhs_msv_emr_grenadier", "rhs_msv_emr_grenadier",   // Grenadier
    
    // Support roles (medium frequency)
    "rhs_msv_emr_sergeant",                              // Team Leader
    "rhs_msv_emr_officer",                               // Squad Leader
    "rhs_msv_emr_marksman",                              // Marksman
    
    // Specialists (low frequency)
    "rhs_msv_emr_at",                                    // AT Specialist
    "rhs_msv_emr_machinegunner",                         // Machine Gunner
    "rhs_msv_emr_medic"                                  // Medic
];

// Fire Observer Units for Artillery
East_FireObserver = [
    "rhs_msv_emr_artyp"
];

// Officer Units
East_Units_Officers = [
    "rhs_msv_emr_officer"
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