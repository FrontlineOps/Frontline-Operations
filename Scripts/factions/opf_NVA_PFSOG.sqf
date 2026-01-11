// ============================================================================
// NVA FACTION - OPFOR (PFSOG Mod)
// North Vietnamese Army forces
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Patrol"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_AT_Team"),
    (configfile >> "CfgGroups" >> "East" >> "VN_PAVN" >> "Infantry" >> "VN_PAVN_Infantry_Weapons_Team")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "vn_o_men_nva_01", "vn_o_men_nva_01",
    "vn_o_men_nva_07", "vn_o_men_nva_07",
    "vn_o_men_nva_06", "vn_o_men_nva_06",
    "vn_o_men_nva_04",
    "vn_o_men_nva_03",
    "vn_o_men_nva_10",
    "vn_o_men_nva_14",
    "vn_o_men_nva_11",
    "vn_o_men_nva_08"
];

East_Units_Officers = ["vn_o_men_nva_65_01"];
East_FireObserver = ["vn_o_men_nva_04"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "vn_o_wheeled_z157_01", "vn_o_wheeled_z157_02",
    "vn_o_car_01_01", "vn_o_car_03_01", "vn_o_car_02_01"
];

East_Ground_Vehicles_Light = [
    "vn_o_wheeled_btr40_mg_01", "vn_o_wheeled_btr40_mg_02",
    "vn_o_wheeled_z157_mg_01", "vn_o_wheeled_btr40_01"
];

East_Ground_Vehicles_Heavy = [
    "vn_o_armor_type63_01", "vn_o_armor_m41_01", "vn_o_armor_pt76a_01",
    "vn_o_armor_pt76b_01", "vn_o_armor_t54b_01"
];

East_Ground_Transport = [
    "vn_o_wheeled_z157_01", "vn_o_wheeled_z157_02", "vn_o_wheeled_btr40_01"
];

East_Ground_Artillery = [
    "vn_o_vc_static_mortar_type53", "vn_o_vc_static_mortar_type63", "vn_o_nva_static_d44"
];

East_Air_Transport = ["vn_o_air_mi2_01_01", "vn_o_air_mi2_01_02"];

East_Air_Heli = ["vn_o_air_mi2_04_01", "vn_o_air_mi2_04_02", "vn_o_air_mi2_05_01"];

East_Air_Jet = ["vn_o_air_mig19_cap", "vn_o_air_mig19_cas", "vn_o_air_mig21_cap", "vn_o_air_mig21_cas"];

East_Air_Drone = [];

East_Mobile_AA = ["vn_o_wheeled_z157_mg_02"];

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

// ============================================================================
// VIRTUALIZATION SETTINGS
// ============================================================================
OPFOR_Objective_Size_Threshold = "Medium";
OPFOR_Virtualization_Distance = 2000;