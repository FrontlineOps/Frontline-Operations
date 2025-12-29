/*
 * FLO Player Local Initialization Script
 * Author: Frontline Operations Development Group
 * Description: Client-side initialization
 */

params ["_player", "_didJIP"];

// Only execute on clients with interface
if (!hasInterface) exitWith {};

// ============================================================================
// INITIAL SETUP AND LOADING SCREEN
// ============================================================================

// Initialize loading screen with fade effect
titleText ["Frontline Operations Group Presents...", "BLACK IN", 9999];
5 fadeSound 0;

sleep 1;

// Initialize mission state
StartingLocationDone = false;

// ============================================================================
// MISSION LOADING SEQUENCE
// ============================================================================

// Wait for mission to be fully loaded with timeout protection
private _loadTimeout = time + 300; // 5 minute timeout
waitUntil {
    sleep 0.1;
    !isNil "MissionLoadedLitterally" && {MissionLoadedLitterally} || {time > _loadTimeout}
};

if (time > _loadTimeout) then {
    ["INIT_CLIENT", 1, "Mission loading timeout reached"] call FLO_fnc_log;
};

// ============================================================================
// SAVE GAME DETECTION - Wait for server's Phase 0 detection
// ============================================================================

// Wait for server to complete Phase 0 (save detection) with timeout
private _fnc_waitForSaveDetection = {
    private _startTime = diag_tickTime;
    private _timeout = 30; // 30 second timeout for save detection

    ["INIT_CLIENT", 3, "Waiting for server save detection..."] call FLO_fnc_log;

    // Wait for the server to broadcast FLO_IsLoadedSave (happens in Phase 0)
    // The variable is always set (to true or false) before Phase 1 starts
    waitUntil {
        sleep 0.3;
        // FLO_IsLoadedSave is always set (true/false) before Phase 1
        // We also check FLO_InitPhase to know server has started
        private _serverStarted = !isNil "FLO_InitPhase";
        private _saveStatusKnown = !isNil "FLO_IsLoadedSave";
        private _timedOut = (diag_tickTime - _startTime) > _timeout;

        // Wait until we know the save status, or we're past phase 0
        (_serverStarted && _saveStatusKnown) ||
        (_serverStarted && {FLO_InitPhase >= 1}) ||
        _timedOut
    };

    // Small delay to ensure network sync
    sleep 0.5;

    // Check if this is a saved game from server's detection
    private _isSavedGame = !isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave};

    if (_isSavedGame) then {
        ["INIT_CLIENT", 3, "Server detected saved game - skipping faction dialog"] call FLO_fnc_log;
        StartingLocationDone = true;
    } else {
        ["INIT_CLIENT", 3, "Server detected fresh start"] call FLO_fnc_log;
    };

    _isSavedGame
};

private _isSavedGame = call _fnc_waitForSaveDetection;

// ============================================================================
// FRESH START INITIALIZATION
// ============================================================================

if (!_isSavedGame && !StartingLocationDone) then {
    // Commander validation
    private _fnc_validateCommander = {
        if (isNil "TheCommander") then {
            private _message = "Commander must be assigned to a player at fresh start.\nHave someone return to Lobby and pick Commander.";
            titleText [_message, "BLACK IN", 9999];

            // Wait for commander assignment with periodic updates
            private _startTime = time;
            waitUntil {
                sleep 1;
                if (time - _startTime > 30) then {
                    _startTime = time;
                    ["INIT_CLIENT", 2, "Still waiting for commander assignment..."] call FLO_fnc_log;
                };
                !isNil "TheCommander"
            };

            ["INIT_CLIENT", 3, format ["Commander assigned: %1", name TheCommander]] call FLO_fnc_log;
        };
    };

    call _fnc_validateCommander;

    // Check if this is a loaded save - if so, skip the faction dialog
    // Wait briefly for server to set FLO_IsLoadedSave
    private _saveCheckStart = diag_tickTime;
    waitUntil { sleep 0.2; !isNil "FLO_IsLoadedSave" || (diag_tickTime - _saveCheckStart > 5) };

    private _isLoadedSave = !isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave};

    if (_isLoadedSave) then {
        ["INIT_CLIENT", 3, "Loading from saved game - skipping faction selection dialog"] call FLO_fnc_log;
    } else {
        // Launch faction selection for commander (fresh start only)
        if (_player isEqualTo TheCommander) then {
            ["INIT_CLIENT", 3, "Launching faction selection dialog for commander"] call FLO_fnc_log;
            execVM "Scripts\MissionSetupMenu\Dialog_Faction.sqf";
        } else {
            ["INIT_CLIENT", 3, format ["Player %1 waiting for commander faction selection", name _player]] call FLO_fnc_log;
        };
    };
};

// ============================================================================
// WAIT FOR SERVER PHASE MANAGER
// ============================================================================

// Disable saving during initialization
enableSaving [false, false];

// Wait for server Phase Manager to complete all initialization
// This replaces the old fragmented approach (init_groups, init_Markers, etc.)
private _fnc_waitForPhaseManager = {
    private _startTime = diag_tickTime;
    private _timeout = 300; // 5 minute timeout

    waitUntil {
        sleep 1;

        // Show progress to player based on current phase
        if (!isNil "FLO_InitPhase") then {
            private _phaseName = switch (FLO_InitPhase) do {
                case 0: { "Waiting for configuration..." };
                case 1: { "Loading factions..." };
                case 2: { "Configuring factions..." };
                case 3: { "Indexing objectives..." };
                case 4: { "Setting up OPFOR forces..." };
                case 5: { "Starting mission systems..." };
                case 99: { "Ready!" };
                case -1: { "ERROR" };
                default { "Initializing..." };
            };
            hintSilent format ["Mission Setup: %1", _phaseName];
        } else {
            hintSilent "Waiting for server...";
        };

        // Check for completion or error
        private _ready = !isNil "FLO_MissionReady" && {FLO_MissionReady};
        private _error = !isNil "FLO_InitPhase" && {FLO_InitPhase == -1};
        private _timedOut = (diag_tickTime - _startTime) > _timeout;

        _ready || _error || _timedOut
    };

    // Handle result
    if (!isNil "FLO_MissionReady" && {FLO_MissionReady}) then {
        ["INIT_CLIENT", 3, "Phase Manager completed - mission ready"] call FLO_fnc_log;
        true
    } else {
        if (!isNil "FLO_InitPhase" && {FLO_InitPhase == -1}) then {
            private _error = if (!isNil "FLO_InitError") then { FLO_InitError } else { "Unknown error" };
            ["INIT_CLIENT", 1, format ["Phase Manager failed: %1", _error]] call FLO_fnc_log;
        } else {
            ["INIT_CLIENT", 1, "Phase Manager timeout"] call FLO_fnc_log;
        };
        false
    }
};

private _phaseSuccess = call _fnc_waitForPhaseManager;

// ============================================================================
// USER INTERFACE SETUP
// ============================================================================

// Mrker interaction system
private _fnc_initMarkerInteraction = {
    // Wait for main display to be available using spawn
    [] spawn {
        waitUntil {sleep 0.1; !isNull findDisplay 46};

        private _mouseHandler = (findDisplay 46) displayAddEventHandler ["MouseButtonDown", {
            params ["_displayOrControl", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

            // Check for Ctrl+Right-click on map markers
            if (_ctrl && {_button isEqualTo 1}) then {
                try {
                    private _mapDisplay = findDisplay 12;
                    if (!isNull _mapDisplay) then {
                        private _mapCtrl = _mapDisplay displayCtrl 51;
                        private _mouseOver = ctrlMapMouseOver _mapCtrl;

                        if ((_mouseOver select 0) isEqualTo "marker") then {
                            private _markerName = _mouseOver select 1;
                            [_markerName] execVM "Scripts\MarkerIntro.sqf";
                        };
                    };
                } catch {
                    ["UI", 1, format ["Error in marker interaction: %1", _exception]] call FLO_fnc_log;
                };
            };

            false
        }];

        ["UI", 3, "Marker interaction system initialized"] call FLO_fnc_log;
    };
};

call _fnc_initMarkerInteraction;

// ============================================================================
// OPTIONAL EQUIPMENT SETUP
// ============================================================================

// cTab integration (if available)
private _fnc_initCTab = {
    if (isClass (configFile >> "CfgVehicles" >> "Box_cTab_items")) then {
        try {
            player addItem "ItemAndroid";
            player addItem "ItemcTab";
            ["EQUIPMENT", 3, "cTab equipment added to player"] call FLO_fnc_log;
        } catch {
            ["EQUIPMENT", 1, format ["Failed to add cTab equipment: %1", _exception]] call FLO_fnc_log;
        };
    } else {
        ["EQUIPMENT", 5, "cTab not available - skipping equipment"] call FLO_fnc_log;
    };
};

call _fnc_initCTab;

// ============================================================================
// MISSION READINESS CHECK
// ============================================================================

// Note: We already waited for Phase Manager above, but do a final sanity check
if (!_phaseSuccess) then {
    ["INIT_CLIENT", 1, "Mission initialization failed - some features may not work correctly"] call FLO_fnc_log;
    hint "Warning: Mission initialization encountered errors.\nSome features may not work correctly.";
} else {
    ["INIT_CLIENT", 3, "Mission readiness confirmed"] call FLO_fnc_log;
};

// ============================================================================
// CLIENT FEATURE INITIALIZATION
// ============================================================================

// Initialize client features based on mission parameters
private _fnc_initClientFeatures = {
    private _features = [
        ["RestrictedArsenal", "FLO_fnc_restrictedArsenal", "Restricted Arsenal"],
        ["RagequitBlocker", "FLO_fnc_ragequitBlocker", "Ragequit Blocker"],
        ["DisableSystemChat", "FLO_fnc_disableSystemChat", "System Chat Disabler"]
    ];

    {
        _x params ["_paramName", "_functionName", "_displayName"];

        try {
            private _paramValue = _paramName call BIS_fnc_getParamValue;
            if (_paramValue isEqualTo 0) then {
                [] call (missionNamespace getVariable [_functionName, {}]);
                ["CLIENT_FEATURES", 3, format ["%1 initialized", _displayName]] call FLO_fnc_log;
            } else {
                ["CLIENT_FEATURES", 5, format ["%1 disabled by mission parameter", _displayName]] call FLO_fnc_log;
            };
        } catch {
            ["CLIENT_FEATURES", 1, format ["Failed to initialize %1: %2", _displayName, _exception]] call FLO_fnc_log;
        };

        sleep 0.1; // Small delay between feature initializations
    } forEach _features;
};

call _fnc_initClientFeatures;

// ============================================================================
// FINAL CLIENT INITIALIZATION
// ============================================================================

// Execute final client initialization scripts
private _fnc_finalizeInit = {
    try {
        ["INIT_CLIENT", 3, "Starting final client initialization"] call FLO_fnc_log;

        // Execute triggers initialization
        Triggers0 = execVM "Scripts\Init\init_Triggers.sqf";
        waitUntil {sleep 0.5; scriptDone Triggers0};

        ["INIT_CLIENT", 3, "Client initialization completed successfully"] call FLO_fnc_log;

        // Final loading message
        hintSilent "LOADED!";

        // Brief delay before clearing hint using spawn
        [] spawn {
            sleep 3;
            hintSilent "";
        };

        // Initialize Notifications Module
        [] call IDS_Notifications_fnc_initNotificationClass;
        [] spawn {
            waitUntil { !isNil "IDS_NotificationClass" };
            IDS_NotificationClass call ["init", []];
        };

        // Initialize Capture Balance UI (updates pushed from server)
        ["init"] call FLO_fnc_captureUI;
        ["INIT_CLIENT", 3, "Capture UI initialized"] call FLO_fnc_log;

    } catch {
        ["INIT_CLIENT", 1, format ["Error in final initialization: %1", _exception]] call FLO_fnc_log;
        hintSilent "LOADED WITH ERRORS!";
    };
};

call _fnc_finalizeInit;