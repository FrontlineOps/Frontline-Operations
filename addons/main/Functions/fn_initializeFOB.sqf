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
    [_fobBuilding] call FLO_fnc_campaignRegisterBase;
    ["FOB", 3, format["FOB at %1 already initialized - skipping", getPos _fobBuilding]] call FLO_fnc_log;
    true
};

// Mark as initialized to prevent duplicate initialization
_fobBuilding setVariable ["FLO_FOB_Initialized", true, true];
if (isNil { _fobBuilding getVariable "FLO_BaseSide" }) then {
    _fobBuilding setVariable ["FLO_BaseSide", FLO_ActivePlayerSide, true];
};
_fobBuilding setVariable ["FLO_BaseType", "FOB", true];
[_fobBuilding] call FLO_fnc_campaignRegisterBase;

// ============================================================================
// CONFIGURATION
// ============================================================================

// FOB-specific configuration
private _config = createHashMapFromArray [
    ["type", "FOB"],
    ["actionPrefix", "FOB"],
    ["markerText", "FOB"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "fobMarkerName"],
    ["initVariable", "FLO_FOB_Initialized"],
    ["restoreVariable", "FLO_FOB_MarkersRestored"],
    ["containerTypeVariable", "FLO_FactionFobTerminalType"],
    ["containerFallbackType", "Land_Cargo20_military_green_F"],
    ["containerSearchRadius", 25],
    ["containerMissingLog", "No FOB container found nearby for commander actions"],
    ["resourceTriggerArea", [5, 5, 0, false, 7]],
    ["resourceSearchRadius", 4],
    ["resourceSearchRadiusLarge", 10],
    ["holdoutTime", 900], // 15 minutes for FOB
    ["holdoutRadius", 150],
    ["cleanupRadius", 500]
];

// ============================================================================
// MARKER CREATION
// ============================================================================

private _markerName = [_fobBuilding, _config, _preserveMarker] call FLO_fnc_baseCreateMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// ============================================================================
// ACTIONS SETUP
// ============================================================================

[_fobBuilding, _config] call FLO_fnc_baseConfigureMainActions;
[_fobBuilding, _config] call FLO_fnc_baseConfigureContainerActions;

// ============================================================================
// TRIGGER SETUP
// ============================================================================

private _triggers = [_fobBuilding, _config] call FLO_fnc_baseCreateTriggers;

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
            [[FLO_FactionFobType], 1000],
            [[FLO_FactionFobTerminalType], 1000]
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
            // Dedicated-safe unit counting: nearEntities + player fallback.
            private _fobPos = getPosATL _fob;
            private _nearUnits = _fob nearEntities [["Man", "LandVehicle"], _areaRadius];
            private _bluforCount = 0;
            private _opforCount = 0;

            {
                if (!alive _x) then { continue };
                if ((_x distance2D _fobPos) > _areaRadius) then { continue };

                private _uSide = side _x;
                if (isPlayer _x) then {
                    _uSide = side group _x;
                };

                if (_uSide isEqualTo west) then { _bluforCount = _bluforCount + 1 };
                if (_uSide isEqualTo east) then { _opforCount = _opforCount + 1 };
            } forEach _nearUnits;

            {
                if (!alive _x) then { continue };
                if ((_x distance2D _fobPos) > _areaRadius) then { continue };
                if (_x in _nearUnits) then { continue };

                private _pSide = side group _x;
                if (_pSide isEqualTo west) then { _bluforCount = _bluforCount + 1 };
                if (_pSide isEqualTo east) then { _opforCount = _opforCount + 1 };
            } forEach allPlayers;

            if (_opforCount > _bluforCount && _opforCount > 0) then {
                // Create status marker if needed
                if (isNil "_statusMarker") then {
                    _statusMarker = createMarker [format["FOB_Status_%1", random 1000], getPos _fob];
                    _statusMarker setMarkerTypeLocal "mil_objective";
                    _statusMarker setMarkerColorLocal "ColorRed";
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
                    [format ["FOB under siege! %1 minutes remaining", ceil (_timeLeft / 60)], "warning", false, 0] call FLO_fnc_sendNotification;
                    _lastNotification = time;
                };

                // Check if siege time exceeded
                if (_holdoutTime >= _maxHoldTime) exitWith {
                    _statusMarker setMarkerTextLocal "FOB LOST!";
                    _statusMarker setMarkerColor "ColorBlack";

                    ["FOB has fallen to enemy forces!", "error", false, 0] call FLO_fnc_sendNotification;
                    ["FOB", 1, "FOB lost due to prolonged siege"] call FLO_fnc_log;

                    // Execute destruction sequence
                    private _cleanupRadius = _config get "cleanupRadius";
                    private _objectsToDestroy = [
                        [FLO_FactionFobTerminalType]
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
                        ["FOB defense successful! Timer reset.", "success", false, 0] call FLO_fnc_sendNotification;
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
