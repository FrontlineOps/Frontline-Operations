// ============================================================================
// RUSSIAN AF WOODLAND FACTION - OPFOR (RHS Mod)
// Russian VDV forces in flora camouflage
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
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_fireteam"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_section_AT"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_section_AA"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_squad_mg_sniper"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_squad_2mg"),
    "rhs_vdv_flora_rifleman", "rhs_vdv_flora_rifleman", "rhs_vdv_flora_rifleman",
    "rhs_vdv_flora_machinegunner", "rhs_vdv_flora_machinegunner",
    "rhs_vdv_flora_grenadier", "rhs_vdv_flora_grenadier",
    "rhs_vdv_flora_medic", "rhs_vdv_flora_medic",
    "rhs_vdv_flora_marksman",
    "rhs_vdv_flora_efreitor",
    "rhs_vdv_flora_LAT",
    "rhs_vdv_flora_at",
    "rhs_vdv_flora_engineer"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["rhs_vdv_des_officer"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = ["rhs_btr60_vmf", "rhs_tigr_sts_msv"];

// groundMechanized
East_Ground_Mechanized = [
    "rhs_zsu234_aa", "rhs_Ob_681_2", "rhs_bmp2_tv", "rhs_bmp1_tv",
    "rhs_t72be_tv", "rhs_t80bvk", "rhs_t90sm_tv"
];
// groundArmor
East_Ground_Armor = [
    "rhs_zsu234_aa", "rhs_Ob_681_2", "rhs_bmp2_tv", "rhs_bmp1_tv",
    "rhs_t72be_tv", "rhs_t80bvk", "rhs_t90sm_tv"
];

// groundTransport
East_Ground_Transport = ["rhs_tigr_msv", "rhs_gaz66_msv", "rhs_gaz66o_msv"];

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["rhs_ka60_c", "RHS_Mi8mt_vvsc", "RHS_Mi8MTV3_heavy_vvsc"];

// airHeli
East_Air_Heli = ["RHS_Ka52_vvsc", "RHS_Mi24P_vdv"];

// airJet
East_Air_Jet = ["rhs_mig29sm_vvsc", "RHS_Su25SM_vvsc"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["rhs_zsu234_aa"];

// staticAA
East_Static_AA = ["rhs_S300_launcher_radar_F"];

// radar
East_Radar = ["rhs_S300_launcher_radar_F"];

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

