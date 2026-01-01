// ============================================================================
// WESTERN SAHARA CIVILIAN FACTION (Western Sahara DLC)
// North African civilian population
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
    "C_Djella_05_lxWS", "C_Djella_01_lxWS", "C_Djella_02_lxWS",
    "C_Djella_03_lxWS", "C_Djella_04_lxWS",
    "C_Tak_02_A_lxWS", "C_Tak_02_B_lxWS", "C_Tak_02_C_lxWS",
    "C_Tak_03_A_lxWS", "C_Tak_03_B_lxWS", "C_Tak_03_C_lxWS",
    "C_Tak_01_A_lxWS", "C_Tak_01_B_lxWS", "C_Tak_01_C_lxWS"
];

// ============================================================================
// GUERRILLA/RESISTANCE UNITS
// ============================================================================
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'OPF_TURA_lxWS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'OPF_TURA_lxWS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
