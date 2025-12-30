// ============================================================================
// WESTERN SAHARA CIVILIAN FACTION (Western Sahara DLC)
// North African civilian population
// ============================================================================

// Civilian population configuration
CiviliansPerLocationMin = 5;
CiviliansPerLocationMax = 15;

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
