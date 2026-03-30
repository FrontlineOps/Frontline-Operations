// ============================================================================
// AFGHAN INSURGENTS FACTION - OPFOR (CUP Mod)
// Takistani Militia/Insurgent forces
// ============================================================================

/*
 * HOW THIS FILE FEEDS THE COMMANDER / VIRTUALIZATION
 *
 * You only edit the faction data in this file. Phase 2 builds the runtime pools
 * from these sections automatically:
 *
 *   groundInfantry   = East_Ground_Infantry
 *   groundSpecOps    = East_Ground_SpecOps
 *   groundMotorized  = East_Ground_Motorized
 *   groundMechanized = East_Ground_Mechanized
 *   groundArmor      = East_Ground_Armor
 *   groundTransport  = East_Ground_Transport
 *   transportReserveGroundCount = East_Transport_Reserve_Ground_Count
 *   groundArtillery  = East_Ground_Artillery
 *   airTransport     = East_Air_Transport
 *   transportReserveAirCount = East_Transport_Reserve_Air_Count
 *   airHeli          = East_Air_Heli
 *   airJet           = East_Air_Jet
 *   airDrone         = East_Air_Drone
 *   mobileAA         = East_Mobile_AA
 *   staticAA         = East_Static_AA
 *   radar            = East_Radar
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above.
 */
// ============================================================================
// INFANTRY
// ============================================================================
// Mixed infantry source for groundInfantry.
// Entries may be full CfgGroups configs or individual unit classnames.
East_Ground_Infantry = [
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_Group"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_AATeam"),
    "CUP_O_TK_INS_Soldier", "CUP_O_TK_INS_Soldier",
    "CUP_O_TK_INS_Soldier_MG", "CUP_O_TK_INS_Soldier_MG",
    "CUP_O_TK_INS_Soldier_GL", "CUP_O_TK_INS_Soldier_GL",
    "CUP_O_TK_INS_Soldier_TL",
    "CUP_O_TK_INS_Soldier_AR",
    "CUP_O_TK_INS_Sniper",
    "CUP_O_TK_INS_Soldier_AT",
    "CUP_O_TK_INS_Soldier_Enfield",
    "CUP_O_TK_INS_Soldier_FNFAL"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["CUP_O_TK_INS_Soldier_TL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS", "CUP_O_Hilux_UB32_TK_INS",
    "CUP_O_Hilux_SPG9_TK_INS", "CUP_O_Hilux_metis_TK_INS"
];

// groundMechanized
East_Ground_Mechanized = [
    "CUP_O_BMP2_CHDKZ", "Opf_I_I_Offroad_01_AT_F", "CUP_O_Hilux_SPG9_TK_INS",
    "Opf_I_I_Offroad_01_armed_F", "CUP_O_Hilux_UB32_TK_INS"
];
// groundArmor
East_Ground_Armor = [
    "CUP_O_BMP2_CHDKZ", "Opf_I_I_Offroad_01_AT_F", "CUP_O_Hilux_SPG9_TK_INS",
    "Opf_I_I_Offroad_01_armed_F", "CUP_O_Hilux_UB32_TK_INS"
];

// groundTransport
East_Ground_Transport = ["CUP_O_Hilux_unarmed_TK_INS", "CUP_O_V3S_Open_TKM"];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = [];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"];

// airJet
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["O_APC_Tracked_02_AA_F"];

// staticAA
East_Static_AA = ["O_SAM_System_04_F"];

// radar
East_Radar = ["O_Radar_System_02_F"];

// ============================================================================
// GARRISON CONFIGURATION
// ============================================================================
OPFOR_Objective_Groups = [
    ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["air", 1], ["armor", 1], ["artillery", 1], ["mobile_aa", 1], ["static_aa", 1]]],
    ["city", [["infantry", 7], ["motorized", 2]]],
    ["village", [["infantry", 3]]],
    ["local", [["infantry", 6], ["motorized", 2], ["mechanized", 1], ["mobile_aa", 1]]],
    ["marine", [["infantry", 3], ["motorized", 1]]],
    ["cluster", [["infantry", 2]]]
];

OPFOR_Group_Counts = [
    ["infantry", 10],
    ["motorized", 1],
    ["mechanized", 1],
    ["armor", 1],
    ["helicopter", 1],
    ["jet", 1],
    ["air", 1],
    ["artillery", 3],
    ["mobile_aa", 1],
    ["static_aa", 1]
];

