/*
 * Function: FLO_fnc_initializeFOB
 * Author: Frontline Operations Development Group
 * Description: FOB initialization
 *
 * Parameters:
 * 0: FOB Building <OBJECT> - The FOB building to initialize
 * 1: Preserve Marker <BOOL> - (Optional) Whether to preserve existing marker (default: false)
 *
 * Returns: <BOOL> - Success status
 *
 * Example:
 * [_building] call FLO_fnc_initializeFOB;
 * [_building, true] call FLO_fnc_initializeFOB;
 */

params [
    ["_fobBuilding", objNull, [objNull]],
    ["_preserveMarker", false, [false]]
];

// ============================================================================
// VALIDATION AND INITIALIZATION CHECK
// ============================================================================

if (isNull _fobBuilding) exitWith {
    ["FOB", 1, "Error: Null object passed to FOB initialization"] call FLO_fnc_log;
    false
};

// Check if FOB was already initialized
if (_fobBuilding getVariable ["FLO_FOB_Initialized", false]) exitWith {
    ["FOB", 3, format["FOB at %1 already initialized - skipping", getPos _fobBuilding]] call FLO_fnc_log;
    true
};

// Mark as initialized to prevent duplicate initialization
_fobBuilding setVariable ["FLO_FOB_Initialized", true, true];

// ============================================================================
// CONFIGURATION
// ============================================================================

// FOB-specific configuration
private _config = createHashMapFromArray [
    ["type", "FOB"],
    ["markerText", "FOB"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "fobMarkerName"],
    ["initVariable", "FLO_FOB_Initialized"],
    ["restoreVariable", "FLO_FOB_MarkersRestored"],
    ["packScript", "Scripts\PObjectives\FOBPACK.sqf"],
    ["requestScript", "Scripts\RequestMenu\Dialog_Request_FOB.sqf"],
    ["resourceTriggerArea", [3, 3, 0, false, 7]],
    ["resourceSearchRadius", 3],
    ["resourceSearchRadiusLarge", 10],
    ["holdoutTime", 900], // 15 minutes for FOB
    ["holdoutRadius", 150],
    ["cleanupRadius", 500],
    ["packCondition", "_this distance _target < 40"]
];

// ============================================================================
// SHARED FUNCTIONS (REUSED FROM OP)
// ============================================================================

private _fnc_createMarker = {
    params ["_building", "_config", "_preserveMarker"];

    private _markerVariable = _config get "markerVariable";
    private _restoreVariable = _config get "restoreVariable";
    private _type = _config get "type";

    private _markerName = "";

    if (_preserveMarker && {_building getVariable [_restoreVariable, false]}) then {
        // Use the existing marker name that was restored from save
        _markerName = _building getVariable [_markerVariable, ""];
        [_type, 3, format["Using restored %1 marker %2", _type, _markerName]] call FLO_fnc_log;
    } else {
        // Create a new marker
        private _activeSide = FLO_ActivePlayerSide;
        private _respawnKey = if (_activeSide isEqualTo east) then { "east" } else { "west" };
        private _relpos = _building getRelPos [12, 0];
        _markerName = format ["respawn_%1_%2", _respawnKey, str (getPosATL _building)];
        _building setVariable [_markerVariable, _markerName, true];

        // Check if marker already exists
        private _markerExists = _markerName in allMapMarkers;

        if (_markerExists) then {
            [_type, 3, format["Using existing %1 marker %2", _type, _markerName]] call FLO_fnc_log;
        } else {
            // Create new marker
            private _marker = createMarker [_markerName, _relpos];
            _marker setMarkerType "b_installation";
            _marker setMarkerColor "ColorYellow";
            _marker setMarkerText (_config get "markerText");
            _marker setMarkerSize (_config get "markerSize");
            [_type, 3, format["Created new %1 marker %2", _type, _markerName]] call FLO_fnc_log;
        };
    };

    _markerName
};

// ============================================================================
// MARKER CREATION
// ============================================================================

private _markerName = [_fobBuilding, _config, _preserveMarker] call _fnc_createMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// ============================================================================
// ARSENAL AND ACTIONS SETUP
// ============================================================================

private _fnc_setupArsenal = {
    params ["_building", "_config"];

    private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;
    
    // Check if we should restrict the arsenal
    if (_restrictedArsenal == 0) then {
        try {
            [_building] call FLO_fnc_restrictArsenalBox;
            [_config get "type", 3, "Arsenal restrictions applied"] call FLO_fnc_log;
        } catch {
            [_config get "type", 1, format["Failed to setup restricted arsenal: %1", _exception]] call FLO_fnc_log;
        };
    } else {
        // Unrestricted - initialize full arsenal
        try {
            if (isClass (configFile >> "ace_arsenal_loadoutsDisplay")) then {
                [_building, true] call ace_arsenal_fnc_initBox;
                [_building, true] call ace_arsenal_fnc_addVirtualItems;
            } else {
                ["AmmoboxInit", [_building, true]] call BIS_fnc_arsenal;
            };
            
            [_building] remoteExec ["FLO_fnc_addCratePurchaseActions", 0, true];
            [_config get "type", 3, "Arsenal unrestricted initialized"] call FLO_fnc_log;
        } catch {
            [_config get "type", 1, format["Failed to setup unrestricted arsenal: %1", _exception]] call FLO_fnc_log;
        };
    };
};

private _fnc_addActions = {
    params ["_building", "_config"];

    private _type = _config get "type";
    private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;
    
    private _actions = [
        // Build Mode Action
        [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
            { [player] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ],
        // Pack Action (FOB-specific with commander check)
        [
            format["<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Pack %1", _type],
            { execVM (_this select 3 get "packScript"); },
            _config, 2, true, true, "", "player isEqualTo TheCommander && _this distance _target < 40"
        ],
        // Request Menu Action (FOB uses different script)
        [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
            "Scripts\RequestMenu\Dialog_Request.sqf", nil, 99999, true, true, "", "", 40, false, "", ""
        ]
    ];
    
    // Always add Arsenal action
    _actions pushBack [
        "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
        {
            if (isClass (configFile >> "ace_arsenal_loadoutsDisplay")) then {
                [player, player, true] call ace_arsenal_fnc_openBox;
            } else {
                ["Open", true] spawn BIS_fnc_arsenal;
            };
        },
        nil, 1, true, true, "", "_this distance _target < 10"
    ];

    // Add all actions with error handling
    {
        try {
            [_building, _x] remoteExec ["addAction", 0, true];
        } catch {
            [_type, 1, format["Failed to add action %1: %2", _forEachIndex, _exception]] call FLO_fnc_log;
        };
    } forEach _actions;

    [_type, 3, format["Added %1 actions to %2", count _actions, _type]] call FLO_fnc_log;
};

// Add commander actions to the FOB container (screen/board)
private _fnc_addContainerActions = {
    params ["_building", "_config"];

    private _type = _config get "type";
    private _containerType = if (!isNil "F_HQ_C_01") then { F_HQ_C_01 } else { "Land_Cargo20_military_green_F" };

    // Find nearby FOB container
    private _containers = nearestObjects [_building, [_containerType], 25];
    if (count _containers == 0) exitWith {
        [_type, 2, "No FOB container found nearby for commander actions"] call FLO_fnc_log;
    };

    private _container = _containers select 0;
    private _commanderCondition = "player isEqualTo TheCommander";

    // Commander-only actions for the container/board
    private _containerActions = [
        ["<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Skip_Time", { createDialog 'C_LOCK'; }, nil, 4, true, true, "", _commanderCondition],
        ["<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Change_Weather", { { execVM "Scripts\Init\init_Weather.sqf"; } remoteExec ["call", 2]; }, nil, 4, true, true, "", _commanderCondition],
        ["<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>SAVE Mission Progress", { [] remoteExec ["FLO_fnc_MissionSave", 2]; }, nil, 6, true, true, "", _commanderCondition],
        ["<img size=2 color='#59ff58' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#59ff58'>Bribe_Militia_(200)", { execVM "Scripts\BRIBE.sqf"; }, nil, 3, true, true, "", _commanderCondition]
    ];

    {
        try {
            [_container, _x] remoteExec ["addAction", 0, true];
        } catch {
            [_type, 1, format["Failed to add container action %1: %2", _forEachIndex, _exception]] call FLO_fnc_log;
        };
    } forEach _containerActions;

    [_type, 3, format["Added %1 commander actions to container", count _containerActions]] call FLO_fnc_log;
};

// Execute setup functions
[_fobBuilding, _config] call _fnc_setupArsenal;
[_fobBuilding, _config] call _fnc_addActions;
[_fobBuilding, _config] call _fnc_addContainerActions;

// ============================================================================
// TRIGGER SETUP
// ============================================================================

private _fnc_createTriggers = {
    params ["_building", "_config"];

    private _type = _config get "type";
    private _triggers = [];

    try {
        // Civilian Handling Trigger
        private _civTrigger = createTrigger ["EmptyDetector", getPos _building];
        _civTrigger setTriggerArea [5, 5, 0, false, 7];
        _civTrigger setTriggerTimeout [3, 3, 3, true];
        _civTrigger setTriggerActivation ["NONE", "PRESENT", true];
        _civTrigger setTriggerStatements [
            "{(alive _x) && (side _x isEqualTo civilian)} count (thisTrigger nearEntities [['Man'], 5]) > 0",
            "
            private _civilian = (nearestObjects [thisTrigger, ['Man'], 7] select {(alive _x) && ((side _x) isEqualTo civilian)}) param [0, objNull];

            if (!isNull _civilian) then {
                if (_civilian getUnitTrait 'engineer') then {
                    [50, 'STR_FLO_INSURGENT'] call FLO_fnc_sendRewardNotification;
                    [50] call FLO_fnc_addReward;
                    deleteVehicle _civilian;
                    [] call FLO_fnc_civilianIntel;
                    [0.35, 'increase'] call FLO_fnc_adjustReputation;
                } else {
                    [0, 'STR_FLO_CIVILIAN'] call FLO_fnc_sendRewardNotification;
                    deleteVehicle _civilian;
                    [-0.35, 'decrease'] call FLO_fnc_adjustReputation;
                };
            };
            ", ""
        ];
        _civTrigger attachTo [_building, [0, 0, 0]];
        _triggers pushBack _civTrigger;

        // Resource Trigger (FOB uses larger area)
        private _resourceArea = [5, 5, 0, false, 7]; // FOB has larger resource area
        private _searchRadius = 4; // FOB-specific search radius
        private _searchRadiusLarge = 10;

        private _resTrigger = createTrigger ["EmptyDetector", getPos _building];
        _resTrigger setTriggerArea _resourceArea;
        _resTrigger setTriggerTimeout [3, 3, 3, true];
        _resTrigger setTriggerActivation ["NONE", "PRESENT", true];
        _resTrigger setTriggerStatements [
            format["count (nearestObjects [thisTrigger, ['CargoNet_01_box_F'], %1]) > 0", _searchRadius],
            format["
                private _resource = (nearestObjects [thisTrigger, ['CargoNet_01_box_F'], %1]) param [0, objNull];
                if (!isNull _resource) then {
                    deleteVehicle _resource;
                    [100, 'STR_FLO_RESOURCE'] call FLO_fnc_sendRewardNotification;
                    [100] call FLO_fnc_addReward;
                };
            ", _searchRadiusLarge], ""
        ];
        _resTrigger attachTo [_building, [0, 0, 0]];
        _triggers pushBack _resTrigger;

        [_type, 3, format["Created %1 triggers", count _triggers]] call FLO_fnc_log;

    } catch {
        [_type, 1, format["Failed to create triggers: %1", _exception]] call FLO_fnc_log;
    };

    _triggers
};

private _triggers = [_fobBuilding, _config] call _fnc_createTriggers;

// ============================================================================
// EVENT HANDLERS
// ============================================================================

// Building destruction handler
_fobBuilding addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];

    try {
        [playerSide, 'HQ'] commandChat 'All Forces Fall Back. We Lost the FOB...';

        // Clean up related objects
        private _cleanupObjects = [
            [['B_Slingload_01_Cargo_F'], 1000],
            [[F_HQ_01], 1000],
            [[F_HQ_C_01], 1000]
        ];

        {
            _x params ["_types", "_radius"];
            private _objects = nearestObjects [_unit, _types, _radius];
            {
                if (!isNull _x) then {
                    if (_x isKindOf "Building") then {
                        _x setDamage 1;
                    } else {
                        deleteVehicle _x;
                    };
                };
            } forEach _objects;
        } forEach _cleanupObjects;

        // Clean up marker
        private _markerName = _unit getVariable ["fobMarkerName", ""];
        if (_markerName != "") then {
            deleteMarker _markerName;
        };

        // Clean up triggers
        private _allTriggers = allMissionObjects "EmptyDetector";
        private _nearbyTriggers = _allTriggers select {position _x distance _unit < 20};
        {deleteVehicle _x} forEach _nearbyTriggers;

        ["FOB", 2, format["FOB destroyed at %1", getPos _unit]] call FLO_fnc_log;

    } catch {
        ["FOB", 1, format["Error in FOB destruction handler: %1", _exception]] call FLO_fnc_log;
    };
}];

// ============================================================================
// SIEGE MONITORING SYSTEM
// ============================================================================

// Siege monitoring
[_fobBuilding, _config] spawn {
    params ["_fob", "_config"];

    private _holdoutTime = 0;
    private _maxHoldTime = _config get "holdoutTime"; // From config (900 seconds for FOB)
    private _checkInterval = 5; 
    private _areaRadius = _config get "holdoutRadius"; // From config (150m for FOB)
    private _statusMarker = nil;
    private _lastNotification = 0;
    private _notificationInterval = 60; // Notify every minute

    ["FOB", 3, "Siege monitoring started"] call FLO_fnc_log;

    while {alive _fob} do {
        try {
            // Optimized unit counting using nearEntities
            private _nearUnits = _fob nearEntities [["Man", "LandVehicle"], _areaRadius];
            private _bluforCount = {alive _x && side _x isEqualTo west} count _nearUnits;
            private _opforCount = {alive _x && side _x isEqualTo east} count _nearUnits;

            if (_opforCount > _bluforCount && _opforCount > 0) then {
                // Create status marker if needed
                if (isNil "_statusMarker") then {
                    _statusMarker = createMarker [format["FOB_Status_%1", random 1000], getPos _fob];
                    _statusMarker setMarkerType "mil_objective";
                    _statusMarker setMarkerColor "ColorRed";
                    _statusMarker setMarkerSize [1.5, 1.5];
                    ["FOB", 2, "FOB siege started"] call FLO_fnc_log;
                };

                _holdoutTime = _holdoutTime + _checkInterval;
                private _timeLeft = _maxHoldTime - _holdoutTime;
                private _minutes = floor(_timeLeft / 60);
                private _seconds = _timeLeft % 60;

                // Update marker text with CBA formatting
                _statusMarker setMarkerText format["FOB UNDER SIEGE: %1:%2", _minutes, [_seconds, 2] call CBA_fnc_formatNumber];

                // Periodic notifications
                if (time - _lastNotification > _notificationInterval) then {
                    [format["FOB under siege! %1 minutes remaining", ceil(_timeLeft / 60)]] remoteExec ["hint", -2];
                    _lastNotification = time;
                };

                // Check if siege time exceeded
                if (_holdoutTime >= _maxHoldTime) exitWith {
                    _statusMarker setMarkerText "FOB LOST!";
                    _statusMarker setMarkerColor "ColorBlack";

                    "FOB has fallen to enemy forces!" remoteExec ["hint", -2];
                    ["FOB", 1, "FOB lost due to prolonged siege"] call FLO_fnc_log;

                    // Execute destruction sequence
                    private _cleanupRadius = _config get "cleanupRadius";
                    private _objectsToDestroy = [
                        ['B_Slingload_01_Cargo_F'],
                        [F_HQ_C_01]
                    ];

                    {
                        private _objects = nearestObjects [_fob, _x, _cleanupRadius];
                        {
                            if (!isNull _x) then { deleteVehicle _x };
                        } forEach _objects;
                    } forEach _objectsToDestroy;

                    // Destroy the FOB itself
                    if (!isNull _fob) then { _fob setDamage 1 };

                    // Clean up marker and triggers
                    private _markerName = _fob getVariable ["fobMarkerName", ""];
                    if (_markerName != "") then { deleteMarker _markerName };

                    deleteMarker _statusMarker;

                    // Cleanup nearby triggers
                    private _allTriggers = allMissionObjects "EmptyDetector";
                    private _nearbyTriggers = _allTriggers select { position _x distance _fob < _cleanupRadius };
                    { deleteVehicle _x } forEach _nearbyTriggers;
                };
            } else {
                // Siege ended - cleanup status marker
                if (!isNil "_statusMarker") then {
                    deleteMarker _statusMarker;
                    _statusMarker = nil;
                    if (_holdoutTime > 0) then {
                        "FOB defense successful! Timer reset." remoteExec ["hint", -2];
                        ["FOB", 3, "FOB siege successfully defended"] call FLO_fnc_log;
                    };
                };
                _holdoutTime = 0;
            };

        } catch {
            ["FOB", 1, format["Error in siege monitoring: %1", _exception]] call FLO_fnc_log;
        };

        sleep _checkInterval;
    };

    // Cleanup on FOB destruction
    if (!isNil "_statusMarker") then {
        deleteMarker _statusMarker;
    };

    ["FOB", 3, "Siege monitoring ended"] call FLO_fnc_log;
};

// ============================================================================
// COMPLETION
// ============================================================================

// Final notifications
[playerSide, "HQ"] commandChat "FOB Deployed";
["FOB", 3, format["FOB initialization completed successfully at %1", getPos _fobBuilding]] call FLO_fnc_log;

true
