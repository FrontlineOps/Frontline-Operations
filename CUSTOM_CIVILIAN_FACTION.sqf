//If you want to Use Faction classnames, Use These two Lines Below and Replace 'CUP_C_CHERNARUS' with your Chosen Civilian Faction classname ! Be sure to remove first two Slashes !
//CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_C_CHERNARUS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//CivMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_C_CHERNARUS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};

//If you want to Use Faction classnames, Use These two Lines Below and Replace 'CUP_I_NAPA' with your Chosen Guerilla Faction classname ! Be sure to remove first two Slashes !
//GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_I_NAPA')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_I_NAPA')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};

// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

// Civilian population configuration
CiviliansPerLocationMin = 10;
CiviliansPerLocationMax = 25;

// List of building classes considered civilian (expand as needed)
CivBuildingClasses = [
    "House_F", "Building", "Land_i_House_Small_03_V1_F", "Land_i_House_Big_01_V1_F"
    // Add more as needed
];

// Default civilian classnames (Vanilla Arma 3)
CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CIV_F')" configClasses (configFile >> "CfgVehicles")) apply {configName _x};
CivMenArray = ("(configname _x iskindOf 'CAManBase') && !(['CivilianPresence_',configName _x] call bis_fnc_inString) && (gettext (_x >> 'faction') == 'CIV_F') && (getNumber (_x >> 'scope') >= 2)" configClasses (configFile >> "CfgVehicles")) apply {configName _x};

// Default guerilla classnames (Vanilla Arma 3)
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configFile >> "CfgVehicles")) apply {configName _x};
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configFile >> "CfgVehicles")) apply {configName _x};
