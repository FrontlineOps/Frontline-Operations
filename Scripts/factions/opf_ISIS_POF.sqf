// ============================================================================
// ISIS FACTION - OPFOR (POF Mod)
// Islamic State insurgent forces
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_ISTS" >> "Infantry" >> "LOP_ISTS_Infantry_AATeam")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
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

East_Units_Officers = ["LOP_ISTS_Infantry_TL"];
East_FireObserver = ["LOP_ISTS_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "LOP_ISTS_Landrover", "LOP_ISTS_Truck", "LOP_ISTS_M998_D_4DR",
    "LOP_ISTS_Offroad", "LOP_ISTS_Landrover_M2", "LOP_ISTS_Offroad_M2", "LOP_ISTS_BMP2"
];

East_Ground_Vehicles_Light = [
    "LOP_ISTS_Landrover_M2", "LOP_ISTS_Offroad_M2", "LOP_ISTS_M1025_W_M2",
    "LOP_ISTS_M1025_W_Mk19", "LOP_ISTS_BTR60", "LOP_ISTS_M113_W"
];

East_Ground_Vehicles_Heavy = [
    "LOP_ISTS_BMP1", "LOP_ISTS_BMP2", "LOP_ISTS_T72BA", "LOP_ISTS_T72BB", "LOP_ISTS_ZSU234"
];

East_Ground_Transport = [
    "LOP_ISTS_Landrover", "LOP_ISTS_Truck", "LOP_ISTS_M998_D_4DR", "LOP_ISTS_Offroad"
];

East_Ground_Artillery = ["LOP_ISTS_BM21", "LOP_ISTS_2S1"];

East_Air_Transport = ["LOP_ISTS_Mi8MT_Cargo"];

East_Air_Heli = ["LOP_ISTS_Mi8MTV3_FAB", "LOP_ISTS_Mi8MTV3_UPK23"];

East_Air_Jet = ["LOP_ISTS_Mi8MTV3_FAB"];

East_Air_Drone = ["O_UAV_01_F"];

// ============================================================================
// GARRISON CONFIGURATION
// ============================================================================
OPFOR_Objective_Groups = [
    ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["air", 1], ["armor", 1], ["artillery", 1]]],
    ["city", [["infantry", 7], ["motorized", 2]]],
    ["village", [["infantry", 3]]],
    ["local", [["infantry", 6], ["motorized", 2], ["mechanized", 1]]],
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
    ["artillery", 3]
];

// ============================================================================
// VIRTUALIZATION SETTINGS
// ============================================================================
OPFOR_Objective_Size_Threshold = "Medium";
OPFOR_Virtualization_Distance = 2000;