// ============================================================================
// TTI DESERT FACTION - OPFOR (Western Sahara DLC)
// Tura insurgent forces in desert camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfTeam_lxWS"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfSquad_lxWS")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "O_Tura_watcher_lxWS", "O_Tura_watcher_lxWS",
    "O_Tura_enforcer_lxWS", "O_Tura_enforcer_lxWS",
    "O_Tura_thug_lxWS", "O_Tura_thug_lxWS",
    "O_Tura_scout_lxWS",
    "O_Tura_deserter_lxWS",
    "O_Tura_hireling_lxWS",
    "O_Tura_medic2_lxWS"
];

East_Units_Officers = ["O_SFIA_officer_lxWS"];
East_FireObserver = ["O_Tura_watcher_lxWS"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "O_SFIA_Offroad_lxWS", "I_C_Offroad_02_AT_F", "I_C_Offroad_02_LMG_F",
    "O_Tura_Offroad_armor_lxWS", "I_C_Offroad_02_unarmed_F",
    "O_SFIA_Truck_02_transport_lxWS", "O_T_Quadbike_01_ghex_F"
];

East_Ground_Vehicles_Light = [
    "O_Tura_Offroad_armor_lxWS", "O_Tura_Offroad_armor_AT_lxWS",
    "O_Tura_Offroad_armor_armed_lxWS", "O_SFIA_Offroad_AT_lxWS",
    "I_C_Offroad_02_LMG_F", "O_Tura_Truck_02_aa_lxWS"
];

East_Ground_Vehicles_Heavy = [
    "O_SFIA_APC_Tracked_02_cannon_lxWS", "O_Tura_Truck_02_aa_lxWS", "O_SFIA_Truck_02_MRL_lxWS"
];

East_Ground_Transport = [
    "O_Tura_Offroad_armor_lxWS", "O_SFIA_Truck_02_transport_lxWS", "O_SFIA_Offroad_lxWS"
];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["I_C_Heli_Light_01_civil_F", "O_Heli_Transport_04_covered_F"];

East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"];

East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"];

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