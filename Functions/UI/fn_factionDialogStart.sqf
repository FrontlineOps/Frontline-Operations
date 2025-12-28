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

// Execute mission setup
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

	// Process difficulty
	private _difficultyValue = switch (_difficulty) do {
		case "EASY _ Low Enemy Presence _ progressive": {0.5};
		case "NORMAL _ Half Enemy Presence _ progressive": {1};
		case "HARD _ Full Enemy Presence _ progressive": {1.5};
		default {1};
	};

	// Process resources
	private _resourceValue = parseNumber _resources;

	// Process enemy presence
	private _enemyPresence = switch (_presence) do {
		case "10% _ Small Operation": {7};
		case "30% _ Short Campaign": {3};
		case "50% _ Medium Campaign": {2};
		case "75% _ Long Campaign": {1.5};
		case "100% _ Dedi Servers with HCs": {1};
		default {2};
	};

	// Fade to black and prompt for starting location
	titleText ["", "BLACK IN", 7, true, true];

	HQLOCC = 0;
	publicVariable "HQLOCC";
	hint "Choose Your Starting Point";
	openMap [true, true];

	// Add map click handler for starting location
	private _startPos = getPos player;
	FLO_mapClickDFD = addMissionEventHandler ["MapSingleClick", {
		params ["_control", "_pos", "_alt", "_shift"];

		removeMissionEventHandler ["MapSingleClick", FLO_mapClickDFD];

		player setPos _pos;
		hintSilent "LOADING...";
		HQLOCC = 1;
		publicVariable "HQLOCC";

		// Store the selected position
		missionNamespace setVariable ["FLO_StartPosition", _pos, true];

		titleText ["", "BLACK IN", 999, true, true];
	}];

	waitUntil {HQLOCC == 1};
	openMap [true, false];
	openMap [false, false];

	// Get final start position
	_startPos = missionNamespace getVariable ["FLO_StartPosition", getPos player];

	// Create FOB container
	private _fobContainer = createVehicle ["B_Slingload_01_Cargo_F", (player getPos [random 10, random 360]), [], 0, "NONE"];
	_fobContainer allowDamage false;

	// ============================================================================
	// SEND CONFIG TO SERVER VIA FLO_MissionConfig
	// The Phase Manager (FLO_fnc_initPhase1_MissionConfig) is waiting for this
	// ============================================================================

	FLO_MissionConfig = createHashMapFromArray [
		["friendlyHandle", createHashMapFromArray [["name", _playerFaction]]],
		["enemyHandle", createHashMapFromArray [["name", _enemyFaction]]],
		["civilianHandle", createHashMapFromArray [["name", _civilianFaction]]],
		["reputationHandle", createHashMapFromArray [["value", _reputationValue], ["name", _reputation]]],
		["difficultyHandle", createHashMapFromArray [["value", _difficultyValue], ["name", _difficulty]]],
		["moneyHandle", createHashMapFromArray [["value", _resourceValue], ["name", _resources]]],
		["enemyPresence", _enemyPresence],
		["startPosition", _startPos]
	];
	publicVariable "FLO_MissionConfig";

	["UI", 3, "Mission config sent to server - Phase Manager will handle initialization"] call FLO_fnc_log;

	// ============================================================================
	// WAIT FOR SERVER PHASE MANAGER TO COMPLETE
	// No more local init_groups, init_Markers - server handles everything
	// ============================================================================

	hint "Initializing mission systems...";

	private _startTime = diag_tickTime;
	private _timeout = 300; // 5 minute timeout for full initialization

	waitUntil {
		uiSleep 1;

		// Show progress to player
		if (!isNil "FLO_InitPhase") then {
			private _phaseName = switch (FLO_InitPhase) do {
				case 1: { "Loading factions..." };
				case 2: { "Configuring factions..." };
				case 3: { "Indexing objectives..." };
				case 4: { "Setting up OPFOR forces..." };
				case 5: { "Starting mission systems..." };
				case 99: { "Complete!" };
				case -1: { "ERROR - Check server log" };
				default { "Initializing..." };
			};
			hintSilent format ["Mission Setup: %1\nPhase %2", _phaseName, FLO_InitPhase];
		};

		(!isNil "FLO_MissionReady" && {FLO_MissionReady}) ||
		(!isNil "FLO_InitPhase" && {FLO_InitPhase == -1}) ||
		{diag_tickTime - _startTime > _timeout}
	};

	// Check result
	if (!isNil "FLO_MissionReady" && {FLO_MissionReady}) then {
		["UI", 3, "Mission initialization complete - ready to play"] call FLO_fnc_log;

		// Create local respawn marker
		private _respawnMarker = createMarkerLocal ["respawn_west", _startPos];
		_respawnMarker setMarkerTypeLocal "hd_start";
		_respawnMarker setMarkerTextLocal "Respawn";

		// Set MarLOCC for backwards compatibility
		MarLOCC = 1;

		// Final notification
		titleText ["", "BLACK IN", 3, true, true];
		private _msg = "<t size='1.2' color='#00ff00'>Mission Ready</t><br/><t size='0.9'>Good luck, Commander</t>";
		[_msg, 0, 0.3, 4, 0] spawn BIS_fnc_dynamicText;

	} else {
		private _errorMsg = if (!isNil "FLO_InitError") then { FLO_InitError } else { "Unknown error" };
		["UI", 1, format["Mission initialization FAILED: %1", _errorMsg]] call FLO_fnc_log;
		hint format ["Mission initialization failed:\n%1\n\nCheck server RPT for details.", _errorMsg];
	};

	["UI", 3, "Faction dialog setup complete"] call FLO_fnc_log;
};

