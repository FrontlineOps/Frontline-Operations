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
    ["actionPrefix", "OP"],
    ["markerText", "COP"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "opMarkerName"],
    ["initVariable", "FLO_OP_Initialized"],
    ["restoreVariable", "FLO_OP_MarkersRestored"],
    ["containerTypeVariable", "FLO_FactionCopTerminalType"],
    ["containerFallbackType", "Land_TripodScreen_01_dual_v2_sand_F"],
    ["containerSearchRadius", 10],
    ["containerMissingLog", "No OP container found nearby for actions"],
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

private _markerName = [_opBuilding, _config, _preserveMarker] call FLO_fnc_baseCreateMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// ============================================================================
// ACTIONS SETUP
// ============================================================================

[_opBuilding, _config] call FLO_fnc_baseConfigureMainActions;
[_opBuilding, _config] call FLO_fnc_baseConfigureContainerActions;

// ============================================================================
// TRIGGER SETUP
// ============================================================================

private _triggers = [_opBuilding, _config] call FLO_fnc_baseCreateTriggers;

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
