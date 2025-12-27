/*
 * FLO Server Initialization Script
 * Author: Frontline Operations Development Group
 * Description: Server initialization
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
    ["F_Init", false]
];

// Set and publish global variables
{
    missionNamespace setVariable [_x, _y];
    publicVariable _x;
} forEach _globalVars;

// Initialize world center position (fix case sensitivity issue)
Centerposition = [worldSize / 2, worldSize / 2, 0];

// ============================================================================
// EARLY INITIALIZATION
// ============================================================================

// Initialize Heartbeat System
[] spawn FLO_fnc_heartbeat;

// ============================================================================
// MISSION LOADING SEQUENCE
// ============================================================================

// Wait for mission to be fully loaded
waitUntil {sleep 0.1; !isNil "MissionLoadedLitterally" && {MissionLoadedLitterally}};

// Wait for starting location configuration
waitUntil {sleep 0.1; StartingLocationDone};

// ============================================================================
// FACTION INITIALIZATION
// ============================================================================

// On dedicated server, we run init_groups.sqf ourselves
// On listen server, the host player runs it via initPlayerLocal.sqf
if (isDedicated) then {
    ["INIT_SERVER", 3, "Dedicated server - running faction initialization"] call FLO_fnc_log;
    execVM "Scripts\Init\init_groups.sqf";
    setViewDistance 3000; // Required for AI knowsAbout calculations
} else {
    ["INIT_SERVER", 3, "Listen server - waiting for host player faction initialization"] call FLO_fnc_log;
};

// Wait for faction initialization to complete (ALL server types)
// This ensures init_groups.sqf has finished before we continue
private _factionInitStart = diag_tickTime;
private _factionInitTimeout = 120; // 2 minutes timeout

waitUntil {
    sleep 0.5;
    private _fInitReady = !isNil "F_Init" && {F_Init};
    private _timedOut = (diag_tickTime - _factionInitStart) > _factionInitTimeout;

    if (_timedOut && !_fInitReady) then {
        ["INIT_SERVER", 1, "CRITICAL: Faction initialization timeout! F_Init not set after 2 minutes."] call FLO_fnc_log;
    };

    _fInitReady || _timedOut
};

if (!isNil "F_Init" && {F_Init}) then {
    ["INIT_SERVER", 3, format["Faction initialization complete (took %1 seconds)", diag_tickTime - _factionInitStart]] call FLO_fnc_log;
} else {
    ["INIT_SERVER", 1, "Faction initialization failed - continuing with defaults"] call FLO_fnc_log;
};

// ============================================================================
// CONFIG CACHE INITIALIZATION
// ============================================================================

// Wait for faction arrays to be initialized (should already be done if F_Init is true)
private _arrayWaitStart = diag_tickTime;
private _arrayWaitTimeout = 30;

waitUntil {
    sleep 0.1;
    private _arraysReady = !isNil "East_Units" && !isNil "East_Air_Transport" && !isNil "East_Ground_Vehicles_Light";
    private _timedOut = (diag_tickTime - _arrayWaitStart) > _arrayWaitTimeout;

    if (_timedOut && !_arraysReady) then {
        ["INIT_SERVER", 1, format["CRITICAL: Faction arrays not initialized! Missing: %1",
            [
                if (isNil "East_Units") then {"East_Units"} else {""},
                if (isNil "East_Air_Transport") then {"East_Air_Transport"} else {""},
                if (isNil "East_Ground_Vehicles_Light") then {"East_Ground_Vehicles_Light"} else {""}
            ] select {_x != ""}
        ]] call FLO_fnc_log;
    };

    _arraysReady || _timedOut
};

if (isNil "East_Units" || isNil "East_Air_Transport" || isNil "East_Ground_Vehicles_Light") exitWith {
    ["INIT_SERVER", 1, "FATAL: Cannot continue without faction arrays. Mission initialization aborted."] call FLO_fnc_log;
};

// Initialize config cache with categorized data
private _fnc_initConfigCache = {
    private _helipads = [
        "Land_HelipadCircle_F", "Land_HelipadCivil_F", "Heli_H_rescue",
        "Land_HelipadRescue_F", "Land_HelipadSquare_F", "HeliHRescue",
        "Heli_H_civil", "HeliHCivil", "HeliH"
    ];

    private _vehicles = [
        East_Air_Heli, East_Ground_Transport, East_Ground_Vehicles_Light,
        East_Ground_Vehicles_Heavy, East_Ground_Vehicles_Ambient,
        East_Air_Transport, East_Air_Jet, East_Ground_Artillery, East_Air_Drone
    ];

    private _buildings = [
        "House", "Land_MilOffices_V1_F", "Land_Cargo_Tower_V3_F",
        "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F",
        "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V3_F",
        "Land_Cargo_House_V1_F"
    ];

    private _sovBuildings = [
        // Markers and indicators
        "Sign_Pointer_Cyan_F", "Land_Garbage_square3_F", "Land_Garbage_line_F",
        "Sign_Pointer_Yellow_F", "Sign_Sphere10cm_F", "Sign_Pointer_Blue_F",
        "Land_InvisibleBarrier_F", "Land_HelipadEmpty_F",
        // Military equipment
        "O_Radar_System_02_F", "O_G_Mortar_01_F", "O_G_HMG_02_high_F",
        // Command and control
        "Land_TripodScreen_01_large_black_F", "Land_vn_b_prop_mapstand_01",
        "MapBoard_altis_F", "Land_Laptop_device_F", "Land_Map_Malden_F",
        "Land_Document_01_F", "Land_File2_F",
        // Structures
        "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
        "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F",
        "Land_vn_controltower_01_f", "Land_Radar_F", "Land_TTowerBig_1_F",
        "Land_TTowerBig_2_F",
        // Screens and displays
        "Land_TripodScreen_01_large_F", "Land_TripodScreen_01_large_sand_F",
        "Land_TripodScreen_01_dual_v2_sand_F", "Land_TripodScreen_01_dual_v2_F",
        // Supply containers
        "Box_FIA_Support_F", "Box_FIA_Ammo_F", "Land_PowerGenerator_F",
        "Land_Barracks_01_camo_F", "Land_vn_barracks_01_camo_f",
        // Cargo structures
        "Land_Cargo_House_V1_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_Tower_V3_F",
        "Land_Cargo_Tower_V2_F", "Land_Cargo_House_V3_F", "Land_Cargo_HQ_V3_F",
        "Land_Cargo_HQ_V1_F",
        // Slingload containers
        "B_Slingload_01_Cargo_F", "B_Slingload_01_Repair_F",
        // Ammo boxes
        "VirtualReammoBox_small_F", "Box_NATO_WpsSpecial_F",
        "Box_NATO_AmmoOrd_F", "Box_NATO_Ammo_F", "Box_NATO_Wps_F"
    ];

    private _hqBuildings = [
        "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F",
        "Land_Cargo_House_V3_F", "Land_Cargo_HQ_V3_ruins_F",
        "Land_Cargo_HQ_V1_ruins_F", "Land_Cargo_House_V1_ruins_F",
        "Land_Cargo_House_V3_ruins_F", "House"
    ];

    private _bunkers = [
        "Land_BagBunker_Large_F", "Land_BagBunker_Small_F",
        "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F",
        "Land_Cargo_Patrol_V3_F", "Land_Cargo_Patrol_V2_F",
        "Land_Cargo_Patrol_V1_F"
    ];

    createHashMapFromArray [
        ["helipads", _helipads],
        ["tyres", ["Land_Tyre_F"]],
        ["vehicles", _vehicles],
        ["units", East_Units],
        ["fireObservers", East_FireObserver],
        ["buildings", _buildings],
        ["SOVbuildings", _sovBuildings],
        ["HQbuildings", _hqBuildings],
        ["bunkers", _bunkers]
    ]
};

FLO_configCache = call _fnc_initConfigCache;
publicVariable "FLO_configCache";

// ============================================================================
// VIRTUALIZATION SYSTEM INITIALIZATION
// ============================================================================

// Initialize the virtualization system after faction arrays are ready
// This must happen before objective groups are created
private _fnc_initVirtualizationSystem = {
    // Get activation distance from faction config, default to 2000m
    private _activationDistance = missionNamespace getVariable ["OPFOR_Virtualization_Distance", 2000];

    ["INIT_SERVER", 3, format["Initializing virtualization system (activation distance: %1m)", _activationDistance]] call FLO_fnc_log;

    // Initialize the virtualization system
    [_activationDistance] call FLO_fnc_initVirtualization;

    // Wait for confirmation
    private _startTime = diag_tickTime;
    private _timeout = 10;
    waitUntil {
        sleep 0.1;
        (!isNil "FLO_VirtualizationReady" && {FLO_VirtualizationReady}) ||
        {diag_tickTime - _startTime > _timeout}
    };

    if (!isNil "FLO_VirtualizationReady" && {FLO_VirtualizationReady}) then {
        ["INIT_SERVER", 3, "Virtualization system ready"] call FLO_fnc_log;
    } else {
        ["INIT_SERVER", 1, "Virtualization system initialization timeout!"] call FLO_fnc_log;
    };
};

call _fnc_initVirtualizationSystem;

// ============================================================================
// OBJECTIVE GROUPS INITIALIZATION
// ============================================================================

// Create virtual groups at objectives after virtualization is ready
private _fnc_initObjectiveGroups = {
    ["INIT_SERVER", 3, "Waiting for objectives to be indexed..."] call FLO_fnc_log;

    // Wait for objectives to be indexed
    private _startTime = diag_tickTime;
    private _timeout = 60; // Give more time for large maps

    waitUntil {
        sleep 0.5;
        (!isNil "FLO_Objectives" && {count keys FLO_Objectives > 0}) ||
        {diag_tickTime - _startTime > _timeout}
    };

    if (isNil "FLO_Objectives" || {count keys FLO_Objectives == 0}) exitWith {
        ["INIT_SERVER", 2, "No objectives found after 60s - skipping objective group initialization"] call FLO_fnc_log;
        // Still set InitializationOG so other systems don't hang
        InitializationOG = true;
        publicVariable "InitializationOG";
    };

    ["INIT_SERVER", 3, format["Found %1 objectives - initializing virtual groups", count keys FLO_Objectives]] call FLO_fnc_log;

    // Verify virtualization is ready before creating groups
    if (isNil "FLO_virtualGroups") then {
        ["INIT_SERVER", 1, "Virtualization system not ready - attempting to initialize"] call FLO_fnc_log;
        [2000] call FLO_fnc_initVirtualization;
    };

    // Initialize objective groups
    [] call FLO_fnc_initializeObjectiveGroups;

    // Wait for completion with timeout
    private _ogStartTime = diag_tickTime;
    private _ogTimeout = 120; // 2 minutes for large maps

    waitUntil {
        sleep 0.5;
        (!isNil "InitializationOG" && {InitializationOG}) ||
        {diag_tickTime - _ogStartTime > _ogTimeout}
    };

    if (!isNil "InitializationOG" && {InitializationOG}) then {
        ["INIT_SERVER", 3, format["Objective groups initialization complete (took %1 seconds)", diag_tickTime - _ogStartTime]] call FLO_fnc_log;
    } else {
        ["INIT_SERVER", 1, "Objective groups initialization timeout - setting flag anyway"] call FLO_fnc_log;
        InitializationOG = true;
        publicVariable "InitializationOG";
    };
};

// Spawn objective group initialization to not block other systems
[] spawn _fnc_initObjectiveGroups;

// ============================================================================
// BACKGROUND SYSTEMS INITIALIZATION
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
// MISSION SYSTEMS INITIALIZATION
// ============================================================================

// Initialize systems in dependency order with error handling
private _fnc_initSystems = {
    private _systems = [
        ["Intel System", {[] call FLO_fnc_intelSystem}],
        ["Side Mission Templates", {[] call FLO_fnc_sideMissionTemplatesInit}],
        ["Side Mission Manager", {["start"] call FLO_fnc_sideMissionManager}],
        ["Background Events", {[] call FLO_fnc_backgroundEvents}],
        ["OPFOR Resources", {[] call FLO_fnc_opforResources}],
        ["Logistics Network", {[] call FLO_fnc_logisticsNetwork}],
        ["AI Commander Analyzer", {FLO_AICommander_UnitCapabilityAnalyzer = call FLO_fnc_aiCommanderUnitCapabilityAnalyzer}],
        ["AI Commander", {
            FLO_AICommander = [] call FLO_fnc_aiCommander;
            [FLO_AICommander, false] call FLO_fnc_aiCommanderStagingDebug;
        }]
    ];

    {
        _x params ["_systemName", "_initCode"];

        try {
            ["INIT", 3, format ["Initializing %1...", _systemName]] call FLO_fnc_log;
            call _initCode;
            ["INIT", 3, format ["%1 initialized successfully", _systemName]] call FLO_fnc_log;
        } catch {
            ["INIT", 1, format ["Failed to initialize %1: %2", _systemName, _exception]] call FLO_fnc_log;
        };

        sleep 0.1; // Small delay between system initializations
    } forEach _systems;
};

call _fnc_initSystems;

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