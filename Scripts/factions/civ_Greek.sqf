// ============================================================================
// GREEK CIVILIAN FACTION (Vanilla)
// Mediterranean/Greek civilian population
// ============================================================================

// ============================================================================
// CIVILIAN POPULATION CONFIGURATION
// ============================================================================
CiviliansPerLocationMin = 5;
CiviliansPerLocationMax = 10;

// Building classes considered civilian (for spawning civilians inside)
CivBuildingClasses = [
    "House_F", "Building", "Land_i_House_Small_03_V1_F", "Land_i_House_Big_01_V1_F"
];

// ============================================================================
// CIVILIAN UNITS
// ============================================================================
CivMenArray = [
    "C_Man_casual_9_F_euro", "C_Man_casual_8_F_euro",
    "C_man_polo_1_F_euro", "C_man_polo_2_F_euro", "C_man_polo_3_F_euro",
    "C_man_polo_4_F_euro", "C_man_polo_5_F_euro", "C_man_polo_6_F_euro",
    "C_man_p_fugitive_F_euro", "C_man_p_beggar_F_euro", "C_man_p_shorts_1_F_euro",
    "C_man_shorts_1_F_euro", "C_man_shorts_2_F_euro", "C_man_shorts_3_F_euro", "C_man_shorts_4_F_euro",
    "C_man_sport_1_F_euro", "C_man_sport_2_F_euro", "C_man_sport_3_F_euro",
    "C_Man_casual_1_F_euro", "C_Man_casual_2_F_euro",
    "C_Journalist_01_War_F", "C_Man_UtilityWorker_01_F",
    "C_Man_Fisherman_01_F", "C_Man_Messenger_01_F", "C_Story_Mechanic_01_F",
    "C_scientist_01_formal_F", "C_scientist_02_formal_F",
    "C_scientist_01_informal_F", "C_scientist_02_informal_F",
    "C_Man_casual_6_F_euro", "C_Man_casual_5_F_euro", "C_Man_casual_3_F_euro",
    "C_Man_casual_4_F_euro", "C_Man_casual_4_v2_F_euro", "C_Man_smart_casual_1_F_euro",
    "C_Man_casual_5_v2_F_euro", "C_Man_casual_6_v2_F_euro", "C_Man_casual_7_F_euro",
    "C_man_p_fugitive_F", "C_man_p_beggar_F", "C_man_w_worker_F", "C_scientist_F"
];

// ============================================================================
// GUERRILLA/RESISTANCE UNITS
// ============================================================================
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};