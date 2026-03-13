// ============================================================================
// IRANIAN AF FACTION - OPFOR (POF Mod)
// Iranian Armed Forces
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_IRAN" >> "Infantry" >> "LOP_IRAN_Infantry_AATeam")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
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

East_Units_Officers = ["LOP_IRAN_Infantry_Officer"];
East_FireObserver = ["LOP_IRAN_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "LOP_IRAN_UAZ", "LOP_IRAN_Ural", "LOP_IRAN_UAZ_Open", "LOP_IRAN_KAMAZ_Transport",
    "LOP_IRAN_UAZ_DshKM", "LOP_IRAN_UAZ_AGS", "LOP_IRAN_UAZ_SPG"
];

East_Ground_Vehicles_Light = [
    "LOP_IRAN_UAZ_DshKM", "LOP_IRAN_UAZ_AGS", "LOP_IRAN_UAZ_SPG",
    "LOP_IRAN_M113_W", "LOP_IRAN_BTR60"
];

East_Ground_Vehicles_Heavy = [
    "LOP_IRAN_BMP1", "LOP_IRAN_BMP2", "LOP_IRAN_M113_W",
    "LOP_IRAN_BTR60", "LOP_IRAN_T72BA", "LOP_IRAN_ZSU234"
];

East_Ground_Transport = [
    "LOP_IRAN_UAZ", "LOP_IRAN_Ural", "LOP_IRAN_UAZ_Open", "LOP_IRAN_KAMAZ_Transport"
];

East_Ground_Artillery = ["LOP_IRAN_BM21", "LOP_IRAN_2S1"];

East_Air_Transport = ["LOP_IRAN_CH47F", "LOP_IRAN_UH1Y"];

East_Air_Heli = ["LOP_IRAN_AH1Z_CS", "LOP_IRAN_AH1Z_GS", "LOP_IRAN_UH1Y_Armed"];

East_Air_Jet = ["LOP_IRAN_MIG21Bis"];

East_Air_Drone = ["O_UAV_01_F", "O_UAV_02_dynamicLoadout_F"];

East_Mobile_AA = ["LOP_IRAN_ZSU234"];

East_Static_AA = ["O_SAM_System_04_F"];

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

