// ============================================================================
// IRANIAN AF FACTION - OPFOR (POF Mod)
// Iranian Armed Forces
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
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_AATeam"),
    "LOP_IRAN_Infantry_Rifleman", "LOP_IRAN_Infantry_Rifleman",
    "LOP_IRAN_Infantry_AR", "LOP_IRAN_Infantry_AR",
    "LOP_IRAN_Infantry_GL", "LOP_IRAN_Infantry_GL",
    "LOP_IRAN_Infantry_TL",
    "LOP_IRAN_Infantry_SL",
    "LOP_IRAN_Infantry_Marksman",
    "LOP_IRAN_Infantry_AT",
    "LOP_IRAN_Infantry_AA",
    "LOP_IRAN_Infantry_Corpsman"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["LOP_IRAN_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "LOP_IRAN_UAZ_DshKM", "LOP_IRAN_UAZ_AGS", "LOP_IRAN_UAZ_SPG",
    "LOP_IRAN_M113_W", "LOP_IRAN_BTR60"
];

// groundMechanized
East_Ground_Mechanized = [
    "LOP_IRAN_BMP1", "LOP_IRAN_BMP2", "LOP_IRAN_M113_W",
    "LOP_IRAN_BTR60", "LOP_IRAN_T72BA", "LOP_IRAN_ZSU234"
];
// groundArmor
East_Ground_Armor = [
    "LOP_IRAN_BMP1", "LOP_IRAN_BMP2", "LOP_IRAN_M113_W",
    "LOP_IRAN_BTR60", "LOP_IRAN_T72BA", "LOP_IRAN_ZSU234"
];

// groundTransport
East_Ground_Transport = [
    "LOP_IRAN_UAZ", "LOP_IRAN_Ural", "LOP_IRAN_UAZ_Open", "LOP_IRAN_KAMAZ_Transport"
];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["LOP_IRAN_BM21", "LOP_IRAN_2S1"];

// airTransport
East_Air_Transport = ["LOP_IRAN_CH47F", "LOP_IRAN_UH1Y"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["LOP_IRAN_AH1Z_CS", "LOP_IRAN_AH1Z_GS", "LOP_IRAN_UH1Y_Armed"];

// airJet
East_Air_Jet = ["LOP_IRAN_MIG21Bis"];

// airDrone
East_Air_Drone = ["O_UAV_01_F", "O_UAV_02_dynamicLoadout_F"];

// mobileAA
East_Mobile_AA = ["LOP_IRAN_ZSU234"];

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

