/*
 * Function: FLO_fnc_MissionStartup
 * Author: Frontline Operations Development Group
 * Description:
 * Initializes FOBs, OPs, and support systems
*/

if (!isServer) exitWith {};

// Constants
private _worldCenter = [worldSize / 2, worldSize / 2, 0];
private _searchRadius = worldSize * 0.7;

["LOADING . . . "] remoteExec ["hint", 0];

// Initialize FOBs
private _fnc_initializeFOBs = {
    ["STARTUP", 3, "Initializing FOBs..."] call FLO_fnc_log;

    // Collect all FOB building types
    private _fobTypes = [F_HQ_01, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"];
    private _allFobBuildings = [];

    {
        private _buildings = nearestObjects [_worldCenter, [_x], _searchRadius];
        _allFobBuildings append _buildings;
    } forEach _fobTypes;

    // Remove duplicates and store globally
    FOBB = _allFobBuildings arrayIntersect _allFobBuildings;

    // Initialize FOBs that have containers nearby
    private _initializedCount = 0;
    {
        private _nearbyContainers = nearestObjects [_x, [F_HQ_C_01], 20];
        if (count _nearbyContainers > 0) then {
            [_x] call FLO_fnc_initializeFOB;
            _initializedCount = _initializedCount + 1;
        };
    } forEach FOBB;

    ["STARTUP", 3, format["Initialized %1 FOBs successfully", _initializedCount]] call FLO_fnc_log;
};

call _fnc_initializeFOBs;

// Initialize OPs
private _fnc_initializeOPs = {
    ["STARTUP", 3, "Initializing OPs..."] call FLO_fnc_log;

    private _opBuildings = nearestObjects [_worldCenter, [F_OP_01], _searchRadius];
    private _initializedCount = 0;

    {
        private _nearbyContainers = nearestObjects [_x, [F_OP_C_01], 6];
        if (count _nearbyContainers > 0) then {
            [_x] call FLO_fnc_initializeOP;
            _initializedCount = _initializedCount + 1;
        };
    } forEach _opBuildings;

    ["STARTUP", 3, format["Initialized %1 OPs successfully", _initializedCount]] call FLO_fnc_log;
};

call _fnc_initializeOPs;


// Initialize FOB Screen Actions
private _fnc_initializeFOBActions = {
    ["STARTUP", 3, "Initializing FOB screen actions..."] call FLO_fnc_log;

    private _fobContainers = nearestObjects [_worldCenter, [F_HQ_C_01], _searchRadius];
    private _commanderCondition = "((player isEqualTo TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player isEqualTo TheCommander) && (isServer))";

    // Define FOB actions
    private _fobActions = [
        ["<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Skip_Time", {createDialog 'C_LOCK';}, 4],
        ["<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Change_Weather", {{ null = execVM "Scripts\Init\init_Weather.sqf" ;} remoteExec ["call", 2];}, 4],
        ["<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>SAVE Mission Progress", {remoteExec ["FLO_fnc_MissionSave", 2];}, 6],
        ["<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>RESET Mission Progress", {{ null = execVM "Scripts\MissionReset.sqf" } remoteExec ["call", 2];}, 5],
        ["<img size=2 color='#59ff58' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#59ff58'>Bribe_Militia_(200)", {[] execVM "Scripts\BRIBE.sqf";}, 3]
    ];

    // Add actions to all FOB containers
    {
        private _container = _x;
        {
            _x params ["_title", "_script", "_priority"];
            [_container, [_title, _script, nil, _priority, true, true, "", _commanderCondition]] remoteExec ["addAction", 0, true];
        } forEach _fobActions;
    } forEach _fobContainers;

    ["STARTUP", 3, format["Added FOB actions to %1 containers", count _fobContainers]] call FLO_fnc_log;
};

call _fnc_initializeFOBActions;
 

// Initialize deployable FOB/OP containers
private _fnc_initializeDeployables = {
    ["STARTUP", 3, "Initializing deployable containers..."] call FLO_fnc_log;

    // FOB containers
    private _fobContainers = nearestObjects [_worldCenter, ["B_Slingload_01_Cargo_F"], _searchRadius];
    {
        [_x, [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack FOB",
            "Scripts\PObjectives\FOBUNPACK.sqf",
            nil, 0, true, true, "", "true", 40, false, "", ""
        ]] remoteExec ["addAction", 0, true];

        _x setVariable ["IDS_Logistics_isPlacedEntity", true, true];

        [_x, [
            "<t font='PuristaBold' color='#FF0000' size='1.15'>Move FOB</t>",
            { [player, true] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ]] remoteExec ["addAction", 0, true];
    } forEach _fobContainers;

    // OP containers
    private _opContainers = nearestObjects [_worldCenter, ["B_Slingload_01_Repair_F"], _searchRadius];
    {
        [_x, [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
            "Scripts\PObjectives\OPUNPACK.sqf",
            nil, 0, true, true, "", "true", 40, false, "", ""
        ]] remoteExec ["addAction", 0, true];

        _x setVariable ["IDS_Logistics_isPlacedEntity", true, true];

        [_x, [
            "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>",
            { [player, true] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ]] remoteExec ["addAction", 0, true];
    } forEach _opContainers;

    ["STARTUP", 3, format["Initialized %1 FOB and %2 OP containers", count _fobContainers, count _opContainers]] call FLO_fnc_log;
};

call _fnc_initializeDeployables;

// Initialize mobile respawn marker system
private _fnc_initializeMobileRespawn = {
    ["STARTUP", 3, "Starting mobile respawn marker system..."] call FLO_fnc_log;

    [] spawn {
        private _respawnVehicleTypes = (F_Truck_Respawn_List + F_Heli_Respawn_List) apply {_x select 0};

        while {true} do {
            // Clean up old markers
            private _oldMarkers = allMapMarkers select {
                markerType _x isEqualTo "b_unknown" &&
                markerColor _x isEqualTo "ColorYellow" &&
                markerAlpha _x isEqualTo 0.7
            };
            {deleteMarker _x} forEach _oldMarkers;

            // Find active respawn vehicles
            private _respawnVehicles = vehicles select {
                (typeOf _x in _respawnVehicleTypes) && {alive _x}
            };

            // Create new markers
            {
                private _markerName = "respawn_west" + str(getPos _x);
                private _marker = createMarkerLocal [_markerName, getPos _x];
                _marker setMarkerTypeLocal "b_unknown";
                _marker setMarkerColorLocal "ColorYellow";
                _marker setMarkerSizeLocal [1, 1];
                _marker setMarkerAlpha 0.7;
            } forEach _respawnVehicles;

            sleep 5;
        };
    };
};

call _fnc_initializeMobileRespawn;

// Initialize mobile service stations
private _fnc_initializeMobileStations = {
    ["STARTUP", 3, "Initializing mobile service stations..."] call FLO_fnc_log;

    // Construction vehicles
    private _constructionVehicleTypes = F_Truck_Construction_List apply {_x select 0};
    private _constructionVehicles = nearestObjects [_worldCenter, _constructionVehicleTypes, _searchRadius];

    {
        if (!isNull _x) then {
            [_x, [
                "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
                { [player] call IDS_Logistics_fnc_initBuildCamera; },
                nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
            ]] remoteExec ["addAction", 0, true];
        };
    } forEach _constructionVehicles;

    // Arsenal vehicles
    private _arsenalVehicleTypes = F_Truck_Ammo_List apply {_x select 0};
    private _arsenalVehicles = nearestObjects [_worldCenter, _arsenalVehicleTypes, _searchRadius];

    {
        [_x, [
            "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
            {
                if (isClass (configFile >> "ace_arsenal_loadoutsDisplay")) then {
                    [player, player, true] call ace_arsenal_fnc_openBox;
                } else {
                    ["Open", true] spawn BIS_fnc_arsenal;
                };
            },
            nil, 1, true, true, "", "_this distance _target < 10"
        ]] remoteExec ["addAction", 0, true];
    } forEach _arsenalVehicles;

    ["STARTUP", 3, format["Initialized %1 construction and %2 arsenal vehicles", count _constructionVehicles, count _arsenalVehicles]] call FLO_fnc_log;
};

call _fnc_initializeMobileStations;

// Clean up map objects
private _fnc_cleanupMapObjects = {
    ["STARTUP", 3, "Cleaning up map objects..."] call FLO_fnc_log;

    private _cleanupTypes = [
        "Sign_Pointer_Blue_F",
        "Land_InvisibleBarrier_F",
        "LocationCityCapital_F",
        "LocationCity_F"
    ];

    private _objectsToDelete = nearestObjects [_worldCenter, _cleanupTypes, _searchRadius];

    // Delete objects on all clients
    {
        [_x] remoteExec ["deleteVehicle", 0];
    } forEach _objectsToDelete;

    ["STARTUP", 3, format["Cleaned up %1 map objects", count _objectsToDelete]] call FLO_fnc_log;
};

call _fnc_cleanupMapObjects;

// Mission startup completion
["STARTUP", 3, "Mission startup completed successfully"] call FLO_fnc_log;