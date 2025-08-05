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
// SAVE GAME DETECTION
// ============================================================================

// Optimized save game detection
private _fnc_detectSaveGame = {
    // Check for existing BLUFOR installations (indicates saved game)
    private _bluforMarkers = allMapMarkers select {markerType _x isEqualTo "b_installation"};
    private _installationCount = count _bluforMarkers;

    if (_installationCount > 0) then {
        ["INIT_CLIENT", 3, format ["Detected %1 existing installations - loading from save", _installationCount]] call FLO_fnc_log;
        StartingLocationDone = true;
        publicVariable "StartingLocationDone";
        true
    } else {
        ["INIT_CLIENT", 3, "No existing installations found - fresh mission start"] call FLO_fnc_log;
        false
    }
};

private _isSavedGame = call _fnc_detectSaveGame;

// ============================================================================
// FRESH START INITIALIZATION
// ============================================================================

if (!StartingLocationDone) then {
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

    // Launch faction selection for commander
    if (_player isEqualTo TheCommander) then {
        ["INIT_CLIENT", 3, "Launching faction selection dialog for commander"] call FLO_fnc_log;
        execVM "Scripts\MissionSetupMenu\Dialog_Faction.sqf";
    } else {
        ["INIT_CLIENT", 3, format ["Player %1 waiting for commander faction selection", name _player]] call FLO_fnc_log;
    };
};

// ============================================================================
// FACTION INITIALIZATION
// ============================================================================

// Wait for starting location configuration
waitUntil {sleep 0.1; StartingLocationDone};

// Update loading status
hintSilent "LOADING . . . ";

// Initialize faction system
F_Init = false;
execVM "Scripts\Init\init_groups.sqf";

// Disable saving during initialization
enableSaving [false, false];

// Wait for faction initialization
waitUntil {sleep 0.1; F_Init};

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
// MISSION READINESS WAIT
// ============================================================================

// Wait for mission systems to be ready
private _fnc_waitForMissionReady = {
    private _startTime = time;
    private _timeout = 300; // 5 minute timeout

    waitUntil {
        sleep 0.5;

        // Check multiple conditions for mission readiness
        private _markerReady = (MarLOCC isEqualTo 1);
        private _installationsExist = (count (allMapMarkers select {markerType _x isEqualTo "b_installation"}) > 0);
        private _respawnExists = (count (allMapMarkers select {markerType _x isEqualTo "b_unknown"}) > 0);
        private _timeoutReached = (time - _startTime > _timeout);

        if (_timeoutReached) then {
            ["INIT_CLIENT", 1, "Mission readiness timeout reached"] call FLO_fnc_log;
        };

        _markerReady || _installationsExist || _respawnExists || _timeoutReached
    };

    ["INIT_CLIENT", 3, "Mission readiness confirmed"] call FLO_fnc_log;
};

call _fnc_waitForMissionReady;

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

    } catch {
        ["INIT_CLIENT", 1, format ["Error in final initialization: %1", _exception]] call FLO_fnc_log;
        hintSilent "LOADED WITH ERRORS!";
    };
};

call _fnc_finalizeInit;