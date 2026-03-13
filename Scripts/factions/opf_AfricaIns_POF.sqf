// ============================================================================
// AFRICAN INSURGENTS FACTION - OPFOR (POF Mod)
// African rebel/insurgent forces
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_ATTeam"),
    (configfile >> "CfgGroups" >> "East" >> "LOP_AFR_OPF" >> "Infantry" >> "LOP_AFR_OPF_Infantry_AATeam")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
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

East_Units_Officers = ["LOP_AFR_OPF_Infantry_SL"];
East_FireObserver = ["LOP_AFR_OPF_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "LOP_AFR_OPF_Offroad", "LOP_AFR_OPF_Truck", "I_G_Van_01_transport_F",
    "I_G_Van_02_transport_F", "LOP_AFR_OPF_BTR60", "LOP_AFR_OPF_Offroad_AT",
    "LOP_AFR_OPF_Offroad_M2", "LOP_AFR_OPF_Nissan_PKM",
    "I_C_Offroad_02_AT_F", "I_C_Offroad_02_LMG_F",
    "O_G_Offroad_01_AT_F", "O_G_Offroad_01_armed_F"
];

East_Ground_Vehicles_Light = [
    "LOP_AFR_OPF_BTR60", "LOP_AFR_OPF_Offroad_AT", "LOP_AFR_OPF_Offroad_M2",
    "LOP_AFR_OPF_Nissan_PKM", "I_C_Offroad_02_AT_F", "I_C_Offroad_02_LMG_F",
    "O_G_Offroad_01_AT_F", "O_G_Offroad_01_armed_F"
];

East_Ground_Vehicles_Heavy = [
    "LOP_AFR_OPF_T34", "LOP_ChDKZ_BMP1", "LOP_AFR_OPF_M113_W", "LOP_AFR_OPF_BTR60"
];

East_Ground_Transport = [
    "LOP_AFR_OPF_Offroad", "LOP_AFR_OPF_Truck",
    "I_G_Van_01_transport_F", "I_G_Van_02_transport_F"
];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["rhsgref_ins_Mi8amt"];

East_Air_Heli = ["rhsgref_ins_Mi8amt"];

East_Air_Jet = ["rhsgref_ins_Mi8amt"];

East_Air_Drone = ["O_UAV_01_F"];

East_Mobile_AA = ["O_APC_Tracked_02_AA_F"];

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

