// ============================================================================
// EAST EUROPEAN CIVILIAN FACTION (CUP)
// Chernarussian civilian population
// ============================================================================

// Civilian population configuration
CiviliansPerLocationMin = 5;
CiviliansPerLocationMax = 15;

// ============================================================================
// CIVILIAN UNITS & VEHICLES
// ============================================================================
CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_C_CHERNARUS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
CivMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_C_CHERNARUS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};

// ============================================================================
// GUERRILLA/RESISTANCE UNITS
// ============================================================================
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_I_NAPA')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_I_NAPA')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
