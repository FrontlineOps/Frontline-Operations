//If you want to Use Faction classnames, Use These two Lines Below and Replace 'CUP_C_CHERNARUS' with your Chosen Civilian Faction classname ! Be sure to remove first two Slashes !
//CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_C_CHERNARUS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//CivMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_C_CHERNARUS')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};

//If you want to Use Faction classnames, Use These two Lines Below and Replace 'CUP_I_NAPA' with your Chosen Guerilla Faction classname ! Be sure to remove first two Slashes !
//GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'CUP_I_NAPA')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CUP_I_NAPA')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};

// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,


//Civilian classnames
CivVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'CIV_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//publicVariable "CivVehArray";
CivMenArray = ("(configname _x iskindOf 'CAManBase') && !(['CivilianPresence_',configName _x] call bis_fnc_inString) && (gettext (_x >> 'faction') == 'CIV_F') && (getNumber (_x >> 'scope') >= 2)" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//publicVariable "CivMenArray";

//Guerilla classnames
GuerMenArray = ("(configname _x iskindOf 'CAManBase') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//publicVariable "GuerMenArray";
GuerVehArray = ("(configname _x iskindOf 'car') && (gettext (_x >> 'faction') == 'IND_G_F')" configClasses (configfile >> "CfgVehicles")) apply {configName _x};
//publicVariable "GuerVehArray";