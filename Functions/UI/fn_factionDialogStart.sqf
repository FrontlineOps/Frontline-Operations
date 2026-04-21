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
 * FLO_IDC_FACTION_COMBO_WEST_ATTACK_COVERAGE = 1958
 * FLO_IDC_FACTION_COMBO_RESOURCES  = 1959
 * FLO_IDC_FACTION_COMBO_REPUTATION = 1960
 * FLO_IDC_FACTION_COMBO_WEST_AGGRESSION = 1961
 * FLO_IDC_FACTION_COMBO_WEST_DEFENSE_COVERAGE = 1962
 * FLO_IDC_FACTION_COMBO_WEST_TEMPO = 1963
 * FLO_IDC_FACTION_COMBO_OBJ_SIZE = 1964
 * FLO_IDC_FACTION_COMBO_VIRT_DIST = 1965
 * FLO_IDC_FACTION_COMBO_WEST_FORCE_GROWTH = 1966
 * FLO_IDC_FACTION_COMBO_WEST_GARRISON = 1967
 * FLO_IDC_FACTION_COMBO_VIRT_UNIT_CAP = 1968
 * FLO_IDC_FACTION_COMBO_TERRITORY_RATIO = 1969
 * FLO_IDC_FACTION_COMBO_EAST_ATTACK_COVERAGE = 1970
 * FLO_IDC_FACTION_COMBO_EAST_DEFENSE_COVERAGE = 1971
 * FLO_IDC_FACTION_COMBO_EAST_AGGRESSION = 1972
 * FLO_IDC_FACTION_COMBO_EAST_TEMPO = 1973
 * FLO_IDC_FACTION_COMBO_EAST_FORCE_GROWTH = 1974
 * FLO_IDC_FACTION_COMBO_EAST_GARRISON = 1975
 * FLO_IDC_FACTION_EDIT_*_COMPOSITION = 2050-2093
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
    private _idx = lbCurSel _ctrl;
	[_ctrl lbText _idx, _ctrl lbData _idx]
};

// Get all selections using numeric IDCs
private _playerFactionSelection = [1955] call _fnc_getSelection;
private _enemyFactionSelection = [1956] call _fnc_getSelection;
private _civilianFactionSelection = [1957] call _fnc_getSelection;
private _playerFaction = _playerFactionSelection select 0;
private _enemyFaction = _enemyFactionSelection select 0;
private _civilianFaction = _civilianFactionSelection select 0;
private _playerFactionData = _playerFactionSelection select 1;
private _enemyFactionData = _enemyFactionSelection select 1;
private _civilianFactionData = _civilianFactionSelection select 1;
private _westAttackCoverage = ([1958] call _fnc_getSelection) select 0;
private _resources = ([1959] call _fnc_getSelection) select 0;
private _reputation = ([1960] call _fnc_getSelection) select 0;
private _westDifficulty = ([1961] call _fnc_getSelection) select 0;
private _westDefenseCoverage = ([1962] call _fnc_getSelection) select 0;
private _westTempo = ([1963] call _fnc_getSelection) select 0;
private _objectiveSize = ([1964] call _fnc_getSelection) select 0;
private _virtualizationDistance = ([1965] call _fnc_getSelection) select 0;
private _westForceGrowth = ([1966] call _fnc_getSelection) select 0;
private _westGarrison = ([1967] call _fnc_getSelection) select 0;
private _virtualizationUnitCap = ([1968] call _fnc_getSelection) select 0;
private _territoryRatio = ([1969] call _fnc_getSelection) select 0;
private _eastAttackCoverage = ([1970] call _fnc_getSelection) select 0;
private _eastDefenseCoverage = ([1971] call _fnc_getSelection) select 0;
private _eastDifficulty = ([1972] call _fnc_getSelection) select 0;
private _eastTempo = ([1973] call _fnc_getSelection) select 0;
private _eastForceGrowth = ([1974] call _fnc_getSelection) select 0;
private _eastGarrison = ([1975] call _fnc_getSelection) select 0;

// Validate selections
if (_playerFaction isEqualTo "" ||
    _enemyFaction isEqualTo "" ||
    _civilianFaction isEqualTo "" ||
    _westAttackCoverage isEqualTo "" ||
    _resources isEqualTo "" ||
    _reputation isEqualTo "" ||
    _westDifficulty isEqualTo "" ||
    _westDefenseCoverage isEqualTo "" ||
    _westTempo isEqualTo "" ||
    _objectiveSize isEqualTo "" ||
    _virtualizationDistance isEqualTo "" ||
    _westForceGrowth isEqualTo "" ||
    _westGarrison isEqualTo "" ||
    _virtualizationUnitCap isEqualTo "" ||
    _eastAttackCoverage isEqualTo "" ||
    _eastDefenseCoverage isEqualTo "" ||
    _eastDifficulty isEqualTo "" ||
    _eastTempo isEqualTo "" ||
    _eastForceGrowth isEqualTo "" ||
    _eastGarrison isEqualTo "" ||
    _territoryRatio isEqualTo "") exitWith {
	
	["UI", 2, "Faction dialog validation failed - empty selections"] call FLO_fnc_log;
	hint "Please select all options before starting the mission.";
	_startBtn ctrlEnable true;
};

private _westFactionTuningSpecs = ["BLUFOR"] call FLO_fnc_factionGetTuningFieldSpecs;
private _eastFactionTuningSpecs = ["OPFOR"] call FLO_fnc_factionGetTuningFieldSpecs;

private _westFactionTuningParse = [_display, "BLUFOR", _westFactionTuningSpecs] call FLO_fnc_factionBuildTuningHandle;
private _eastFactionTuningParse = [_display, "OPFOR", _eastFactionTuningSpecs] call FLO_fnc_factionBuildTuningHandle;

if (!(_westFactionTuningParse get "valid") || {!(_eastFactionTuningParse get "valid")}) exitWith {
    private _errors = (_westFactionTuningParse get "errors") + (_eastFactionTuningParse get "errors");
    ["UI", 2, format ["Force composition validation failed: %1", _errors]] call FLO_fnc_log;
    hint format ["Force composition is invalid:\n%1", _errors joinString "\n"];
    _startBtn ctrlEnable true;
};

private _westFactionTuningHandle = _westFactionTuningParse get "overrides";
private _eastFactionTuningHandle = _eastFactionTuningParse get "overrides";

// Close dialog
_display closeDisplay 1;

// Log selections
["UI", 3, format["Mission starting with: Player=%1, Enemy=%2, Civilian=%3",
	_playerFaction, _enemyFaction, _civilianFaction]] call FLO_fnc_log;

// Execute mission setup
[
    _playerFaction,
    _enemyFaction,
    _civilianFaction,
    _westAttackCoverage,
    _resources,
    _reputation,
    _westDifficulty,
    _westDefenseCoverage,
    _westTempo,
    _objectiveSize,
    _virtualizationDistance,
    _westForceGrowth,
    _westGarrison,
    _virtualizationUnitCap,
    _territoryRatio,
    _eastAttackCoverage,
    _eastDefenseCoverage,
    _eastDifficulty,
    _eastTempo,
    _eastForceGrowth,
    _eastGarrison,
    _playerFactionData,
    _enemyFactionData,
    _civilianFactionData,
    _westFactionTuningHandle,
    _eastFactionTuningHandle
] spawn {
	params [
        "_playerFaction",
        "_enemyFaction",
        "_civilianFaction",
        "_westAttackCoverage",
        "_resources",
        "_reputation",
        "_westDifficulty",
        "_westDefenseCoverage",
        "_westTempo",
        "_objectiveSize",
        "_virtualizationDistance",
        "_westForceGrowth",
        "_westGarrison",
        "_virtualizationUnitCap",
        "_territoryRatio",
        "_eastAttackCoverage",
        "_eastDefenseCoverage",
        "_eastDifficulty",
        "_eastTempo",
        "_eastForceGrowth",
        "_eastGarrison",
        "_playerFactionData",
        "_enemyFactionData",
        "_civilianFactionData",
        "_westFactionTuningHandle",
        "_eastFactionTuningHandle"
    ];

    private _fnc_buildFactionHandle = {
        params ["_selection", "_data"];

        private _handle = createHashMapFromArray [
            ["name", _selection],
            ["source", "preset"]
        ];

        if ((_data find "auto|") == 0) then {
            _handle set ["source", "auto"];
            _handle set ["factionClass", _data select [5]];
        };

        _handle
    };

    private _fnc_buildScalarHandle = {
        params ["_selection", "_map"];
        createHashMapFromArray [
            ["value", _map get _selection],
            ["name", _selection]
        ]
    };

    private _fnc_buildGarrisonHandle = {
        params ["_selection"];

        switch (_selection) do {
            case "Light _ 1 Rear / 2 Front": {
                createHashMapFromArray [
                    ["name", _selection],
                    ["rearBaseGroups", 1],
                    ["frontlineBaseGroups", 2],
                    ["priorityBonusGroups", 0],
                    ["hotBonusGroups", 1]
                ]
            };
            case "Standard _ 1 Rear / 3 Front": {
                createHashMapFromArray [
                    ["name", _selection],
                    ["rearBaseGroups", 1],
                    ["frontlineBaseGroups", 3],
                    ["priorityBonusGroups", 0],
                    ["hotBonusGroups", 1]
                ]
            };
            case "Heavy _ 2 Rear / 3 Front": {
                createHashMapFromArray [
                    ["name", _selection],
                    ["rearBaseGroups", 2],
                    ["frontlineBaseGroups", 3],
                    ["priorityBonusGroups", 0],
                    ["hotBonusGroups", 1]
                ]
            };
            case "Fortified _ 2 Rear / 4 Front": {
                createHashMapFromArray [
                    ["name", _selection],
                    ["rearBaseGroups", 2],
                    ["frontlineBaseGroups", 4],
                    ["priorityBonusGroups", 0],
                    ["hotBonusGroups", 2]
                ]
            };
        };
    };

	// Set mission start time for grace period tracking
	missionNamespace setVariable ["FLO_missionStartTime", diag_tickTime, true];

	hint "Setting up mission...";

	// Process reputation
	private _reputationValue = switch (_reputation) do {
		case "Hostile _ Civilians Distrust Players": {2};
		case "Neutral _ Civilians Tolerate Players": {9};
		case "Friendly _ Civilians Support Players": {16};
		default {9};
	};

	// Process resources
	private _resourceValue = parseNumber _resources;

    private _difficultyMap = createHashMapFromArray [
        ["LOW _ Cautious Commander", 0.5],
        ["MEDIUM _ Balanced Commander", 1],
        ["HIGH _ Aggressive Commander", 1.5]
    ];

    private _coverageMap = createHashMapFromArray [
        ["Minimal Coverage", 0.5],
        ["Balanced Coverage", 0.75],
        ["Layered Coverage", 1],
        ["Maximum Coverage", 1.25]
    ];

    private _tempoMap = createHashMapFromArray [
        ["10s", 10],
        ["14s", 14],
        ["20s", 20],
        ["28s", 28]
    ];

    private _forceGrowthMap = createHashMapFromArray [
        ["None _ 0 Groups Per Capture", 0],
        ["Low _ 1 Group Per Capture", 1],
        ["Standard _ 2 Groups Per Capture", 2],
        ["High _ 3 Groups Per Capture", 3]
    ];

    private _westDifficultyHandle = [_westDifficulty, _difficultyMap] call _fnc_buildScalarHandle;
    private _eastDifficultyHandle = [_eastDifficulty, _difficultyMap] call _fnc_buildScalarHandle;
    private _westAttackCoverageHandle = [_westAttackCoverage, _coverageMap] call _fnc_buildScalarHandle;
    private _eastAttackCoverageHandle = [_eastAttackCoverage, _coverageMap] call _fnc_buildScalarHandle;
    private _westDefenseCoverageHandle = [_westDefenseCoverage, _coverageMap] call _fnc_buildScalarHandle;
    private _eastDefenseCoverageHandle = [_eastDefenseCoverage, _coverageMap] call _fnc_buildScalarHandle;
    private _westTempoHandle = [_westTempo, _tempoMap] call _fnc_buildScalarHandle;
    private _eastTempoHandle = [_eastTempo, _tempoMap] call _fnc_buildScalarHandle;
    private _westForceGrowthHandle = [_westForceGrowth, _forceGrowthMap] call _fnc_buildScalarHandle;
    private _eastForceGrowthHandle = [_eastForceGrowth, _forceGrowthMap] call _fnc_buildScalarHandle;
    private _westGarrisonHandle = [_westGarrison] call _fnc_buildGarrisonHandle;
    private _eastGarrisonHandle = [_eastGarrison] call _fnc_buildGarrisonHandle;

	private _objectiveSizeThreshold = _objectiveSize;
	private _virtualizationDistanceValue = parseNumber _virtualizationDistance;
    private _virtualizationUnitCapValue = parseNumber _virtualizationUnitCap;
    private _territoryRatioWestValue = (parseNumber ((_territoryRatio splitString "%") select 0)) / 100;

	// Legacy compatibility value (not consumed by current systems)
	private _enemyPresence = 2;

	// Fade to black and prompt for starting location
	titleText ["", "BLACK IN", 7, true, true];

	HQLOCC = 0;
	publicVariable "HQLOCC";
	private _startLocationPrompt = "<t size='1.35' color='#ff3b3b' font='PuristaBold'>SELECT STARTING FOB LOCATION</t><br/><t size='0.9' color='#ffffff'>Left-click the map to place your starting FOB and begin the campaign.</t>";
	hint "Select your starting FOB location on the map.";
	[_startLocationPrompt, 0, 0.18, 9999, 0, 0, 9010] spawn BIS_fnc_dynamicText;
	openMap [true, true];

	// Add map click handler for starting location
	private _startPos = getPos player;
	FLO_mapClickDFD = addMissionEventHandler ["MapSingleClick", {
		params ["_control", "_pos", "_alt", "_shift"];

		removeMissionEventHandler ["MapSingleClick", FLO_mapClickDFD];

		player setPos _pos;
		["", 0, 0.18, 0.1, 0, 0, 9010] spawn BIS_fnc_dynamicText;
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
		["friendlyHandle", [_playerFaction, _playerFactionData] call _fnc_buildFactionHandle],
		["enemyHandle", [_enemyFaction, _enemyFactionData] call _fnc_buildFactionHandle],
		["civilianHandle", [_civilianFaction, _civilianFactionData] call _fnc_buildFactionHandle],
		["reputationHandle", createHashMapFromArray [["value", _reputationValue], ["name", _reputation]]],
		["westDifficultyHandle", _westDifficultyHandle],
		["eastDifficultyHandle", _eastDifficultyHandle],
		["westGTNAttackCoverageHandle", _westAttackCoverageHandle],
		["eastGTNAttackCoverageHandle", _eastAttackCoverageHandle],
		["westGTNDefenseCoverageHandle", _westDefenseCoverageHandle],
		["eastGTNDefenseCoverageHandle", _eastDefenseCoverageHandle],
		["westGTNTempoHandle", _westTempoHandle],
		["eastGTNTempoHandle", _eastTempoHandle],
		["westGTNForceGrowthHandle", _westForceGrowthHandle],
		["eastGTNForceGrowthHandle", _eastForceGrowthHandle],
		["westGTNGarrisonHandle", _westGarrisonHandle],
		["eastGTNGarrisonHandle", _eastGarrisonHandle],
		["westFactionTuningHandle", _westFactionTuningHandle],
		["eastFactionTuningHandle", _eastFactionTuningHandle],
		["moneyHandle", createHashMapFromArray [["value", _resourceValue], ["name", _resources]]],
		["enemyPresence", _enemyPresence],
		["objectiveSizeThreshold", _objectiveSizeThreshold],
		["virtualizationDistance", _virtualizationDistanceValue],
        ["virtualizationUnitCap", _virtualizationUnitCapValue],
        ["startingTerritoryWestRatio", _territoryRatioWestValue],
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
	private _timeout = 600; // 10 minute timeout for full initialization

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
		private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", side player];
		private _respawnKey = if (_activeSide isEqualTo east) then { "east" } else { "west" };
		private _respawnMarker = createMarkerLocal [format ["respawn_%1", _respawnKey], _startPos];
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

