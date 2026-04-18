/*
 * Faction Group Initialization
 * Author: Frontline Operations
 *
 * Description:
 * Initializes faction-specific unit arrays and vehicle classes based on the
 * selected player, enemy, and civilian factions from the mission setup dialog.
 *
 * Each faction script is responsible for defining:
 * - Unit class arrays (infantry, vehicles, aircraft)
 * - Weapon and equipment loadouts
 * - Faction-specific behavior settings
 *
 * Dependencies:
 * - FLO_FriendlyHandle (hashmap with faction data)
 * - FLO_EnemyHandle (hashmap with faction data)
 * - FLO_CivilianHandle (hashmap with faction data)
 *
 * Global Variables Set:
 * - F_Init: Boolean flag indicating faction initialization complete
 * - CivVehArray: Array of civilian vehicle classnames
 */

// ============================================================================
// INITIALIZATION
// ============================================================================

F_Init = false;
publicVariable "F_Init";

["INIT_FACTIONS", 3, "Starting faction initialization..."] call FLO_fnc_log;

// Validate faction handles exist
if (isNil "FLO_FriendlyHandle" || isNil "FLO_EnemyHandle" || isNil "FLO_CivilianHandle") then {
    ["INIT_FACTIONS", 1, "CRITICAL: Faction handles not set! Waiting for faction dialog..."] call FLO_fnc_log;
    waitUntil {
        sleep 0.5;
        !isNil "FLO_FriendlyHandle" && !isNil "FLO_EnemyHandle" && !isNil "FLO_CivilianHandle"
    };
    ["INIT_FACTIONS", 3, "Faction handles now available"] call FLO_fnc_log;
};

// Helper function to safely load faction files with error handling
private _fnc_loadFactionFile = {
    params ["_factionType", "_filePath"];

    try {
        ["INIT_FACTIONS", 3, format["Loading %1 from: %2", _factionType, _filePath]] call FLO_fnc_log;
        call compileScript [_filePath];
        ["INIT_FACTIONS", 3, format["%1 loaded successfully", _factionType]] call FLO_fnc_log;
        true
    } catch {
        ["INIT_FACTIONS", 1, format["ERROR loading %1 from %2: %3", _factionType, _filePath, _exception]] call FLO_fnc_log;
        false
    };
};

// ============================================================================
// FRIENDLY FACTION
// ============================================================================

private _bluFaction = FLO_FriendlyHandle get "name";
["INIT_FACTIONS", 3, format["Loading friendly faction: %1", _bluFaction]] call FLO_fnc_log;

switch (_bluFaction) do {
	case "CUSTOM_PLAYER_FACTION": {
		call compileScript ["CUSTOM_PLAYER_FACTION.sqf"];
	};
	case "NATO _ Desert": {
		call compileScript ["Scripts\factions\blu_NATODesert.sqf"];
	};
	case "AAF _ Woodland": {
		call compileScript ["Scripts\factions\blu_AAF.sqf"];
	};
	case "ADF _ Re-Cut": {
		call compileScript ["Scripts\factions\blu_ADF_RC.sqf"];
	};
	case "BWMod _ RHSUSAF": {
		call compileScript ["Scripts\factions\blu_BW_RHS.sqf"];
	};
	case "UAF _ CUP-UAFVP": {
		call compileScript ["Scripts\factions\blu_UAF_CUP_UAFVP.sqf"];
	};
	case "USMC _ Current Issue": {
		call compileScript ["Scripts\factions\blu_USMC_CI.sqf"];
	};
	case "USMC _ CUP-EF": {
		call compileScript ["Scripts\factions\blu_USMC_CUP_EF.sqf"];
	};
	default {
		["INIT_FACTIONS", 1, format["Unknown friendly faction: %1", _bluFaction]] call FLO_fnc_log;
	};
};

// ============================================================================
// ENEMY FACTION
// ============================================================================

private _opfFaction = FLO_EnemyHandle get "name";
["INIT_FACTIONS", 3, format["Loading enemy faction: %1", _opfFaction]] call FLO_fnc_log;

switch (_opfFaction) do {
	case "CUSTOM_ENEMY_FACTION": {
		call compileScript ["CUSTOM_ENEMY_FACTION.sqf"];
	};
	case "CSAT _ Desert": {
		call compileScript ["Scripts\factions\opf_CSATDesert.sqf"];
	};
	case "Grozovia _ 3CB": {
		call compileScript ["Scripts\factions\opf_Grozovia_3CB.sqf"];
	};
	case "IAF _ CUP-EF": {
		call compileScript ["Scripts\factions\opf_IAF_CUP_EF.sqf"];
	};
	case "Russian AF _ CUP": {
		call compileScript ["Scripts\factions\opf_RU_CUP.sqf"];
	};
	default {
		["INIT_FACTIONS", 1, format["Unknown enemy faction: %1 - loading defaults", _opfFaction]] call FLO_fnc_log;
		// Load default enemy faction to ensure arrays exist
		call compileScript ["CUSTOM_ENEMY_FACTION.sqf"];
	};
};

// ============================================================================
// CIVILIAN FACTION
// ============================================================================

private _civFaction = FLO_CivilianHandle get "name";
["INIT_FACTIONS", 3, format["Loading civilian faction: %1", _civFaction]] call FLO_fnc_log;

// Default civilian vehicles (can be overridden by faction scripts)
CivVehArray = [
	"C_Truck_02_covered_F",
	"C_Truck_02_transport_F",
	"C_Truck_02_fuel_F",
	"C_Van_02_vehicle_F",
	"C_Van_02_service_F",
	"C_Truck_02_box_F",
	"C_Van_02_medevac_F",
	"C_Van_01_fuel_F",
	"C_Hatchback_01_sport_F",
	"C_Hatchback_01_F",
	"C_Offroad_01_F",
	"C_Offroad_02_unarmed_F",
	"C_Offroad_01_comms_F",
	"C_Offroad_01_covered_F",
	"C_Offroad_01_repair_F",
	"C_Van_01_box_F",
	"C_Van_01_transport_F",
	"C_Tractor_01_F",
	"C_SUV_01_F",
	"C_Quadbike_01_F"
];

switch (_civFaction) do {
	case "CUSTOM_CIVILIAN_FACTION": {
		call compileScript ["CUSTOM_CIVILIAN_FACTION.sqf"];
	};
	case "Greek Civilians": {
		call compileScript ["Scripts\factions\civ_Greek.sqf"];
	};
	default {
		["INIT_FACTIONS", 1, format["Unknown civilian faction: %1", _civFaction]] call FLO_fnc_log;
	};
};

// ============================================================================
// FINALIZATION
// ============================================================================

["INIT_FACTIONS", 3, "Faction initialization complete"] call FLO_fnc_log;

F_Init = true;
publicVariable "F_Init";
