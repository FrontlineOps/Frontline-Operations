// ============================================================================
// EAST EUROPEAN INSURGENTS WOODLAND FACTION - OPFOR (AEW Mod)
// Eastern European insurgent forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistShockTeam"),
    (configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistFireTeam"),
    (configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistCombatGroup")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "LOP_ChDKZ_Infantry_Rifleman", "LOP_ChDKZ_Infantry_Rifleman",
    "LOP_ChDKZ_Infantry_MG", "LOP_ChDKZ_Infantry_MG",
    "LOP_ChDKZ_Infantry_GL", "LOP_ChDKZ_Infantry_GL",
    "LOP_ChDKZ_Infantry_TL",
    "LOP_ChDKZ_Infantry_SL",
    "LOP_ChDKZ_Infantry_Marksman",
    "LOP_ChDKZ_Infantry_AT",
    "LOP_ChDKZ_Infantry_AA",
    "LOP_ChDKZ_Infantry_Corpsman"
];

East_Units_Officers = ["LOP_ChDKZ_Infantry_Commander"];
East_FireObserver = ["LOP_ChDKZ_Infantry_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "Opf_I_I_Offroad_01_F", "Opf_I_I_Van_01_transport_F",
    "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_AT_F"
];

East_Ground_Vehicles_Light = [
    "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_O_S_Offroad_01_AT_F"
];

East_Ground_Vehicles_Heavy = [
    "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_O_S_Offroad_01_AT_F", "Opf_O_S_Offroad_01_armed_F"
];

East_Ground_Transport = ["Opf_O_S_Offroad_01_F", "Opf_O_S_Truck_02_transport_F"];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["Opf_I_R_Heli_Light_02_unarmed_F"];

East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"];

East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"];

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

