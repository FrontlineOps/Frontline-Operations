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
	case "BAF _ Desert _ AEW": {
		call compileScript ["Scripts\factions\blu_BAF_Desert_AEW.sqf"];
	};
	case "BAF _ Woodland _ AEW": {
		call compileScript ["Scripts\factions\blu_BAF_Wood_AEW.sqf"];
	};
	case "GAF _ Desert _ BW": {
		call compileScript ["Scripts\factions\blu_GAF_Desert_BW.sqf"];
	};
	case "GAF _ Woodland _ AEW": {
		call compileScript ["Scripts\factions\blu_GAF_Wood_AEW.sqf"];
	};
	case "GAF _ Woodland _ BW": {
		call compileScript ["Scripts\factions\blu_GAF_Wood_BW.sqf"];
	};
	case "IAF _ Woodland _ AEW": {
		call compileScript ["Scripts\factions\blu_IAF_Wood_AEW.sqf"];
	};
	case "LDF _ Woodland _ AEW": {
		call compileScript ["Scripts\factions\blu_LDF_Wood_AEW.sqf"];
	};
	case "NATO _ Desert": {
		call compileScript ["Scripts\factions\blu_NATODesert.sqf"];
	};
	case "NATO _ Woodland": {
		call compileScript ["Scripts\factions\blu_NATOWood.sqf"];
	};
	case "SAF _ Woodland _ FFAA": {
		call compileScript ["Scripts\factions\blu_SAF_Wood_FFAA.sqf"];
	};
	case "US _ Desert _ AEW": {
		call compileScript ["Scripts\factions\blu_US_Desert_AEW.sqf"];
	};
	case "US _ Desert _ CUP RHS": {
		call compileScript ["Scripts\factions\blu_US_Desert_CUP_RHS.sqf"];
	};
	case "US _ PFSOG": {
		call compileScript ["Scripts\factions\blu_US_PFSOG.sqf"];
	};
	case "US _ Woodland _ AEW": {
		call compileScript ["Scripts\factions\blu_US_Wood_AEW.sqf"];
	};
	case "US _ Woodland _ CUP RHS": {
		call compileScript ["Scripts\factions\blu_US_Wood_CUP_RHS.sqf"];
	};
	case "Western Sahara": {
		call compileScript ["Scripts\factions\blu_WesternSahara.sqf"];
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
	case "AAF _ Woodland": {
		call compileScript ["Scripts\factions\opf_AAF_Wood.sqf"];
	};
	case "Afghan AF _ CUP": {
		call compileScript ["Scripts\factions\opf_AfghanAF_CUP.sqf"];
	};
	case "Afghan Insurgents _ CUP": {
		call compileScript ["Scripts\factions\opf_AfghanIns_CUP.sqf"];
	};
	case "African Insurgents _ POF": {
		call compileScript ["Scripts\factions\opf_AfricaIns_POF.sqf"];
	};
	case "CSAT _ Desert": {
		call compileScript ["Scripts\factions\opf_CSATDesert.sqf"];
	};
	case "CSAT _ Woodland": {
		call compileScript ["Scripts\factions\opf_CSATWood.sqf"];
	};
	case "East Europe Insurgents _ Desert _ AEW": {
		call compileScript ["Scripts\factions\opf_EastEuropeIns_Desert_AEW.sqf"];
	};
	case "East Europe Insurgents _ Woodland _ AEW": {
		call compileScript ["Scripts\factions\opf_EastEuropeIns_Wood_AEW.sqf"];
	};
	case "ISIS _ POF": {
		call compileScript ["Scripts\factions\opf_ISIS_POF.sqf"];
	};
	case "Iran AF _ POF": {
		call compileScript ["Scripts\factions\opf_IranAF_POF.sqf"];
	};
	case "LDF _ Woodland": {
		call compileScript ["Scripts\factions\opf_LDF_Wood.sqf"];
	};
	case "NVA _ PFSOG": {
		call compileScript ["Scripts\factions\opf_NVA_PFSOG.sqf"];
	};
	case "Russia AF _ Desert _ RHS": {
		call compileScript ["Scripts\factions\opf_RussiaAF_Desert_RHS.sqf"];
	};
	case "Russia AF _ Woodland _ RHS": {
		call compileScript ["Scripts\factions\opf_RussiaAF_Wood_RHS.sqf"];
	};
	case "SFF _ Desert _ Western Sahara": {
		call compileScript ["Scripts\factions\opf_SFF_Desert_WesternSahara.sqf"];
	};
	case "Syndikat _ Woodland": {
		call compileScript ["Scripts\factions\opf_Syndikat_Wood.sqf"];
	};
	case "Syrian AF _ POF": {
		call compileScript ["Scripts\factions\opf_SyrianAF_POF.sqf"];
	};
	case "TTI _ Desert _ Western Sahara": {
		call compileScript ["Scripts\factions\opf_TTI_Desert_WesternSahara.sqf"];
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
	case "Asian Civilians": {
		call compileScript ["Scripts\factions\civ_Asia.sqf"];
	};
	case "East Europe Civilians": {
		call compileScript ["Scripts\factions\civ_EastEurope.sqf"];
	};
	case "East Europe Civilians _ CUP": {
		call compileScript ["Scripts\factions\civ_EastEuropeCUP.sqf"];
	};
	case "Greek Civilians": {
		call compileScript ["Scripts\factions\civ_Greek.sqf"];
	};
	case "Middle East Civilians _ CUP": {
		call compileScript ["Scripts\factions\civ_MiddleEastCUP.sqf"];
	};
	case "Tanoan Civilians": {
		call compileScript ["Scripts\factions\civ_Tanoa.sqf"];
	};
	case "Vietnamese Civilians": {
		call compileScript ["Scripts\factions\civ_Vietnam.sqf"];
	};
	case "Western Sahara Civilians": {
		call compileScript ["Scripts\factions\civ_WesternSahara.sqf"];
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
