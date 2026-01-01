// ============================================================================
// VIETNAM CIVILIAN FACTION (S.O.G. Prairie Fire)
// Vietnamese civilian population
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
// CIVILIAN VEHICLES
// ============================================================================
CivVehArray = [
    "C_Truck_02_covered_F", "C_Truck_02_transport_F",
    "vn_c_car_01_01", "vn_c_car_03_01", "vn_c_car_02_01",
    "C_Truck_02_box_F", "vn_c_wheeled_m151_02", "vn_c_wheeled_m151_01",
    "C_Tractor_01_F", "vn_c_car_04_01"
];

// ============================================================================
// CIVILIAN UNITS
// ============================================================================
CivMenArray = [
    "vn_c_men_29", "vn_c_men_28", "vn_c_men_27", "vn_c_men_26", "vn_c_men_25",
    "vn_c_men_24", "vn_c_men_23", "vn_c_men_22", "vn_c_men_21", "vn_c_men_20",
    "vn_c_men_19", "vn_c_men_18", "vn_c_men_17", "vn_c_men_16", "vn_c_men_15",
    "vn_c_men_14", "vn_c_men_13", "vn_c_men_12", "vn_c_men_11", "vn_c_men_10",
    "vn_c_men_09", "vn_c_men_08", "vn_c_men_07", "vn_c_men_06", "vn_c_men_05",
    "vn_c_men_04", "vn_c_men_03", "vn_c_men_02", "vn_c_men_01"
];

// ============================================================================
// GUERRILLA/RESISTANCE UNITS
// ============================================================================
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'I_LAO')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'I_LAO')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};