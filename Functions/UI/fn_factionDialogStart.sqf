/*
 * Function: FLO_fnc_factionDialogStart
 * Author: Frontline Operations
 *
 * Description:
 * Handles the START MISSION button click in the Faction Selection Dialog.
 * Validates selections, closes dialog, and initiates mission setup.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call FLO_fnc_factionDialogStart;
 *
 * IDC Reference (from UI/constants.hpp):
 * FLO_IDC_FACTION_COMBO_PLAYER     = 1955
 * FLO_IDC_FACTION_COMBO_ENEMY      = 1956
 * FLO_IDC_FACTION_COMBO_CIVILIAN   = 1957
 * FLO_IDC_FACTION_COMBO_PRESENCE   = 1958
 * FLO_IDC_FACTION_COMBO_RESOURCES  = 1959
 * FLO_IDC_FACTION_COMBO_REPUTATION = 1960
 * FLO_IDC_FACTION_COMBO_DIFFICULTY = 1961
 * FLO_IDC_FACTION_BTN_START        = 1600
 */

disableSerialization;

private _display = uiNamespace getVariable ["FLO_FactionDialog", displayNull];
if (isNull _display) exitWith {
	["UI", 1, "Cannot start mission - faction dialog is null"] call FLO_fnc_log;
};

// Disable start button to prevent double-clicks (IDC 1600)
private _startBtn = _display displayCtrl 1600;
_startBtn ctrlEnable false;

// Helper function to get combo selection
private _fnc_getSelection = {
	params ["_idc"];
	private _ctrl = _display displayCtrl _idc;
	_ctrl lbText (lbCurSel _ctrl)
};

// Get all selections using numeric IDCs
private _playerFaction = [1955] call _fnc_getSelection;
private _enemyFaction = [1956] call _fnc_getSelection;
private _civilianFaction = [1957] call _fnc_getSelection;
private _presence = [1958] call _fnc_getSelection;
private _resources = [1959] call _fnc_getSelection;
private _reputation = [1960] call _fnc_getSelection;
private _difficulty = [1961] call _fnc_getSelection;

// Validate selections
if (_playerFaction isEqualTo "" || 
    _enemyFaction isEqualTo "" || 
    _civilianFaction isEqualTo "" || 
    _presence isEqualTo "" || 
    _resources isEqualTo "" || 
    _reputation isEqualTo "" || 
    _difficulty isEqualTo "") exitWith {
	
	["UI", 2, "Faction dialog validation failed - empty selections"] call FLO_fnc_log;
	hint "Please select all options before starting the mission.";
	_startBtn ctrlEnable true;
};

// Close dialog
_display closeDisplay 1;

// Log selections
["UI", 3, format["Mission starting with: Player=%1, Enemy=%2, Civilian=%3", 
	_playerFaction, _enemyFaction, _civilianFaction]] call FLO_fnc_log;

// Execute mission setup (spawn to allow async operations)
[_playerFaction, _enemyFaction, _civilianFaction, _presence, _resources, _reputation, _difficulty] spawn {
	params ["_playerFaction", "_enemyFaction", "_civilianFaction", "_presence", "_resources", "_reputation", "_difficulty"];
	
	// Set mission start time for grace period tracking
	missionNamespace setVariable ["FLO_missionStartTime", diag_tickTime, true];
	
	hint "Setting up mission...";
	
	// Process reputation
	private _reputationValue = switch (_reputation) do {
		case "LOW_Enemy to Guerillas": {2};
		case "MEDIUM_Neutral to Guerillas": {9};
		case "HIGH_Friendly to Guerillas": {16};
		default {9};
	};
	
	FLO_ReputationHandle = createHashMapFromArray [
		["value", _reputationValue],
		["name", _reputation]
	];
	publicVariable "FLO_ReputationHandle";
	
	// Process difficulty
	private _difficultyValue = switch (_difficulty) do {
		case "EASY _ Low Enemy Presence _ progressive": {0.5};
		case "NORMAL _ Half Enemy Presence _ progressive": {1};
		case "HARD _ Full Enemy Presence _ progressive": {1.5};
		default {1};
	};
	
	FLO_DifficultyHandle = createHashMapFromArray [
		["value", _difficultyValue],
		["name", _difficulty]
	];
	publicVariable "FLO_DifficultyHandle";
	
	// Process resources
	private _resourceValue = parseNumber _resources;
	
	FLO_MoneyHandle = createHashMapFromArray [
		["value", _resourceValue],
		["name", _resources]
	];
	publicVariable "FLO_MoneyHandle";
	
	// Set faction handles
	FLO_FriendlyHandle = createHashMapFromArray [["name", _playerFaction]];
	publicVariable "FLO_FriendlyHandle";
	
	FLO_EnemyHandle = createHashMapFromArray [["name", _enemyFaction]];
	publicVariable "FLO_EnemyHandle";
	
	FLO_CivilianHandle = createHashMapFromArray [["name", _civilianFaction]];
	publicVariable "FLO_CivilianHandle";
	
	// Fade to black and prompt for starting location
	titleText ["", "BLACK IN", 7, true, true];
	
	HQLOCC = 0;
	publicVariable "HQLOCC";
	hint "Choose Your Starting Point";
	openMap [true, true];
	
	// Add map click handler for starting location
	FLO_mapClickDFD = addMissionEventHandler ["MapSingleClick", {
		params ["_control", "_pos", "_alt", "_shift"];

		removeMissionEventHandler ["MapSingleClick", FLO_mapClickDFD];

		player setPos _pos;
		hintSilent "LOADING...";
		HQLOCC = 1;
		publicVariable "HQLOCC";

		titleText ["", "BLACK IN", 999, true, true];
	}];
	
	waitUntil {HQLOCC == 1};
	openMap [true, false];
	openMap [false, false];
	
	// Create FOB container
	private _fobContainer = createVehicle ["B_Slingload_01_Cargo_F", (player getPos [random 10, random 360]), [], 0, "NONE"];
	_fobContainer allowDamage false;
	
	// Process enemy presence
	EnemyPrec = switch (_presence) do {
		case "10% _ Small Operation": {7};
		case "30% _ Short Campaign": {3};
		case "50% _ Medium Campaign": {2};
		case "75% _ Long Campaign": {1.5};
		case "100% _ Dedi Servers with HCs": {1};
		default {2};
	};
	
	StartingLocationDone = true;
	publicVariable "StartingLocationDone";
	
	// Wait for faction initialization
	waitUntil {!isNil "F_Init" && {F_Init}};
	
	// Initialize markers
	private _markerScript = execVM "Scripts\Init\init_Markers.sqf";
	waitUntil {!isNil "_markerScript" && {scriptDone _markerScript}};
	
	["VIRTUALIZATION", 3, "Faction initialization complete, starting virtualization"] call FLO_fnc_log;
	
	// Initialize virtualization system
	[] spawn {
		private _maxAttempts = 10;
		private _attempt = 0;
		while {_attempt < _maxAttempts} do {
			if (isServer) exitWith {
				[OPFOR_Virtualization_Distance] call FLO_fnc_initVirtualization;
			};
			[OPFOR_Virtualization_Distance] remoteExec ["FLO_fnc_initVirtualization", 2];
			uiSleep 0.5;
			_attempt = _attempt + 1;
		};
	};
	
	// Wait for virtualization
	private _startTime = diag_tickTime;
	waitUntil {!isNil "FLO_VirtualizationReady" || {diag_tickTime - _startTime > 10}};
	
	// Initialize objective groups
	[] remoteExec ["FLO_fnc_initializeObjectiveGroups", 2];
	
	["UI", 3, "Mission setup complete"] call FLO_fnc_log;
};

