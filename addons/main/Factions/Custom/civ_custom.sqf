/*
 * Custom civilian and resistance definition.
 * Keep every field documented in Factions/README.md initialized.
 */

// Civilian population configuration
CiviliansPerLocationMin = 10;
CiviliansPerLocationMax = 25;

// Building classes considered civilian
CivBuildingClasses = [
    "House_F", "Building", "Land_i_House_Small_03_V1_F", "Land_i_House_Big_01_V1_F"
];

// Default civilian classnames (Vanilla Arma 3)
CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CIV_F')" configClasses (configFile >> "CfgVehicles")) apply {configName _x};
CivMenArray = ("(configname _x iskindOf 'CAManBase') && !(['CivilianPresence_',configName _x] call bis_fnc_inString) && (gettext (_x >> 'faction') == 'CIV_F') && (getNumber (_x >> 'scope') >= 2)" configClasses (configFile >> "CfgVehicles")) apply {configName _x};

// Default guerilla classnames (Vanilla Arma 3)
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configFile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configFile >> "CfgVehicles")) apply {configName _x};
