if (!isServer) exitWith {};

Centerposition = [worldSize / 2, worldsize / 2, 0];

["LOADING . . . "] remoteExec ["hint", 0];
///////// Init Weather //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _Fog_Int = selectRandom [0, 0, 0.05, 0.05, 0.1, 0.1, 0.1, 0.2, 0.2, 0.3, 0.4, 0.5] ;
private _Fog_Dec = selectRandom [0.01, 0.01, 0.01, 0.02, 0.03,  0.05, 0.05, 0.1, 0.1] ;
private _OverC_Int = selectRandom [ 0.1, 0.1, 0.1, 0.3,  0.3,  0.3,  0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1, 1] ;

private _Fog_Alt = 0 ;

if (_OverC_Int >= 0.6) then {
    0 setFog [_Fog_Int, _Fog_Dec, _Fog_Alt];
} else {
    0 setFog [0, _Fog_Dec, _Fog_Alt];
};

0 setOvercast _OverC_Int;

forceWeatherChange;

["Weather", 3, "Weather Initialized Successfully ..."] call FLO_fnc_log;

///////// Init FOBs //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Initialize FOB objects
// Find all FOB buildings of type F_HQ_01
private _fobBuildings = nearestObjects [Centerposition, [F_HQ_01], 40000];
FOBB = _fobBuildings;

// Initialize FOBs with centralized function
{
    private _nearbyContainers = nearestObjects [_x, [F_HQ_C_01], 20];
    if (count _nearbyContainers > 0) then {
        [_x] call FLO_fnc_initializeFOB;
    };
} forEach _fobBuildings;

// Find additional FOB building types
FOBB = nearestObjects [Centerposition, ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"], 40000];

{ 
    if (count (nearestObjects [_x, [F_HQ_C_01], 20]) > 0) then { 
        [_x] call FLO_fnc_initializeFOB;
    }
} foreach FOBB;

["FOB", 3, "F.O.Bs Initialized Successfully ..."] call FLO_fnc_log;

///////// Init OPs //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_FOBB = nearestObjects [Centerposition, [F_OP_01], 40000];

{ 
    if (count (nearestObjects [_x, [F_OP_C_01], 6]) > 0) then {  
        [_x] call FLO_fnc_initializeOP;
    }
} foreach _FOBB;


// Initialize FOB Screen Actions
_FOBT = nearestObjects [Centerposition, [F_HQ_C_01], 40000];
{
    [_x, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Skip_Time",
        {
            createDialog 'C_LOCK';
        },
        nil,
        4,
        true,
        true,
        "",
        "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer)) || ((player isEqualTo TheCommander) && (isServer))"
    ]] remoteExec ["addAction", 0, true];

    [_x, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Change_Weather",
        {
            { null = execVM "Scripts\Init\init_Weather.sqf" ;} remoteExec ["call", 2];
        },
        nil,
        4,
        true,
        true,
        "",
        "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer)) || ((player isEqualTo TheCommander) && (isServer))"
    ]] remoteExec ["addAction", 0, true];

    [_x, [
        "<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>SAVE Mission Progress",
        {
            remoteExec ["FLO_fnc_MissionSave", 2];
        },
        nil,
        6,
        true,
        true,
        "",
        "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer)) || ((player isEqualTo TheCommander) && (isServer))"
    ]] remoteExec ["addAction", 0, true];

    [_x, [
        "<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>RESET Mission Progress",
        {
            { null = execVM "Scripts\MissionReset.sqf" } remoteExec ["call", 2];
        },
        nil,
        5,
        true,
        true,
        "",
        "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer)) || ((player isEqualTo TheCommander) && (isServer))"
    ]] remoteExec ["addAction", 0, true];

    [_x, [
        "<img size=2 color='#59ff58' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#59ff58'>Bribe_Militia_(200)",
        {
            [] execVM "Scripts\BRIBE.sqf";
        },
        nil,
        3,
        true,
        true,
        "",
        "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer)) || ((player isEqualTo TheCommander) && (isServer))"
    ]] remoteExec ["addAction", 0, true];

    [_x, [
        "<img size=2 color='#FF0000' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FF0000'>Create Custom Mission",
        {
            execVM "Scripts\Mission_Select_Action.sqf";
        },
        nil,
        1.5,
        true,
        true,
        "",
        "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer)) || ((player isEqualTo TheCommander) && (isServer))"
    ]] remoteExec ["addAction", 0, true];
} foreach _FOBT;
 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_FOBC = nearestObjects [Centerposition, ["B_Slingload_01_Cargo_F"], 40000];
{
    [_x, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack FOB",
        "Scripts\PObjectives\FOBUNPACK.sqf",
        nil,
        0,
        true,
        true,
        "",
        "true", // _target, _this, _originalTarget
        40,
        false,
        "",
        ""
    ]] remoteExec ["addAction", 0, true];

    _x setVariable ["IDS_Logistics_isPlacedEntity", true, true];

    [_x, [
        "<t font='PuristaBold' color='#FF0000' size='1.15'>Move FOB</t>", 
        { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, 
        nil, 
        1.4, 
        false, 
        true, 
        "", 
        "!IDS_Logistics_isHolding"
    ]] remoteExec ["addAction", 0, true];
} foreach _FOBC;
 
_FOBC = nearestObjects [Centerposition, ["B_Slingload_01_Repair_F"], 40000];
{
    [_x, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
        "Scripts\PObjectives\OPUNPACK.sqf",
        nil,
        0,
        true,
        true,
        "",
        "true", // _target, _this, _originalTarget
        40,
        false,
        "",
        ""
    ]] remoteExec ["addAction", 0, true];

    _x setVariable ["IDS_Logistics_isPlacedEntity", true, true];

    [_x, [
        "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>", 
        { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, 
        nil, 
        1.4, 
        false, 
        true, 
        "", 
        "!IDS_Logistics_isHolding"
    ]] remoteExec ["addAction", 0, true];
} foreach _FOBC;

//////////// Vehicles Crew Management /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

ALLFACVEHs = nearestobjects [Centerposition,[
    "B_SAM_System_01_F",
    "B_AAA_System_01_F",
    "B_SAM_System_02_F",
    "B_SAM_System_03_F",
    "B_GMG_01_A_F",
    "B_HMG_01_A_F",
    "B_W_Static_Designator_01_F",
    "B_UGV_02_Demining_F",
    "B_UAV_02_lxWS",
    "B_UAV_01_F",
    "B_SDV_01_F",
    "USAF_A10",
    "USAF_F22",
    "USAF_F22_Heavy",
    "USAF_F35A_STEALTH",
    "USAF_F35A",
    "USAF_AC130U",
    "USAF_C130J",
    "USAF_C130J_Cargo",
    "usaf_kc135",
    "USAF_C17",
    F_RADAR,
    F_ABT_01,
    F_UAV_01,
    F_UAV_02,
    F_UAV_03,
    F_UGV_01,
    F_turret_01,
    F_turret_02,
    F_turret_03,
    F_Car_01,
    F_Car_02,
    F_Car_03,
    F_Car_04,
    F_Car_05,
    F_Car_06,
    F_MRAP_01,
    F_MRAP_02,
    F_MRAP_03,
    F_MRAP_04,
    F_MRAP_05,
    F_MRAP_06,
    F_Truck_01,
    F_Truck_02,
    F_Truck_03,
    F_Truck_04,
    F_Truck_05,
    F_Truck_06,
    F_APC_01,
    F_APC_02,
    F_APC_03,
    F_APC_04,
    F_APC_05,
    F_APC_06,
    F_TNK_01,
    F_TNK_02,
    F_TNK_03,
    F_TNK_04,
    F_Art_00,
    F_Art_01,
    F_Art_02,
    F_Heli_01,
    F_Heli_02,
    F_Heli_03,
    F_Heli_04,
    F_Heli_05,
    F_Heli_06_G,
    F_Heli_07_G,
    F_Plane_01_CAS,
    F_Plane_02_CAS,
    F_Plane_03,
    F_Plane_04,
    F_Plane_05,
    F_Plane_06
],40000] ;

_EXCVEH = vehicles - ALLFACVEHs;

{
    deleteVehicleCrew _x; 
} foreach _EXCVEH;  

////////////////Support Stations/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[] spawn {  
    while { true } do {  
        _MOBRESMarks = allMapMarkers select {
            markerType _x isEqualTo "b_unknown" && 
            markerColor _x isEqualTo "ColorYellow" && 
            markerAlpha _x isEqualTo 0.7
        };
        
        {deleteMarker _x} forEach _MOBRESMarks;
        
        _MOBRESVeh = vehicles select {
            (typeOf _x isEqualTo F_Truck_05 || typeOf _x isEqualTo F_Heli_04) && 
            alive _x
        };	
        
        {
            _markerName = "respawn_west" + (str (getPos _x));  
            _mrkr = createMarkerLocal [_markerName, getPos _x];  
            _mrkr setMarkerTypeLocal "b_unknown";
            _mrkr setMarkerColorLocal "ColorYellow";
            _mrkr setMarkerSizeLocal [1, 1]; 
            _mrkr setMarkerAlpha 0.7; 
        } foreach _MOBRESVeh;
        
        sleep 5;  
    };  
};

// Initialize mobile service stations
_MOBSER = nearestobjects [Centerposition, [F_Truck_04], 40000];
{
    if (!isNil "_x" && {!isNull _x}) then {
        [_x, [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode", 
            { [player] call IDS_Logistics_fnc_initBuildCamera; }, 
            nil, 
            1.4, 
            false, 
            true, 
            "", 
            "!IDS_Logistics_isHolding"
        ]] remoteExec ["addAction", 0, true];
    };
} forEach _MOBSER;

// Initialize mobile arsenal stations
_MOBARS = nearestobjects [Centerposition, [F_Truck_03], 40000];
{
    [_x, [
        "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
        {
            if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") isEqualTo true) then {
                [player, player, true] call ace_arsenal_fnc_openBox;
            } else {
                ["Open", true] spawn BIS_fnc_arsenal;
            };
        },
        nil,
        1,
        true,
        true,
        "",
        "_this distance _target < 10"
    ]] remoteExec ["addAction", 0, true];
} forEach _MOBARS;

["Support Stations", 3, "Support Stations Initialized Successfully ..."] call FLO_fnc_log;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Set MRZR texture to olive mud if using woodland theme
_mrzrVehicles = nearestobjects [Centerposition, ["rhsusf_mrzr4_d"], 40000]; 
if (((markerText "Friendly_Handle" isEqualTo "United States Armed Forces _ Woodland _ CUP + RHS") || 
     (markerText "Friendly_Handle" isEqualTo "United States Armed Forces _ Woodland _ RHS")) && 
     (count _mrzrVehicles > 0)) then {
    {
        [_x, ["mud_olive", 1]] call BIS_fnc_initVehicle;
    } forEach _mrzrVehicles;
};

// Clean up map markers and invisible barriers
{
    _mapObjects = nearestObjects [Centerposition, [
        "Sign_Pointer_Blue_F", 
        "Land_InvisibleBarrier_F", 
        "LocationCityCapital_F", 
        "LocationCity_F", 
        "Sign_Pointer_Blue_F"
    ], 40000];
    
    {
        deleteVehicle _x;
    } forEach _mapObjects;
} remoteExec ["call", 0];

// Create crews for AA systems
_antiAirSystems = nearestObjects [Centerposition, [
    "O_Radar_System_02_F",
    "O_SAM_System_04_F",
    "vn_o_nva_navy_static_v11m", 
    "vn_o_pl_static_zpu4"
], 40000];

{
    createVehicleCrew _x;
} forEach _antiAirSystems;

// Notify mission startup completion
["Mission StartUp", 3, "Mission StartUp Initialized Successfully ..."] call FLO_fnc_log;