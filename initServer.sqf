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
// FACTION INITIALIZATION (DEDICATED SERVER)
// ============================================================================

if (isDedicated) then {
    execVM "Scripts\Init\init_groups.sqf";
    setViewDistance 3000; // Required for AI knowsAbout calculations
    sleep 1;
    waitUntil {sleep 0.1; F_Init};
};

// ============================================================================
// CONFIG CACHE INITIALIZATION
// ============================================================================

// Wait for faction arrays to be initialized
waitUntil {
    sleep 0.1;
    !isNil "East_Units" &&
    !isNil "East_Air_Transport" &&
    !isNil "East_Ground_Vehicles_Light"
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
        ["Side Missions", {[] call FLO_fnc_registerDefaultMissions}],
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