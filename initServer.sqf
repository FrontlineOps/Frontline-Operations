HQLOCC = 0 ;
publicVariable "HQLOCC";

MarLOCC = 0;
publicVariable "MarLOCC";
AVENGLOCC = 1;
publicVariable "AVENGLOCC";

ConVLocc = 0;
publicVariable "ConVLocc";

FLO_Objectives_Debug = false;
StartingLocationDone = false;
Centerposition = [worldSize / 2, worldsize / 2, 0];

// Initialize Heartbeat System
[] spawn FLO_fnc_heartbeat;

if (isNil "F_Init") then {F_Init = false;};

// After Mission Loaded
waitUntil {MissionLoadedLitterally};

// Mission Settings Loading
waitUntil {StartingLocationDone};

// Dedicated server needs to know factions too
if (isDedicated) then {
    execVM "Scripts\Init\init_groups.sqf"; 
    setViewDistance 3000; // for knowsabout
    sleep 1;
    waitUntil {F_Init};
};

// Wait for faction initialization before creating FLO_configCache
waitUntil {!isNil "East_Units" && !isNil "East_Air_Transport" && !isNil "East_Ground_Vehicles_Light"};

// Initialize FLO_configCache with proper arrays
FLO_configCache = createHashMapFromArray [
    ["helipads", ["Land_HelipadCircle_F","Land_HelipadCivil_F","Heli_H_rescue","Land_HelipadRescue_F","Land_HelipadSquare_F","HeliHRescue","Heli_H_civil","HeliHCivil","HeliH"]],
    ["tyres", ["Land_Tyre_F"]],
    ["vehicles", [East_Air_Heli, East_Ground_Transport, East_Ground_Vehicles_Light, East_Ground_Vehicles_Heavy, East_Ground_Vehicles_Ambient, East_Air_Transport, East_Air_Jet, East_Ground_Artillery, East_Air_Drone]],
    ["units", East_Units],
    ["fireObservers", East_FireObserver],
    ["buildings", ["House", "Land_MilOffices_V1_F", "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"]],
    ["SOVbuildings", ["Sign_Pointer_Cyan_F", "Land_Garbage_square3_F", "Land_Garbage_line_F", "Sign_Pointer_Yellow_F", "Sign_Sphere10cm_F", "Land_vn_controltower_01_f", "Sign_Pointer_Blue_F", "Land_InvisibleBarrier_F", "Land_HelipadEmpty_F",
    "O_Radar_System_02_F", "O_G_Mortar_01_F", "O_G_HMG_02_high_F", "Land_TripodScreen_01_large_black_F", "Land_vn_b_prop_mapstand_01", "MapBoard_altis_F", "Land_Laptop_device_F", "Land_Map_Malden_F",
    "Land_Document_01_F", "Land_File2_F", "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "Land_Radar_F", "Land_TTowerBig_1_F",
    "Land_TTowerBig_2_F", "Land_TripodScreen_01_large_F", "Land_TripodScreen_01_large_sand_F", "Land_TripodScreen_01_dual_v2_sand_F", "Land_TripodScreen_01_dual_v2_F", "Box_FIA_Support_F", "Box_FIA_Ammo_F",
    "Land_PowerGenerator_F", "Land_Barracks_01_camo_F", "Land_vn_barracks_01_camo_f", "Land_Cargo_House_V1_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_House_V3_F", "Land_Cargo_HQ_V3_F",
    "Land_Cargo_HQ_V1_F", "B_Slingload_01_Cargo_F", "B_Slingload_01_Repair_F", "VirtualReammoBox_small_F", "Box_NATO_WpsSpecial_F", "Box_NATO_AmmoOrd_F", "Box_NATO_Ammo_F", "Box_NATO_Wps_F"]],
    ["HQbuildings", ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F", "Land_Cargo_HQ_V3_ruins_F", "Land_Cargo_HQ_V1_ruins_F", "Land_Cargo_House_V1_ruins_F", "Land_Cargo_House_V3_ruins_F", "House"]],
    ["bunkers", ["Land_BagBunker_Large_F", "Land_BagBunker_Small_F", "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F", "Land_Cargo_Patrol_V3_F", "Land_Cargo_Patrol_V2_F", "Land_Cargo_Patrol_V1_F"]]
];
publicVariable "FLO_configCache";

// SYSTEMs Init Server 
// Run these only if dedicated (not hosted - hosted servers run initPlayerLocal)

//Resource Loops//Convoy Loops//Radio Tower Loops
[] spawn {  
    while { sleep 60 ; time > 0 } do {  
        // Count BLUFOR objectives
        private _bluforObjectives = 0;
        {
            private _objData = FLO_Objectives get _x;
            if (!isNil "_objData" && {(_objData get "owner") isEqualTo west}) then {
                _bluforObjectives = _bluforObjectives + 1;
            };
        } forEach (keys FLO_Objectives);

        // Add reward based on number of BLUFOR objectives
        if (_bluforObjectives > 0) then {
            [_bluforObjectives * 2] call FLO_fnc_addReward;
        };
    };
};

// Separate convoy loop
[] spawn {
    while { sleep 60 ; time > 0 } do {
        if (ConVLocc isEqualTo 1) then {
            // Clean up old road markers
            private _RoadMrks = allMapMarkers select {markerType _x isEqualTo "mil_dot" && markerColor _x isEqualTo "colorCivilian" && markerAlpha _x isEqualTo 0.3};
            {deleteMarker _x} forEach _RoadMrks;

            // Get the CGM from missionNamespace
            private _CGM = missionNamespace getVariable ["CGM", grpNull];
            
            // Make sure CGM exists and has vehicles before proceeding
            if (!isNull _CGM && {count (units _CGM) > 0}) then {
                // Get the lead vehicle (V0)
                private _leadVehicle = vehicle (leader _CGM);
                
                // Only update waypoints if we have a valid lead vehicle
                if (!isNull _leadVehicle && {alive _leadVehicle}) then {
                    // Clear existing waypoints
                    {deleteWaypoint((waypoints _CGM) select 0);} forEach waypoints _CGM;

                    // Calculate new path
                    (calculatePath ["wheeled_APC", "safe", position _leadVehicle, position (selectRandom ((getMarkerPos "ConvoyDest") nearRoads 500))]) addEventHandler ["PathCalculated", {
                        params ["_path", "_posesArr"];
                        private _CGM = missionNamespace getVariable ["CGM", grpNull];
                        
                        if (!isNull _CGM) then {
                            private _posesArrCnt = count _posesArr;
                            private _posesArrCntndd = round (_posesArrCnt / 10);
                            private _indexed = [1,2,3,4,5,6,7,8,9];

                            // Create waypoints
                            {
                                private _Waypos = _posesArr select (_x * _posesArrCntndd);
                                private _wp = _CGM addWaypoint [_Waypos, 0];
                                _wp SetWaypointType "MOVE";
                                _wp setWaypointBehaviour "SAFE";
                                _wp setWaypointSpeed "LIMITED";
                            } forEach _indexed;

                            // Create markers for the path
                            {
                                private _marker = createMarkerLocal [(str position _leadVehicle) + str _forEachIndex, _x];
                                _marker setMarkerTypeLocal "mil_dot";
                                _marker setMarkerSizeLocal [0.5, 0.5];
                                _marker setMarkerColorLocal "colorCivilian";
                                _marker setMarkerAlpha 0.3;
                            } forEach _posesArr;
                        };
                    }];
                    
                    // Update formation
                    sleep 2;
                    _CGM setFormation "WEDGE";
                    sleep 2;
                    _CGM setFormation "COLUMN";
                };
            } else {
                // If CGM is null or has no units, reset convoy state
                if (ConVLocc isEqualTo 1) then {
                    ConVLocc = 0;
                    publicVariable "ConVLocc";
                };
            };
        };
    };
};

//Mission Commander System
remoteExec ["FLO_fnc_MissionStartup", 2];

//Saving System
AutoSaveSwitchVal = "AutoSaveSwitch" call BIS_fnc_getParamValue;
AutoSaveIntervalVal = "AutoSaveInterval" call BIS_fnc_getParamValue;

if (AutoSaveSwitchVal isEqualTo 1) then {
    [] spawn {  
        while { true } do {  
            call FLO_fnc_MissionSave;
            sleep AutoSaveIntervalVal;  
        };
    };
};

// Initialize Intel System
[] call FLO_fnc_intelSystem;

// Register default side missions
[] call FLO_fnc_registerDefaultMissions;

// Initialize the resource system
[] call FLO_fnc_opforResources;

// Initialize the logistics network
[] call FLO_fnc_logisticsNetwork;

// Initialize AI Commander Unit Capability Analyzer
FLO_AICommander_UnitCapabilityAnalyzer = call FLO_fnc_aiCommanderUnitCapabilityAnalyzer;

// Initialize AI Commander
FLO_AICommander = [] call FLO_fnc_aiCommander;
[FLO_AICommander, false] call FLO_fnc_aiCommanderStagingDebug;

private _RestrictedArsenalVal = "RestrictedArsenal" call BIS_fnc_getParamValue;
if (_RestrictedArsenalVal isEqualTo 0) then {
    [] call FLO_fnc_purchaseCrate;
};

// Dynamic View Distance System based on server FPS
[] spawn {
    // Configuration
    private _minViewDistance = 1500;    // Minimum view distance
    private _maxViewDistance = 7500;    // Maximum view distance
    private _targetFPS = 50;            // Target server FPS
    private _sampleInterval = 15;       // Seconds between checks
    private _sampleSize = 5;            // Number of samples to average
    private _changeStep = 500;          // How much to change view distance each time
    private _currentViewDistance = 3000; // Starting view distance
    
    private _fpsSamples = [];
    
    while {true} do {
        // Add current FPS to samples
        _fpsSamples pushBack diag_fps;
        
        // Keep only the most recent samples
        if (count _fpsSamples > _sampleSize) then {
            _fpsSamples deleteAt 0;
        };
        
        // Calculate average FPS over samples
        private _avgFPS = 0;
        if (count _fpsSamples > 0) then {
            {
                _avgFPS = _avgFPS + _x;
            } forEach _fpsSamples;
            _avgFPS = _avgFPS / (count _fpsSamples);
        };
        
        // Only adjust if we have enough samples
        if (count _fpsSamples >= _sampleSize) then {
            // Determine if view distance should be changed
            private _newViewDistance = _currentViewDistance;
            
            if (_avgFPS < _targetFPS - 5) then {
                // FPS is too low, decrease view distance
                _newViewDistance = (_currentViewDistance - _changeStep) max _minViewDistance;
            } else {
                if (_avgFPS > _targetFPS + 10) then {
                    // FPS is comfortably high, increase view distance
                    _newViewDistance = (_currentViewDistance + _changeStep) min _maxViewDistance;
                };
            };
            
            // Apply the change if needed
            if (_newViewDistance != _currentViewDistance) then {
                _currentViewDistance = _newViewDistance;
                setViewDistance _currentViewDistance;
                diag_log format ["[FLO][ViewDistance] Adjusted to %1m based on average FPS of %2", _currentViewDistance, _avgFPS];
            };
        };
        
        // Wait for next check
        sleep _sampleInterval;
    };
};