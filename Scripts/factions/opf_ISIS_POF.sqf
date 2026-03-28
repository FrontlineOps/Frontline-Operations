// ============================================================================
// ISIS FACTION - OPFOR (POF Mod)
// Islamic State insurgent forces
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
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_AATeam"),
    "LOP_ISTS_Infantry_Rifleman", "LOP_ISTS_Infantry_Rifleman",
    "LOP_ISTS_Infantry_AR", "LOP_ISTS_Infantry_AR",
    "LOP_ISTS_Infantry_GL", "LOP_ISTS_Infantry_GL",
    "LOP_ISTS_Infantry_TL",
    "LOP_ISTS_Infantry_SL",
    "LOP_ISTS_Infantry_Marksman",
    "LOP_ISTS_Infantry_AT",
    "LOP_ISTS_Infantry_AA",
    "LOP_ISTS_Infantry_Corpsman"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["LOP_ISTS_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "LOP_ISTS_Landrover_M2", "LOP_ISTS_Offroad_M2", "LOP_ISTS_M1025_W_M2",
    "LOP_ISTS_M1025_W_Mk19", "LOP_ISTS_BTR60", "LOP_ISTS_M113_W"
];

// groundMechanized
East_Ground_Mechanized = [
    "LOP_ISTS_BMP1", "LOP_ISTS_BMP2", "LOP_ISTS_T72BA", "LOP_ISTS_T72BB", "LOP_ISTS_ZSU234"
];
// groundArmor
East_Ground_Armor = [
    "LOP_ISTS_BMP1", "LOP_ISTS_BMP2", "LOP_ISTS_T72BA", "LOP_ISTS_T72BB", "LOP_ISTS_ZSU234"
];

// groundTransport
East_Ground_Transport = [
    "LOP_ISTS_Landrover", "LOP_ISTS_Truck", "LOP_ISTS_M998_D_4DR", "LOP_ISTS_Offroad"
];

// groundArtillery
East_Ground_Artillery = ["LOP_ISTS_BM21", "LOP_ISTS_2S1"];

// airTransport
East_Air_Transport = ["LOP_ISTS_Mi8MT_Cargo"];

// airHeli
East_Air_Heli = ["LOP_ISTS_Mi8MTV3_FAB", "LOP_ISTS_Mi8MTV3_UPK23"];

// airJet
East_Air_Jet = ["LOP_ISTS_Mi8MTV3_FAB"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["LOP_ISTS_ZSU234"];

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

