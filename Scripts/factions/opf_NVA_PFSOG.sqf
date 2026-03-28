// ============================================================================
// NVA FACTION - OPFOR (PFSOG Mod)
// North Vietnamese Army forces
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
 *   groundArtillery  = East_Ground_Artillery
 *   airTransport     = East_Air_Transport
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
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_AT_Team"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Weapons_Team"),
    "vn_o_men_nva_01", "vn_o_men_nva_01",
    "vn_o_men_nva_07", "vn_o_men_nva_07",
    "vn_o_men_nva_06", "vn_o_men_nva_06",
    "vn_o_men_nva_04",
    "vn_o_men_nva_03",
    "vn_o_men_nva_10",
    "vn_o_men_nva_14",
    "vn_o_men_nva_11",
    "vn_o_men_nva_08"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["vn_o_men_nva_04"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "vn_o_wheeled_btr40_mg_01", "vn_o_wheeled_btr40_mg_02",
    "vn_o_wheeled_z157_mg_01", "vn_o_wheeled_btr40_01"
];

// groundMechanized
East_Ground_Mechanized = [
    "vn_o_armor_type63_01", "vn_o_armor_m41_01", "vn_o_armor_pt76a_01",
    "vn_o_armor_pt76b_01", "vn_o_armor_t54b_01"
];
// groundArmor
East_Ground_Armor = [
    "vn_o_armor_type63_01", "vn_o_armor_m41_01", "vn_o_armor_pt76a_01",
    "vn_o_armor_pt76b_01", "vn_o_armor_t54b_01"
];

// groundTransport
East_Ground_Transport = [
    "vn_o_wheeled_z157_01", "vn_o_wheeled_z157_02", "vn_o_wheeled_btr40_01"
];

// groundArtillery
East_Ground_Artillery = [
    "vn_o_vc_static_mortar_type53", "vn_o_vc_static_mortar_type63", "vn_o_nva_static_d44"
];

// airTransport
East_Air_Transport = ["vn_o_air_mi2_01_01", "vn_o_air_mi2_01_02"];

// airHeli
East_Air_Heli = ["vn_o_air_mi2_04_01", "vn_o_air_mi2_04_02", "vn_o_air_mi2_05_01"];

// airJet
East_Air_Jet = ["vn_o_air_mig19_cap", "vn_o_air_mig19_cas", "vn_o_air_mig21_cap", "vn_o_air_mig21_cas"];

// airDrone
East_Air_Drone = [];

// mobileAA
East_Mobile_AA = ["vn_o_wheeled_z157_mg_02"];

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

