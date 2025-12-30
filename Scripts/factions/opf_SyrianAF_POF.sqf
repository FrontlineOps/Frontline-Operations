// ============================================================================
// SYRIAN AF FACTION - OPFOR (POF Mod)
// Syrian Armed Forces
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_Rifle_squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_Patrol_section"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_SYR" >> "Infantry" >> "LOP_SYR_AT_section")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
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

East_Units_Officers = ["LOP_SYR_Infantry_SL"];
East_FireObserver = ["LOP_SYR_Infantry_TL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "LOP_SYR_Ural_open", "LOP_SYR_UAZ_Open", "LOP_SLA_BTR70", "LOP_SYR_BTR80",
    "LOP_SYR_UAZ_DshKM", "LOP_SYR_UAZ_SPG", "LOP_IRA_Landrover_M2",
    "LOP_IRA_Landrover_SPG9", "LOP_SYR_UAZ"
];

East_Ground_Vehicles_Light = [
    "LOP_SLA_BTR70", "LOP_SYR_BTR80", "LOP_SYR_UAZ_DshKM", "LOP_SYR_UAZ_SPG",
    "LOP_IRA_Landrover_M2", "LOP_IRA_Landrover_SPG9", "LOP_SYR_UAZ"
];

East_Ground_Vehicles_Heavy = [
    "LOP_SYR_ZSU234", "LOP_ISTS_OPF_BMP2", "LOP_SYR_BMP2",
    "LOP_SYR_BMP1", "LOP_SYR_T55", "LOP_SYR_T72BA"
];

East_Ground_Transport = ["LOP_SYR_Ural_open", "LOP_SYR_UAZ_Open"];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["rhsgref_ins_Mi8amt"];

East_Air_Heli = ["rhsgref_ins_Mi8amt"];

East_Air_Jet = ["rhsgref_ins_Mi8amt"];

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
    ["motorized", 2],
    ["mechanized", 2],
    ["armor", 2],
    ["helicopter", 1],
    ["jet", 1],
    ["air", 1],
    ["artillery", 1]
];

// ============================================================================
// VIRTUALIZATION SETTINGS
// ============================================================================
OPFOR_Objective_Size_Threshold = "Medium";
OPFOR_Virtualization_Distance = 2000;