// ============================================================================
// SYNDIKAT WOODLAND FACTION - OPFOR (Vanilla)
// Syndikat paramilitary forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaShockTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaFireTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaCombatGroup")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "I_C_Soldier_Para_1_F", "I_C_Soldier_Para_1_F",
    "I_C_Soldier_Para_2_F", "I_C_Soldier_Para_2_F",
    "I_C_Soldier_Para_3_F", "I_C_Soldier_Para_3_F",
    "I_C_Soldier_Para_4_F",
    "I_C_Soldier_Para_5_F",
    "I_C_Soldier_Para_6_F",
    "I_C_Soldier_Para_7_F",
    "I_C_Soldier_Para_8_F"
];

East_Units_Officers = ["I_C_Soldier_Para_4_F"];
East_FireObserver = ["I_C_Soldier_Para_4_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "I_G_Offroad_01_armed_F", "I_C_Offroad_02_AT_F", "I_C_Offroad_02_LMG_F",
    "I_C_Offroad_02_unarmed_F", "I_C_Van_01_transport_F",
    "I_C_Van_02_transport_F", "O_T_Quadbike_01_ghex_F"
];

East_Ground_Vehicles_Light = [
    "I_G_Offroad_01_armed_F", "I_C_Offroad_02_LMG_F", "I_C_Offroad_02_AT_F"
];

East_Ground_Vehicles_Heavy = [
    "I_E_APC_tracked_03_cannon_F", "I_C_Offroad_02_AT_F", "I_G_Offroad_01_armed_F"
];

East_Ground_Transport = [
    "I_C_Van_01_transport_F", "I_C_Van_02_transport_F", "I_C_Offroad_02_unarmed_F"
];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["I_C_Heli_Light_01_civil_F"];

East_Air_Heli = ["I_C_Heli_Light_01_civil_F"];

East_Air_Jet = ["I_C_Heli_Light_01_civil_F"];

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