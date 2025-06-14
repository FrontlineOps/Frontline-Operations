if (!isServer) exitWith {};

Centerposition = [worldSize / 2, worldsize / 2, 0];

["LOADING . . . "] remoteExec ["hint", 0];

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
            (typeOf _x isEqualTo F_Truck_Respawn_List || typeOf _x isEqualTo F_Heli_Respawn_List) && 
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
_MOBSER = nearestobjects [Centerposition, [F_Truck_Construction_List], 40000];
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
_MOBARS = nearestobjects [Centerposition, [F_Truck_Ammo_List], 40000];
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

// Notify mission startup completion
["Mission StartUp", 3, "Mission StartUp Initialized Successfully ..."] call FLO_fnc_log;