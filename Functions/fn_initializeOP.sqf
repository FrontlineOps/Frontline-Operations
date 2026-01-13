/*
 * Function: FLO_fnc_initializeOP
 * Author: Frontline Operations Development Group
 * Description: OP initialization
 *
 * Parameters:
 * 0: OP Building <OBJECT> - The OP building to initialize
 * 1: Preserve Marker <BOOL> - (Optional) Whether to preserve existing marker (default: false)
 *
 * Returns: <BOOL> - Success status
 *
 * Example:
 * [_building] call FLO_fnc_initializeOP;
 * [_building, true] call FLO_fnc_initializeOP;
 */

params [
    ["_opBuilding", objNull, [objNull]],
    ["_preserveMarker", false, [false]]
];

// ============================================================================
// VALIDATION AND INITIALIZATION CHECK
// ============================================================================

if (isNull _opBuilding) exitWith {
    ["OP", 1, "Error: Null object passed to OP initialization"] call FLO_fnc_log;
    false
};

// Check if OP was already initialized
if (_opBuilding getVariable ["FLO_OP_Initialized", false]) exitWith {
    ["OP", 3, format["OP at %1 already initialized - skipping", getPos _opBuilding]] call FLO_fnc_log;
    true
};

// Mark as initialized to prevent duplicate initialization
_opBuilding setVariable ["FLO_OP_Initialized", true, true];

// ============================================================================
// CONFIGURATION
// ============================================================================

// OP-specific configuration
private _config = createHashMapFromArray [
    ["type", "OP"],
    ["markerText", "OP"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "opMarkerName"],
    ["initVariable", "FLO_OP_Initialized"],
    ["restoreVariable", "FLO_OP_MarkersRestored"],
    ["packScript", "Scripts\PObjectives\OPPACK.sqf"],
    ["requestScript", "Scripts\RequestMenu\Dialog_Request_OP.sqf"],
    ["resourceTriggerArea", [3, 3, 0, false, 7]],
    ["resourceSearchRadius", 3],
    ["resourceSearchRadiusLarge", 10],
    ["holdoutTime", 600], // 10 minutes
    ["holdoutRadius", 100],
    ["cleanupRadius", 300],
    ["packCondition", "_this distance _target < 40"]
];

// ============================================================================
// MARKER CREATION
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
        private _relpos = _building getRelPos [12, 0];
        _markerName = "respawn_west" + (str (getPos _building));
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

private _markerName = [_opBuilding, _config, _preserveMarker] call _fnc_createMarker;

// ============================================================================
// ARSENAL AND ACTIONS SETUP
// ============================================================================

private _fnc_setupArsenal = {
    params ["_building", "_config"];

    private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;
    
    // Check if we should restrict the arsenal (Param == 1)
    if (_restrictedArsenal == 1) then {
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
        // Pack Action
        [
            format["<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Pack %1", _type],
            { execVM (_this select 3 get "packScript"); },
            _config, 2, true, true, "", (_config get "packCondition")
        ],
        // Request Menu Action
        [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
            (_config get "requestScript"), nil, 99999, true, true, "", "", 40, false, "", ""
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

// Add container/screen actions (similar to FOB)
private _fnc_addContainerActions = {
    params ["_building", "_config"];

    private _type = _config get "type";
    private _containerType = if (!isNil "F_OP_C_01") then { F_OP_C_01 } else { "Land_TripodScreen_01_dual_v2_sand_F" };

    // Find nearby OP container/screen
    private _containers = nearestObjects [_building, [_containerType], 10];
    if (count _containers == 0) exitWith {
        [_type, 2, "No OP container found nearby for actions"] call FLO_fnc_log;
    };

    private _container = _containers select 0;

    // Container actions for OP (REQUEST MENU is primary for OPs)
    private _containerActions = [
        // Request Menu on container as well
        [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
            (_config get "requestScript"), nil, 99999, true, true, "", "", 40, false, "", ""
        ],
        // Build Mode
        [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
            { [player] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ]
    ];

    {
        try {
            [_container, _x] remoteExec ["addAction", 0, true];
        } catch {
            [_type, 1, format["Failed to add container action %1: %2", _forEachIndex, _exception]] call FLO_fnc_log;
        };
    } forEach _containerActions;

    [_type, 3, format["Added %1 actions to OP container", count _containerActions]] call FLO_fnc_log;
};

// Execute setup functions
[_opBuilding, _config] call _fnc_setupArsenal;
[_opBuilding, _config] call _fnc_addActions;
[_opBuilding, _config] call _fnc_addContainerActions;

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

        // Resource Trigger
        private _resourceArea = _config get "resourceTriggerArea";
        private _searchRadius = _config get "resourceSearchRadius";
        private _searchRadiusLarge = _config get "resourceSearchRadiusLarge";

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

private _triggers = [_opBuilding, _config] call _fnc_createTriggers;

// ============================================================================
// EVENT HANDLERS
// ============================================================================

// Building destruction handler
_opBuilding addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];

    try {
        [playerSide, 'HQ'] commandChat 'All Forces Fall Back. We Lost the OP...';

        // Clean up related objects efficiently
        private _cleanupObjects = [
            [['B_Slingload_01_Cargo_F'], 1000],
            [[F_OP_01], 1000],
            [[F_OP_C_01], 1000]
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
        private _markerName = _unit getVariable ["opMarkerName", ""];
        if (_markerName != "") then {
            deleteMarker _markerName;
        };

        // Clean up triggers efficiently
        private _allTriggers = allMissionObjects "EmptyDetector";
        private _nearbyTriggers = _allTriggers select {position _x distance _unit < 20};
        {deleteVehicle _x} forEach _nearbyTriggers;

        ["OP", 2, format["OP destroyed at %1", getPos _unit]] call FLO_fnc_log;

    } catch {
        ["OP", 1, format["Error in OP destruction handler: %1", _exception]] call FLO_fnc_log;
    };
}];

// ============================================================================
// SIEGE MONITORING SYSTEM
// ============================================================================

// Siege monitoring
[_opBuilding, _config] spawn {
    params ["_op", "_config"];

    private _holdoutTime = 0;
    private _maxHoldTime = _config get "holdoutTime"; // From config
    private _checkInterval = 5; 
    private _areaRadius = _config get "holdoutRadius"; // From config
    private _statusMarker = nil;
    private _lastNotification = 0;
    private _notificationInterval = 60; // Notify every minute

    ["OP", 3, "Siege monitoring started"] call FLO_fnc_log;

    while {alive _op} do {
        try {
            // Unit counting using nearEntities
            private _nearUnits = _op nearEntities [["Man", "LandVehicle"], _areaRadius];
            private _bluforCount = {alive _x && side _x isEqualTo west} count _nearUnits;
            private _opforCount = {alive _x && side _x isEqualTo east} count _nearUnits;

            if (_opforCount > _bluforCount && _opforCount > 0) then {
                // Create status marker if needed
                if (isNil "_statusMarker") then {
                    _statusMarker = createMarker [format["OP_Status_%1", random 1000], getPos _op];
                    _statusMarker setMarkerType "mil_objective";
                    _statusMarker setMarkerColor "ColorRed";
                    _statusMarker setMarkerSize [1.2, 1.2];
                    ["OP", 2, "OP siege started"] call FLO_fnc_log;
                };

                _holdoutTime = _holdoutTime + _checkInterval;
                private _timeLeft = _maxHoldTime - _holdoutTime;
                private _minutes = floor(_timeLeft / 60);
                private _seconds = _timeLeft % 60;

                // Update marker text with CBA formatting
                _statusMarker setMarkerText format["OP UNDER SIEGE: %1:%2", _minutes, [_seconds, 2] call CBA_fnc_formatNumber];

                // Periodic notifications
                if (time - _lastNotification > _notificationInterval) then {
                    [format["OP under siege! %1 minutes remaining", ceil(_timeLeft / 60)]] remoteExec ["hint", -2];
                    _lastNotification = time;
                };

                // Check if siege time exceeded
                if (_holdoutTime >= _maxHoldTime) exitWith {
                    _statusMarker setMarkerText "OP LOST!";
                    _statusMarker setMarkerColor "ColorBlack";

                    "OP has fallen to enemy forces!" remoteExec ["hint", -2];
                    ["OP", 1, "OP lost due to prolonged siege"] call FLO_fnc_log;

                    // Execute destruction sequence
                    private _cleanupRadius = _config get "cleanupRadius";
                    private _objectsToDestroy = [
                        ['B_Slingload_01_Cargo_F'],
                        [F_OP_C_01]
                    ];

                    {
                        private _objects = nearestObjects [_op, _x, _cleanupRadius];
                        {
                            if (!isNull _x) then { deleteVehicle _x };
                        } forEach _objects;
                    } forEach _objectsToDestroy;

                    // Destroy the OP itself
                    if (!isNull _op) then { _op setDamage 1 };

                    // Clean up marker and triggers
                    private _markerName = _op getVariable ["opMarkerName", ""];
                    if (_markerName != "") then { deleteMarker _markerName };

                    deleteMarker _statusMarker;

                    // Cleanup nearby triggers
                    private _allTriggers = allMissionObjects "EmptyDetector";
                    private _nearbyTriggers = _allTriggers select { position _x distance _op < _cleanupRadius };
                    { deleteVehicle _x } forEach _nearbyTriggers;
                };
            } else {
                // Siege ended - cleanup status marker
                if (!isNil "_statusMarker") then {
                    deleteMarker _statusMarker;
                    _statusMarker = nil;
                    if (_holdoutTime > 0) then {
                        "OP defense successful! Timer reset." remoteExec ["hint", -2];
                        ["OP", 3, "OP siege successfully defended"] call FLO_fnc_log;
                    };
                };
                _holdoutTime = 0;
            };

        } catch {
            ["OP", 1, format["Error in siege monitoring: %1", _exception]] call FLO_fnc_log;
        };

        sleep _checkInterval;
    };

    // Cleanup on OP destruction
    if (!isNil "_statusMarker") then {
        deleteMarker _statusMarker;
    };

    ["OP", 3, "Siege monitoring ended"] call FLO_fnc_log;
};

// ============================================================================
// COMPLETION
// ============================================================================

// Final notifications
[playerSide, "HQ"] commandChat "OP Deployed";
["OP", 3, format["OP initialization completed successfully at %1", getPos _opBuilding]] call FLO_fnc_log;

true