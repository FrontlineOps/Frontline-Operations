/*
 * FLO Server Initialization Script
 * Author: Frontline Operations Development Group
 * Description: Server initialization using the centralized Phase Manager.
 *              This replaces the old fragmented initialization with a robust,
 *              deterministic sequence that eliminates race conditions.
 *
 * The Phase Manager handles:
 *   Phase 1: Mission Config - Wait for faction dialog, receive config
 *   Phase 2: Factions - Load faction scripts
 *   Phase 3: Objectives - Index all map objectives
 *   Phase 4: Virtualization - Setup virtualization and OPFOR groups
 *   Phase 5: Mission Systems - Start side missions, AI commander, etc.
 */

if (!isServer) exitWith {};

// ============================================================================
// GLOBAL VARIABLE INITIALIZATION
// ============================================================================

// Initialize core mission state variables with proper defaults
private _globalVars = createHashMapFromArray [
    ["HQLOCC", 0],
    ["MarLOCC", 0],
    ["AVENGLOCC", 1],
    ["ConVLocc", 0],
    ["FLO_Objectives_Debug", false],
    ["StartingLocationDone", false],
    ["F_Init", false],
    ["InitializationOG", false],
    ["FLO_MissionReady", false]
];

// Set and publish global variables
{
    missionNamespace setVariable [_x, _y];
    publicVariable _x;
} forEach _globalVars;

// Initialize world center position (fix case sensitivity issue)
Centerposition = [worldSize / 2, worldSize / 2, 0];

// ============================================================================
// EARLY INITIALIZATION (Pre-Phase Manager)
// ============================================================================

// Initialize Heartbeat System
[] spawn FLO_fnc_heartbeat;

// Wait for mission to be fully loaded
// MissionLoadedLitterally is set by init.sqf or CBA
waitUntil {sleep 0.1; !isNil "MissionLoadedLitterally" && {MissionLoadedLitterally}};

diag_log "[FLO_INIT] Mission loaded, starting Phase Manager...";

// ============================================================================
// PHASE MANAGER - CENTRALIZED INITIALIZATION
// ============================================================================

// The phase manager runs ALL initialization in proper sequence:
[] spawn {
    // Give the engine a moment to settle
    sleep 1;

    // Run the centralized phase manager
    private _success = [] call FLO_fnc_initPhaseManager;

    if (_success) then {
        diag_log "[FLO_INIT] Phase Manager completed successfully";
    } else {
        diag_log format ["[FLO_INIT] Phase Manager FAILED: %1", FLO_InitError];
        // Notify players of failure
        [format ["Mission initialization failed: %1", FLO_InitError]] remoteExec ["hint", 0];
    };
};

// ============================================================================
// BACKGROUND SYSTEMS (Run independently - these continue after Phase Manager)
// ============================================================================

// Resource and Objective monitoring system
private _fnc_initResourceLoop = {
    [] spawn {
        private _lastCheck = time;
        private _checkInterval = 60; // Base interval in seconds

        while {true} do {
            sleep _checkInterval;

            // Skip if objectives not initialized yet
            if (isNil "FLO_Objectives") then {continue};

            try {
                // Count BLUFOR objectives
                private _bluforCount = 0;
                private _objectiveKeys = keys FLO_Objectives;

                {
                    private _objData = FLO_Objectives get _x;
                    if (!isNil "_objData" && {(_objData get "owner") isEqualTo west}) then {
                        _bluforCount = _bluforCount + 1;
                    };
                } forEach _objectiveKeys;

                // Add reward based on BLUFOR objectives
                if (_bluforCount > 0) then {
                    [_bluforCount * 2] call FLO_fnc_addReward;
                };

                _lastCheck = time;

            } catch {
                ["RESOURCE_LOOP", 1, format ["Error in resource loop: %1", _exception]] call FLO_fnc_log;
            };
        };
    };
};

// Convoy management system
private _fnc_initConvoyLoop = {
    [] spawn {
        private _checkInterval = 60;
        private _lastPathUpdate = 0;
        private _pathUpdateCooldown = 30; // Minimum seconds between path updates

        while {true} do {
            sleep _checkInterval;

            if (ConVLocc isEqualTo 1) then {
                try {
                    // Clean up old road markers
                    private _roadMarkers = allMapMarkers select {
                        markerType _x isEqualTo "mil_dot" &&
                        markerColor _x isEqualTo "colorCivilian" &&
                        markerAlpha _x isEqualTo 0.3
                    };
                    {deleteMarker _x} forEach _roadMarkers;

                    // Get convoy group
                    private _convoyGroup = missionNamespace getVariable ["CGM", grpNull];

                    // Validate convoy group and units
                    if (!isNull _convoyGroup && {count (units _convoyGroup) > 0}) then {
                        private _leadVehicle = vehicle (leader _convoyGroup);

                        // Only update path if enough time has passed and vehicle is valid
                        if (!isNull _leadVehicle &&
                            {alive _leadVehicle} &&
                            {time - _lastPathUpdate > _pathUpdateCooldown}) then {

                            // Clear existing waypoints safely
                            while {count (waypoints _convoyGroup) > 0} do {
                                deleteWaypoint [_convoyGroup, 0];
                            };

                            // Calculate path
                            private _destMarker = getMarkerPos "ConvoyDest";
                            private _nearRoads = _destMarker nearRoads 500;

                            if (count _nearRoads > 0) then {
                                private _targetPos = position (selectRandom _nearRoads);

                                (calculatePath ["wheeled_APC", "safe", position _leadVehicle, _targetPos])
                                addEventHandler ["PathCalculated", {
                                    params ["_path", "_positions"];
                                    private _group = missionNamespace getVariable ["CGM", grpNull];

                                    if (!isNull _group && {count _positions > 0}) then {
                                        private _posCount = count _positions;
                                        private _stepSize = (_posCount / 9) max 1;

                                        // Create waypoints at regular intervals
                                        for "_i" from 1 to 9 do {
                                            private _index = (round (_i * _stepSize)) min (_posCount - 1);
                                            private _wayPos = _positions select _index;
                                            private _wp = _group addWaypoint [_wayPos, 0];
                                            _wp setWaypointType "MOVE";
                                            _wp setWaypointBehaviour "SAFE";
                                            _wp setWaypointSpeed "LIMITED";
                                        };

                                        // Create path markers
                                        private _markerStep = (_posCount / 20) max 1;
                                        {
                                            if (_forEachIndex % _markerStep isEqualTo 0) then {
                                                private _markerName = format ["convoy_path_%1", _forEachIndex];
                                                private _marker = createMarkerLocal [_markerName, _x];
                                                _marker setMarkerTypeLocal "mil_dot";
                                                _marker setMarkerSizeLocal [0.5, 0.5];
                                                _marker setMarkerColorLocal "colorCivilian";
                                                _marker setMarkerAlpha 0.3;
                                            };
                                        } forEach _positions;
                                    };
                                }];

                                _lastPathUpdate = time;
                            };

                            // Update formation with delay using spawn
                            [_convoyGroup] spawn {
                                params ["_group"];
                                if (!isNull _group) then {
                                    sleep 2;
                                    _group setFormation "WEDGE";
                                    sleep 2;
                                    _group setFormation "COLUMN";
                                };
                            };
                        };
                    } else {
                        // Reset convoy state if group is invalid
                        ConVLocc = 0;
                        publicVariable "ConVLocc";
                        ["CONVOY", 2, "Convoy group invalid, resetting convoy state"] call FLO_fnc_log;
                    };

                } catch {
                    ["CONVOY_LOOP", 1, format ["Error in convoy loop: %1", _exception]] call FLO_fnc_log;
                };
            };
        };
    };
};

// Initialize background systems
call _fnc_initResourceLoop;
call _fnc_initConvoyLoop;

// ============================================================================
// CORE SYSTEMS INITIALIZATION
// ============================================================================

// Initialize Mission Commander System
remoteExec ["FLO_fnc_MissionStartup", 2];

// ============================================================================
// AUTO-SAVE SYSTEM
// ============================================================================

private _fnc_initAutoSave = {
    private _autoSaveEnabled = "AutoSaveSwitch" call BIS_fnc_getParamValue;
    private _autoSaveInterval = "AutoSaveInterval" call BIS_fnc_getParamValue;

    if (_autoSaveEnabled isEqualTo 1) then {
        ["AUTOSAVE", 3, format ["Auto-save enabled with %1 second interval", _autoSaveInterval]] call FLO_fnc_log;

        [] spawn {
            private _interval = "AutoSaveInterval" call BIS_fnc_getParamValue;
            private _lastSave = time;

            while {true} do {
                sleep 30; // Check every 30 seconds

                // Only save if enough time has passed
                if (time - _lastSave >= _interval) then {
                    try {
                        call FLO_fnc_MissionSave;
                        _lastSave = time;
                    } catch {
                        ["AUTOSAVE", 1, format ["Auto-save failed: %1", _exception]] call FLO_fnc_log;
                    };
                };
            };
        };
    } else {
        ["AUTOSAVE", 3, "Auto-save disabled"] call FLO_fnc_log;
    };
};

call _fnc_initAutoSave;

// ============================================================================
// CONDITIONAL SYSTEMS
// ============================================================================

// Initialize purchase crate system if arsenal is unrestricted
private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;
if (_restrictedArsenal isEqualTo 0) then {
    try {
        [] call FLO_fnc_purchaseCrate;
        ["INIT", 3, "Purchase crate system initialized (unrestricted arsenal)"] call FLO_fnc_log;
    } catch {
        ["INIT", 1, format ["Failed to initialize purchase crate system: %1", _exception]] call FLO_fnc_log;
    };
};

// ============================================================================
// PERFORMANCE OPTIMIZATION SYSTEMS
// ============================================================================

// Dynamic View Distance System
private _fnc_initViewDistanceSystem = {
    [] spawn {
        // Configuration parameters
        private _config = createHashMapFromArray [
            ["minViewDistance", 1500],
            ["maxViewDistance", 7500],
            ["targetFPS", 50],
            ["sampleInterval", 15],
            ["sampleSize", 5],
            ["changeStep", 500],
            ["currentViewDistance", 3000],
            ["fpsThresholdLow", 5],      // FPS below target - threshold
            ["fpsThresholdHigh", 10],    // FPS above target + threshold
            ["emergencyThreshold", 20]   // Emergency FPS threshold for rapid adjustment
        ];

        private _fpsSamples = [];
        private _lastAdjustment = time;
        private _adjustmentCooldown = 30; // Minimum seconds between adjustments

        ["VIEWDIST", 3, format ["Dynamic view distance system started (target: %1 FPS)", _config get "targetFPS"]] call FLO_fnc_log;

        while {true} do {
            try {
                // Collect FPS sample
                private _currentFPS = diag_fps;
                _fpsSamples pushBack _currentFPS;

                // Maintain sample size
                if (count _fpsSamples > (_config get "sampleSize")) then {
                    _fpsSamples deleteAt 0;
                };

                // Calculate statistics when we have enough samples
                if (count _fpsSamples >= (_config get "sampleSize")) then {
                    // Calculate average FPS
                    private _avgFPS = 0;
                    {_avgFPS = _avgFPS + _x} forEach _fpsSamples;
                    _avgFPS = _avgFPS / (count _fpsSamples);

                    // Calculate FPS variance for stability assessment
                    private _variance = 0;
                    {_variance = _variance + ((_x - _avgFPS) ^ 2)} forEach _fpsSamples;
                    _variance = _variance / (count _fpsSamples);

                    private _currentViewDist = _config get "currentViewDistance";
                    private _targetFPS = _config get "targetFPS";
                    private _newViewDistance = _currentViewDist;

                    // Emergency adjustment for very low FPS
                    if (_avgFPS < (_config get "emergencyThreshold")) then {
                        _newViewDistance = (_config get "minViewDistance");
                        ["VIEWDIST", 2, format ["Emergency FPS detected (%1), setting minimum view distance", round _avgFPS]] call FLO_fnc_log;
                    } else {
                        // Normal adjustment logic
                        if (_avgFPS < (_targetFPS - (_config get "fpsThresholdLow")) &&
                            {time - _lastAdjustment > _adjustmentCooldown}) then {
                            // FPS too low, decrease view distance
                            _newViewDistance = (_currentViewDist - (_config get "changeStep")) max (_config get "minViewDistance");
                        } else {
                            if (_avgFPS > (_targetFPS + (_config get "fpsThresholdHigh")) &&
                                {time - _lastAdjustment > _adjustmentCooldown}) then {
                                // FPS comfortably high, increase view distance
                                _newViewDistance = (_currentViewDist + (_config get "changeStep")) min (_config get "maxViewDistance");
                            };
                        };
                    };

                    // Apply adjustment if needed
                    if (_newViewDistance != _currentViewDist) then {
                        _config set ["currentViewDistance", _newViewDistance];
                        setViewDistance _newViewDistance;
                        _lastAdjustment = time;

                        ["VIEWDIST", 3, format ["View distance adjusted to %1m (FPS: %2, Variance: %3)",
                            _newViewDistance, round _avgFPS, round _variance]] call FLO_fnc_log;
                    };
                };

            } catch {
                ["VIEWDIST", 1, format ["Error in view distance system: %1", _exception]] call FLO_fnc_log;
            };

            sleep (_config get "sampleInterval");
        };
    };
};

call _fnc_initViewDistanceSystem;

// ============================================================================
// INITIALIZATION COMPLETE
// ============================================================================

["INIT", 3, "Server initialization completed successfully"] call FLO_fnc_log;