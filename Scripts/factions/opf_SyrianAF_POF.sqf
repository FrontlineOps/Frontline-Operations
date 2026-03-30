// ============================================================================
// SYRIAN AF FACTION - OPFOR (POF Mod)
// Syrian Armed Forces
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
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_Rifle_squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_Patrol_section"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_AT_section"),
    "LOP_SYR_Infantry_Corpsman", "LOP_SYR_Infantry_Corpsman",
    "LOP_SYR_Infantry_Rifleman", "LOP_SYR_Infantry_Rifleman",
    "LOP_SYR_Infantry_GL", "LOP_SYR_Infantry_GL",
    "LOP_SYR_Infantry_TL",
    "LOP_SYR_Infantry_SL",
    "LOP_SYR_Infantry_Marksman",
    "LOP_SYR_Infantry_AT",
    "LOP_SYR_Infantry_AT_Asst",
    "LOP_SYR_Infantry_MG",
    "LOP_SYR_Infantry_Engineer"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["LOP_SYR_Infantry_TL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "LOP_SLA_BTR70", "LOP_SYR_BTR80", "LOP_SYR_UAZ_DshKM", "LOP_SYR_UAZ_SPG",
    "LOP_IRA_Landrover_M2", "LOP_IRA_Landrover_SPG9", "LOP_SYR_UAZ"
];

// groundMechanized
East_Ground_Mechanized = [
    "LOP_SYR_ZSU234", "LOP_ISTS_OPF_BMP2", "LOP_SYR_BMP2",
    "LOP_SYR_BMP1", "LOP_SYR_T55", "LOP_SYR_T72BA"
];
// groundArmor
East_Ground_Armor = [
    "LOP_SYR_ZSU234", "LOP_ISTS_OPF_BMP2", "LOP_SYR_BMP2",
    "LOP_SYR_BMP1", "LOP_SYR_T55", "LOP_SYR_T72BA"
];

// groundTransport
East_Ground_Transport = ["LOP_SYR_Ural_open", "LOP_SYR_UAZ_Open"];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["rhsgref_ins_Mi8amt"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["rhsgref_ins_Mi8amt"];

// airJet
East_Air_Jet = ["rhsgref_ins_Mi8amt"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["LOP_SYR_ZSU234"];

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

