HQLOCC = 0 ;
publicVariable "HQLOCC";

TRG1LOCC = 0;
publicVariable "TRG1LOCC";
TRG2LOCC = 0;
publicVariable "TRG2LOCC";
TRG3LOCC = 0;
publicVariable "TRG3LOCC";
MarLOCC = 0;
publicVariable "MarLOCC";
AVENGLOCC = 1 ;

COMMSDIS = 0;
publicVariable "COMMSDIS";
HELIDIS = 0;
publicVariable "HELIDIS";
AIRDIS = 0;
publicVariable "AIRDIS";
LOGDIS = 0;
publicVariable "LOGDIS";
INFDIS = 0;
publicVariable "INFDIS";
ARMDIS = 0;
publicVariable "ARMDIS";
ConVLocc = 0;
publicVariable "ConVLocc";

StartingLocationDone = false;
VSDistance = 2500; //750; 
VS_FPS = [];
VSTimeDelay = 20;
VSCurrentTime = diag_tickTime;
VS_IsWorking = false;
Centerposition = [worldSize / 2, worldsize / 2, 0];

if (isNil "F_Init") then {F_Init = false;};

// After Mission Loaded
waitUntil {MissionLoadedLitterally};

//Mission Settings Loading
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
    "Land_Cargo_HQ_V1_F", "B_Slingload_01_Cargo_F", "B_Slingload_01_Repair_F"]],
    ["HQbuildings", ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F", "Land_Cargo_HQ_V3_ruins_F", "Land_Cargo_HQ_V1_ruins_F", "Land_Cargo_House_V1_ruins_F", "Land_Cargo_House_V3_ruins_F", "House"]],
    ["bunkers", ["Land_BagBunker_Large_F", "Land_BagBunker_Small_F", "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F", "Land_Cargo_Patrol_V3_F", "Land_Cargo_Patrol_V2_F", "Land_Cargo_Patrol_V1_F"]]
];
publicVariable "FLO_configCache";

// SYSTEMs Init Server 
// Run these only if dedicated (not hosted - hosted servers run initPlayerLocal)

// ETV Init - Everyone
execVM "Scripts\EtV.sqf";
waitUntil {!isNil "EtVInitialized"};

// Parallel execution
{
    0 spawn compileFinal preprocessFileLineNumbers _x;
} forEach ["Scripts\Init\init_Triggers_1.sqf", "Scripts\Init\init_Triggers_2.sqf", "Scripts\Init\init_Triggers_3.sqf"];


//Resource Loops//Convoy Loops//Radio Tower Loops
[] spawn {  
    while { sleep 90 ; time > 0 } do {  
        private _allENMMarks = allMapMarkers select {markerShape _x isEqualTo "RECTANGLE" && markerBrush _x isEqualTo "FDiagonal"};
        {deleteMarker _x} forEach _allENMMarks;

        if (count (allMapMarkers select { markerType _x isEqualTo "loc_Transmitter" && markerColor _x isEqualTo "colorBLUFOR"}) > 0) then {
            remoteExec ["FLO_fnc_ICS", 2];
        };

        // Why is this here?
        // This is a convoy loop, move it to it's own file so we can preprocessFileLineNumbers it and pass CGM Properly
        // This causes convoys to be broken due to no CGM being passed
        if (ConVLocc isEqualTo 1) then {
            private _RoadMrks = allMapMarkers select {markerType _x isEqualTo "mil_dot" && markerColor _x isEqualTo "colorCivilian" && markerAlpha _x isEqualTo 0.3};
            {deleteMarker _x} forEach _RoadMrks;

            // Get the CGM from missionNamespace
            private _CGM = missionNamespace getVariable ["CGM", grpNull];
            
            // Make sure CGM exists before proceeding
            if (!isNull _CGM) then {
                {deleteWaypoint((waypoints _CGM) select 0);} forEach waypoints _CGM;

                (calculatePath ["wheeled_APC", "safe", position V0, position (selectRandom ((getMarkerPos "ConvoyDest") nearRoads 500))]) addEventHandler ["PathCalculated", {
                    private _posesArr = _this select 1;
                    private _posesArrCnt = count _posesArr;
                    private _posesArrCntndd = round (_posesArrCnt / 10);
                    private _indexed = [1,2,3,4,5,6,7,8,9];
                    private _CGM = missionNamespace getVariable ["CGM", grpNull];

                    {
                        private _Waypos = _posesArr select (_x * _posesArrCntndd);
                        private _wp = _CGM addWaypoint [_Waypos, 0];
                        _wp SetWaypointType "MOVE";
                        _wp setWaypointBehaviour "SAFE";
                        _wp setWaypointSpeed "LIMITED";
                    } forEach _indexed;

                    {
                        private _marker = createMarkerLocal [(str position V0) + str _forEachIndex, _x];
                        _marker setMarkerTypeLocal "mil_dot";
                        _marker setMarkerSizeLocal [0.5, 0.5];
                        _marker setMarkerColorLocal "colorCivilian";
                        _marker setMarkerAlpha 0.3;
                    } forEach (_this select 1);
                }];
                sleep 2;
                _CGM setFormation "WEDGE";
                sleep 2;
                _CGM setFormation "COLUMN";
            } else {
                diag_log "ERROR: CGM is null in convoy loop";
            };
        };

        private _BluezoneMarks = allMapMarkers select { markerType _x isEqualTo "b_installation" && (markerColor _x isEqualTo "colorBLUFOR" or markerColor _x isEqualTo "ColorWEST") };
        { [1] call FLO_fnc_addReward; } foreach _BluezoneMarks;
    };
};

//Dynamic Virtualization System
[] spawn { 
    sleep 20; 
    addMissionEventHandler ["EachFrame", {[] call FLO_fnc_CDVS}];
};

//Mission Commander System
remoteExec ["FLO_fnc_MissionStartup", 2];
[] spawn { 
    [] call FLO_fnc_MissionFrontline;
};

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

// Initialize the resource system
["init", []] call FLO_fnc_opforResources;

// Initialize the garrison management system
[] call FLO_fnc_garrisonManager;

// Initialize the logistics network
["init", []] call FLO_fnc_logisticsNetwork;

// Initialize the Task Force system
["init", []] call FLO_fnc_TaskForceSystem;

// Initialize AI Commander Unit Capability Analyzer
FLO_AICommander_UnitCapabilityAnalyzer = call FLO_fnc_aiCommanderUnitCapabilityAnalyzer;

// Initialize AI Commander
FLO_AICommander = ["DEFEND"] call FLO_fnc_aiCommander;

setViewDistance 3000;

// Dynamic View Distance System based on server FPS
[] spawn {
    // Configuration
    private _minViewDistance = 1500;    // Minimum view distance
    private _maxViewDistance = 5000;    // Maximum view distance
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
                ["ViewDistance", 1, format ["Adjusted to %1m based on average FPS of %2", _currentViewDistance, _avgFPS]] call FLO_fnc_log;
                diag_log format ["[FLO][ViewDistance] Adjusted to %1m based on average FPS of %2", _currentViewDistance, _avgFPS];
            };
        };
        
        // Wait for next check
        sleep _sampleInterval;
    };
};