// ============================================================================
// AFGHAN AF FACTION - OPFOR (CUP Mod)
// Afghan Armed Forces (Takistani Army)
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
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySection"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAT"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAA"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionMG"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySquad"),
    "CUP_O_TK_Soldier", "CUP_O_TK_Soldier",
    "CUP_O_TK_Soldier_AR", "CUP_O_TK_Soldier_AR",
    "CUP_O_TK_Soldier_GL", "CUP_O_TK_Soldier_GL",
    "CUP_O_TK_Soldier_SL",
    "CUP_O_TK_Soldier_MG",
    "CUP_O_TK_Sniper",
    "CUP_O_TK_Soldier_AT",
    "CUP_O_TK_Soldier_HAT",
    "CUP_O_TK_Engineer",
    "CUP_O_TK_Soldier_Backpack"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["CUP_O_TK_Soldier_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "CUP_O_LR_MG_TKM", "CUP_O_Hilux_AGS30_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_SPG9_TK_INS",
    "CUP_O_BTR40_MG_TKM", "CUP_O_MTLB_pk_TK_MILITIA"
];

// groundMechanized
East_Ground_Mechanized = [
    "CUP_O_BTR80_TK", "CUP_O_BTR80A_TK", "CUP_O_BMP1P_TKA", "CUP_O_BMP2_TKA",
    "CUP_O_ZSU23_Afghan_TK", "CUP_O_ZSU23_TK", "CUP_O_BMP2_ZU_TKA",
    "CUP_O_T55_TK", "CUP_O_T72_TKA"
];
// groundArmor
East_Ground_Armor = [
    "CUP_O_BTR80_TK", "CUP_O_BTR80A_TK", "CUP_O_BMP1P_TKA", "CUP_O_BMP2_TKA",
    "CUP_O_ZSU23_Afghan_TK", "CUP_O_ZSU23_TK", "CUP_O_BMP2_ZU_TKA",
    "CUP_O_T55_TK", "CUP_O_T72_TKA"
];

// groundTransport
East_Ground_Transport = ["CUP_O_LR_Transport_TKA", "CUP_O_Ural_TKA", "CUP_O_UAZ_Open_TKA"];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["CUP_O_UH1H_TKA", "CUP_O_Mi17_TK"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["CUP_O_UH1H_gunship_TKA", "CUP_O_Mi24_D_Dynamic_TK"];

// airJet
East_Air_Jet = ["CUP_O_Su25_Dyn_TKA"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["CUP_O_ZSU23_Afghan_TK", "CUP_O_ZSU23_TK"];

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

