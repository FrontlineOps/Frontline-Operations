// ============================================================================
// EAST EUROPEAN CIVILIAN FACTION (Vanilla)
// Livonian/Eastern European civilian population
// ============================================================================

// ============================================================================
// CIVILIAN POPULATION CONFIGURATION
// ============================================================================
CiviliansPerLocationMin = 5;
CiviliansPerLocationMax = 15;

// Building classes considered civilian (for spawning civilians inside)
CivBuildingClasses = [
    "House_F", "Building", "Land_i_House_Small_03_V1_F", "Land_i_House_Big_01_V1_F"
];

// ============================================================================
// CIVILIAN UNITS
// ============================================================================
CivMenArray = [
    "C_man_enoch_base_F", "C_Man_1_enoch_F", "C_Man_2_enoch_F",
    "C_Man_3_enoch_F", "C_Man_4_enoch_F", "C_Man_5_enoch_F",
    "C_Man_6_enoch_F", "C_Farmer_01_enoch_F",
    "C_man_p_fugitive_F", "C_man_p_beggar_F", "C_man_w_worker_F",
    "C_scientist_F", "C_Journalist_01_War_F", "C_Man_UtilityWorker_01_F",
    "C_Man_Fisherman_01_F", "C_Man_Messenger_01_F", "C_Story_Mechanic_01_F",
    "C_E_Man_Base_F", "C_scientist_01_formal_F", "C_scientist_02_formal_F",
    "C_scientist_01_informal_F", "C_scientist_02_informal_F",
    "C_Man_casual_6_F_euro", "C_Man_casual_5_F_euro", "C_Man_casual_3_F_euro",
    "C_Man_casual_4_F_euro", "C_Man_casual_4_v2_F_euro", "C_Man_smart_casual_1_F_euro",
    "C_Man_casual_5_v2_F_euro", "C_Man_casual_6_v2_F_euro", "C_Man_casual_7_F_euro"
];

// ============================================================================
// GUERRILLA/RESISTANCE UNITS
// ============================================================================
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'IND_L_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'IND_L_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};