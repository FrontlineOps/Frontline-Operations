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
publicVariable "AVENGLOCC";

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
ConVLocc = 0 ;
publicVariable "ConVLocc";

StartingLocationDone = false;

VSDistance = 2500; //750; 
VS_FPS = [];
VSTimeDelay = 20;
VSCurrentTime = diag_tickTime;
VS_IsWorking = false;

if (isNil "F_Init") then {F_Init = false;};

// After Mission Loaded
waitUntil {MissionLoadedLitterally};

//Mission Settings Loading
waitUntil {StartingLocationDone};

// Dedicated server needs to know factions too
if (isDedicated) then {
    execVM "Scripts\init\init_groups.sqf"; 
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

// R3F Init - Everyone
execVM "R3F_LOG\init.sqf";

// ETV Init - Everyone
execVM "Scripts\EtV.sqf";
waitUntil {!isNil "EtVInitialized"};

// private _executeAndWait= {
//     params ["_script"];
//     {
//         private _handle = execVM _x;
//         waitUntil {sleep 1; scriptDone _handle };
//     } forEach _script;
// };

// // Faster method - compile and execute immediately
// private _fastExecute = {
//     params ["_scripts"];
//     {
//         diag_log format ["[FLO] Compiling and executing trigger script: %1", _x];
//         call compileFinal preprocessFileLineNumbers _x;
//         diag_log format ["[FLO] Completed trigger script: %1", _x];
//     } forEach _scripts;
// };

// // Execute triggers using the faster method
// [["Scripts\Init\init_Triggers_1.sqf", "Scripts\Init\init_Triggers_2.sqf", "Scripts\Init\init_Triggers_3.sqf"]] call _fastExecute;

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
diag_log "[FLO] Intelligence System initialized";

// Initialize the resource system
["init", []] call FLO_fnc_opforResources;
diag_log "[FLO] Resource system initialized";

// Initialize the garrison management system
["init", []] call FLO_fnc_garrisonManager;
diag_log "[FLO] Garrison system initialized";

// Initialize the logistics network
["init", []] call FLO_fnc_logisticsNetwork;
diag_log "[FLO] Logistics network initialized";

// Initialize the Task Force system
["init", []] call FLO_fnc_TaskForceSystem;
diag_log "[FLO] Task Force system initialized";

// Start a background process to automatically create defensive lines
[] spawn {
    ["System", 3, "Starting defensive line management system"] call FLO_fnc_log;
    
    // Wait a bit for other systems to initialize
    sleep 120;
    
    while {true} do {
        ["DefenseLine", 4, "Starting defense line update cycle"] call FLO_fnc_log;
        
        // Get all potential frontline markers
        private _frontlineMarkers = [];
        
        // First try to find markers that are explicitly marked as frontline
        private _explicitFrontlineMarkers = allMapMarkers select {
            markerType _x isEqualTo "mil_flag" && 
            markerColor _x isEqualTo "ColorEAST"
        };
        
        if (count _explicitFrontlineMarkers > 0) then {
            _frontlineMarkers = _explicitFrontlineMarkers;
            ["DefenseLine", 4, format ["Found %1 explicit frontline markers", count _frontlineMarkers]] call FLO_fnc_log;
        } else {
            // If no explicit markers, calculate frontline from OPFOR and BLUFOR positions
            private _opforMarkers = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["o_support", "n_support", "o_installation", "n_installation"]
            };
            
            private _bluforMarkers = allMapMarkers select {
                markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] && 
                markerType _x in ["b_installation", "b_support"]
            };
            
            ["DefenseLine", 4, format ["Found %1 OPFOR markers and %2 BLUFOR markers", count _opforMarkers, count _bluforMarkers]] call FLO_fnc_log;
            
            // Find OPFOR markers closest to BLUFOR territory
            {
                private _opforPos = getMarkerPos _x;
                private _distanceToBlufor = 999999;
                private _closestBlufor = "";
                
                {
                    private _bluforPos = getMarkerPos _x;
                    private _distance = _opforPos distance _bluforPos;
                    
                    if (_distance < _distanceToBlufor) then {
                        _distanceToBlufor = _distance;
                        _closestBlufor = _x;
                    };
                } forEach _bluforMarkers;
                
                // If an OPFOR marker is within a reasonable range of BLUFOR, consider it frontline
                if (_distanceToBlufor < 2500) then {
                    _frontlineMarkers pushBack _x;
                    ["DefenseLine", 4, format ["Added marker %1 to frontline (distance to BLUFOR: %2m)", _x, _distanceToBlufor]] call FLO_fnc_log;
                };
            } forEach _opforMarkers;
        };
        
        // If frontline markers found, create or reinforce defense lines
        if (count _frontlineMarkers > 0) then {
            ["DefenseLine", 3, format ["Processing %1 frontline markers", count _frontlineMarkers]] call FLO_fnc_log;
            
            // Get the aggression level to determine strength of defense
            private _aggressionMarkers = allMapMarkers select {markerColor _x isEqualTo "Color6_FD_F"};
            private _aggrScore = 5; // Default medium aggression
            
            if (count _aggressionMarkers > 0) then {
                _aggrScore = parseNumber (markerText (_aggressionMarkers select 0));
                ["DefenseLine", 4, format ["Current aggression score: %1", _aggrScore]] call FLO_fnc_log;
            };
            
            private _defenseStrength = switch (true) do {
                case (_aggrScore < 4): {"light"};
                case (_aggrScore < 9): {"medium"};
                default {"heavy"};
            };
            
            ["DefenseLine", 3, format ["Defense strength set to: %1", _defenseStrength]] call FLO_fnc_log;
            
            // Get current resources
            private _currentResources = ["get", []] call FLO_fnc_opforResources;
            ["Resources", 3, format ["Current resources: %1", _currentResources]] call FLO_fnc_log;
            
            // Calculate the number of defense lines to create/reinforce based on resources
            private _maxLinesToProcess = floor (_currentResources / 25);
            _maxLinesToProcess = _maxLinesToProcess min 3; // Cap at 3 lines per cycle
            
            if (_maxLinesToProcess > 0) then {
                ["DefenseLine", 3, format ["Will process up to %1 defense lines this cycle", _maxLinesToProcess]] call FLO_fnc_log;
                
                // Process a random selection of frontline markers
                private _markersToProcess = [];
                
                if (count _frontlineMarkers <= _maxLinesToProcess) then {
                    _markersToProcess = _frontlineMarkers;
                } else {
                    // Select a random subset
                    for "_i" from 1 to _maxLinesToProcess do {
                        private _randomMarker = selectRandom _frontlineMarkers;
                        _markersToProcess pushBack _randomMarker;
                        _frontlineMarkers = _frontlineMarkers - [_randomMarker];
                    };
                };
                
                // Process each selected marker
                {
                    ["DefenseLine", 3, format ["Processing marker: %1", _x]] call FLO_fnc_log;
                    
                    // Determine if we should create a new line or reinforce an existing one
                    private _taskForceMarkers = allMapMarkers select {
                        markerType _x isEqualTo "mil_triangle" && 
                        markerColor _x isEqualTo "ColorEAST" &&
                        markerAlpha _x isEqualTo 0.6 &&
                        getMarkerPos _x distance (getMarkerPos _x) < 1000
                    };
                    
                    if (count _taskForceMarkers > 0) then {
                        ["DefenseLine", 3, format ["Reinforcing existing defense line at %1", _x]] call FLO_fnc_log;
                        ["reinforceDefenseLine", [_x, _defenseStrength]] call FLO_fnc_TaskForceDefenseLine;
                    } else {
                        // Create new line
                        private _depth = switch (_defenseStrength) do {
                            case "light": {1};
                            case "medium": {2};
                            case "heavy": {3};
                            default {1};
                        };
                        
                        ["DefenseLine", 3, format ["Creating new defense line at %1 with depth %2", _x, _depth]] call FLO_fnc_log;
                        ["createDefenseLine", [_x, _depth, _defenseStrength]] call FLO_fnc_TaskForceDefenseLine;
                    };
                } forEach _markersToProcess;
            } else {
                ["Resources", 2, format ["Insufficient resources for defense lines (have: %1, needed: 25)", _currentResources]] call FLO_fnc_log;
            };
        } else {
            ["DefenseLine", 2, "No frontline markers found to process"] call FLO_fnc_log;
        };
        
        ["DefenseLine", 4, "Defense line update cycle complete"] call FLO_fnc_log;
        // Wait before next cycle
        sleep 600; // 10 minutes
    };
};