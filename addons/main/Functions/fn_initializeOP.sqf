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
if (isNil { _opBuilding getVariable "FLO_BaseSide" }) then {
    _opBuilding setVariable ["FLO_BaseSide", FLO_ActivePlayerSide, true];
};
_opBuilding setVariable ["FLO_BaseType", "COP", true];

// ============================================================================
// CONFIGURATION
// ============================================================================

// OP-specific configuration
private _config = createHashMapFromArray [
    ["type", "COP"],
    ["markerText", "COP"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "opMarkerName"],
    ["initVariable", "FLO_OP_Initialized"],
    ["restoreVariable", "FLO_OP_MarkersRestored"],
    ["resourceTriggerArea", [3, 3, 0, false, 7]],
    ["resourceSearchRadius", 3],
    ["resourceSearchRadiusLarge", 10],
    ["holdoutTime", 600], // 10 minutes
    ["holdoutRadius", 100],
    ["cleanupRadius", 300]
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
        private _activeSide = FLO_ActivePlayerSide;
        private _respawnKey = ["west", "east"] select (_activeSide isEqualTo east);
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
            _marker setMarkerTypeLocal "b_installation";
            _marker setMarkerColorLocal "ColorYellow";
            _marker setMarkerTextLocal (_config get "markerText");
            _marker setMarkerSize (_config get "markerSize");
            [_type, 3, format["Created new %1 marker %2", _type, _markerName]] call FLO_fnc_log;
        };
    };

    _markerName
};

private _markerName = [_opBuilding, _config, _preserveMarker] call _fnc_createMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// ============================================================================
// ACTIONS SETUP
// ============================================================================

private _fnc_addActions = {
    params ["_building", "_config"];

    private _type = _config get "type";
    
    private _actions = [
        // Build Mode Action
        [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
            { [player] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ],
        // Store Action
        [
            "<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>STORE",
            { params ["_target"]; [_target] call FLO_fnc_storeOpenDialog; }, nil, 99999, true, true, "", "_this distance _target < 40"
        ]
    ];

    // Add all actions with error handling
    try {
        [_building, "OP_MAIN", _actions] remoteExec [
            "FLO_fnc_configureObjectActionsLocal",
            0,
            format ["FLO_OBJ_ACT_%1_OP_MAIN", netId _building]
        ];
    } catch {
        [_type, 1, format["Failed to configure main actions: %1", _exception]] call FLO_fnc_log;
    };

    [_type, 3, format["Added %1 actions to %2", count _actions, _type]] call FLO_fnc_log;
};

// Add container/screen actions (similar to FOB)
private _fnc_addContainerActions = {
    params ["_building", "_config"];

    private _type = _config get "type";
    private _containerType = if (!isNil "FLO_FactionCopTerminalType") then { FLO_FactionCopTerminalType } else { "Land_TripodScreen_01_dual_v2_sand_F" };

    // Find nearby OP container/screen
    private _containers = nearestObjects [_building, [_containerType], 10];
    if (_containers isEqualTo []) exitWith {
        [_type, 2, "No OP container found nearby for actions"] call FLO_fnc_log;
    };

    private _container = _containers select 0;

    // Container actions for COP support panels.
    private _containerActions = [
        // Store on container as well
        [
            "<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>STORE",
            { params ["_target"]; [_target] call FLO_fnc_storeOpenDialog; }, nil, 99999, true, true, "", "_this distance _target < 40"
        ],
        // Build Mode
        [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
            { [player] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ]
    ];

    try {
        [_container, "OP_CONTAINER", _containerActions] remoteExec [
            "FLO_fnc_configureObjectActionsLocal",
            0,
            format ["FLO_OBJ_ACT_%1_OP_CONTAINER", netId _container]
        ];
    } catch {
        [_type, 1, format["Failed to configure container actions: %1", _exception]] call FLO_fnc_log;
    };

    [_type, 3, format["Added %1 actions to OP container", count _containerActions]] call FLO_fnc_log;
};

// Execute setup functions
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
            "((thisTrigger nearEntities [['Man'], 5]) select {(alive _x) && {side _x isEqualTo civilian}}) isNotEqualTo []",
            "
            private _civilian = (nearestObjects [thisTrigger, ['Man'], 7] select {(alive _x) && ((side _x) isEqualTo civilian)}) param [0, objNull];

            if (!isNull _civilian) then {
                if (_civilian getUnitTrait 'engineer') then {
                    [50, ""INSURGENT""] call FLO_fnc_sendRewardNotification;
                    [50] call FLO_fnc_addReward;
                    private _reportSide = missionNamespace getVariable ['FLO_ActivePlayerSide', west];
                    if !(_reportSide in [east, west]) then { _reportSide = west; };
                    [_civilian, _reportSide] call FLO_fnc_gtnAlertCivilianReport;
                    deleteVehicle _civilian;
                    [0.35, 'increase'] call FLO_fnc_adjustReputation;
                } else {
                    [0, ""CIVILIAN""] call FLO_fnc_sendRewardNotification;
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
            format["(nearestObjects [thisTrigger, ['CargoNet_01_box_F'], %1]) isNotEqualTo []", _searchRadius],
            format["
                private _resource = (nearestObjects [thisTrigger, ['CargoNet_01_box_F'], %1]) param [0, objNull];
                if (!isNull _resource) then {
                    deleteVehicle _resource;
                    [100, ""RESOURCE""] call FLO_fnc_sendRewardNotification;
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
            [[FLO_FactionCopType], 1000],
            [[FLO_FactionCopTerminalType], 1000]
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
            // Dedicated-safe unit counting: nearEntities + player fallback.
            private _opPos = getPosATL _op;
            private _nearUnits = _op nearEntities [["Man", "LandVehicle"], _areaRadius];
            private _bluforCount = 0;
            private _opforCount = 0;

            {
                if (!alive _x) then { continue };
                if ((_x distance2D _opPos) > _areaRadius) then { continue };

                private _uSide = side _x;
                if (isPlayer _x) then {
                    _uSide = side group _x;
                };

                if (_uSide isEqualTo west) then { _bluforCount = _bluforCount + 1 };
                if (_uSide isEqualTo east) then { _opforCount = _opforCount + 1 };
            } forEach _nearUnits;

            {
                if (!alive _x) then { continue };
                if ((_x distance2D _opPos) > _areaRadius) then { continue };
                if (_x in _nearUnits) then { continue };

                private _pSide = side group _x;
                if (_pSide isEqualTo west) then { _bluforCount = _bluforCount + 1 };
                if (_pSide isEqualTo east) then { _opforCount = _opforCount + 1 };
            } forEach allPlayers;

            if (_opforCount > _bluforCount && _opforCount > 0) then {
                // Create status marker if needed
                if (isNil "_statusMarker") then {
                    _statusMarker = createMarker [format["OP_Status_%1", random 1000], getPos _op];
                    _statusMarker setMarkerTypeLocal "mil_objective";
                    _statusMarker setMarkerColorLocal "ColorRed";
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
                    _statusMarker setMarkerTextLocal "OP LOST!";
                    _statusMarker setMarkerColor "ColorBlack";

                    "OP has fallen to enemy forces!" remoteExec ["hint", -2];
                    ["OP", 1, "OP lost due to prolonged siege"] call FLO_fnc_log;

                    // Execute destruction sequence
                    private _cleanupRadius = _config get "cleanupRadius";
                    private _objectsToDestroy = [
                        [FLO_FactionCopTerminalType]
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
