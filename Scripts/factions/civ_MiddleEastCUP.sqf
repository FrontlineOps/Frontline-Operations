// ============================================================================
// MIDDLE EAST CIVILIAN FACTION (CUP)
// Takistani civilian population
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
// CIVILIAN UNITS & VEHICLES
// ============================================================================
CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_C_TK')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
CivMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_C_TK')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};

// ============================================================================
// GUERRILLA/RESISTANCE UNITS
// ============================================================================
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_I_TK_GUE')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_I_TK_GUE')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
