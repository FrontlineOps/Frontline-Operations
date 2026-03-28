// ============================================================================
// AFRICAN INSURGENTS FACTION - OPFOR (POF Mod)
// African rebel/insurgent forces
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
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_AATeam"),
    "LOP_AFRCiv_Soldier", "LOP_AFRCiv_Soldier",
    "LOP_AFRCiv_Soldier_AR", "LOP_AFRCiv_Soldier_AR",
    "LOP_AFRCiv_Soldier_IED", "LOP_AFRCiv_Soldier_IED",
    "LOP_AFRCiv_Soldier_SL",
    "LOP_AFRCiv_Soldier_AT",
    "LOP_AFRCiv_Soldier_Marksman",
    "LOP_AFRCiv_Soldier_Medic",
    "LOP_AFR_OPF_Infantry_Driver",
    "LOP_AFR_OPF_Infantry_SL"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["LOP_AFR_OPF_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "LOP_AFR_OPF_BTR60", "LOP_AFR_OPF_Offroad_AT", "LOP_AFR_OPF_Offroad_M2",
    "LOP_AFR_OPF_Nissan_PKM", "I_C_Offroad_02_AT_F", "I_C_Offroad_02_LMG_F",
    "O_G_Offroad_01_AT_F", "O_G_Offroad_01_armed_F"
];

// groundMechanized
East_Ground_Mechanized = [
    "LOP_AFR_OPF_T34", "LOP_ChDKZ_BMP1", "LOP_AFR_OPF_M113_W", "LOP_AFR_OPF_BTR60"
];
// groundArmor
East_Ground_Armor = [
    "LOP_AFR_OPF_T34", "LOP_ChDKZ_BMP1", "LOP_AFR_OPF_M113_W", "LOP_AFR_OPF_BTR60"
];

// groundTransport
East_Ground_Transport = [
    "LOP_AFR_OPF_Offroad", "LOP_AFR_OPF_Truck",
    "I_G_Van_01_transport_F", "I_G_Van_02_transport_F"
];

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["rhsgref_ins_Mi8amt"];

// airHeli
East_Air_Heli = ["rhsgref_ins_Mi8amt"];

// airJet
East_Air_Jet = ["rhsgref_ins_Mi8amt"];

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

