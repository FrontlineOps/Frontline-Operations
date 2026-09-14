/**
 * @name IDS_Logistics_fnc_initBuildCamera
 * @category Logistics_Core
 *
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 *
 * @description
 * Initializes the IDS Logistics build camera system.
 * This camera allows players to view and place construction objects from different angles.
 * Features include different vision modes (normal, NVG, thermal), color correction filters,
 * and key bindings for camera control.
 *
 * Key Controls:
 * - N: Toggle vision modes (Normal, NVG, Thermal White Hot, Thermal Black Hot)
 * - Numpad Decimal: Reset to last position
 * - B: Open build menu (if not disabled)
 *
 * @param {Object|Array} _this - This can be:
 *  - Object: The object to center the camera on (defaults to player vehicle if undefined)
 *  - Array: [object, buildMenuDisabled] where:
 *      - object: The object to center camera on
 *      - buildMenuDisabled (boolean): Whether to disable the build menu (default: false)
 *
 * @return {Nothing}
 *
 * @example
 * [player] call IDS_Logistics_fnc_initBuildCamera                // Enable camera with build menu
 * [player, true] call IDS_Logistics_fnc_initBuildCamera          // Enable camera without build menu
 */

if (!hasInterface) exitWith { false };
if (IDS_Logistics_CameraActive) then {
    [IDS_Logistics_CameraSession] call IDS_Logistics_fnc_closeBuildCamera;
};
IDS_Logistics_CameraSession = IDS_Logistics_CameraSession + 1;
private _session = IDS_Logistics_CameraSession;
uiNamespace setVariable ["IDS_Logistics_CameraDisplay", findDisplay 46];

// ---- CAMERA CONFIGURATION SETUP ----

// Parse parameters
private _targetObject = objNull;
private _buildMenuDisabled = false;

if (typeName _this == "ARRAY") then {
    if (_this isNotEqualTo []) then {
        _targetObject = _this select 0;
        if (count _this > 1) then {
            _buildMenuDisabled = _this select 1;
        };
    };
} else {
    _targetObject = _this;
};

// Set global variable for build menu status
IDS_Logistics_BuildMenuDisabled = _buildMenuDisabled;

//--- Is FLIR available
if (isNil "IDS_Logistics_BuildCameraIsFlir") then { IDS_Logistics_BuildCameraIsFlir = isClass (configFile >> "CfgPatches" >> "A3_Data_F"); };

IDS_Logistics_CameraVision = 0;
IDS_Logistics_CameraColorEffect = ppEffectCreate ["colorCorrections", 1600];

// Initialize terrain snap variable only if it doesn't exist
if (isNil "IDS_Logistics_CameraTerrainSnap") then { IDS_Logistics_CameraTerrainSnap = false; };

// Initialize center cursor variable
if (isNil "IDS_Logistics_ShowCenterCursor") then { IDS_Logistics_ShowCenterCursor = false; };

IDS_Logistics_MouseClicks = [];

// ---- CAMERA INITIALIZATION ----

//--- Use provided object or default to player's vehicle
if (typeName _targetObject != typeName objNull) then { _targetObject = cameraOn };

//--- Ensure simulation runs at minimum speed (camera needs time to advance)
setAccTime (accTime max (1 / 128));

private _ppos = getPosASL _targetObject;
private _pX = _ppos select 0;
private _pY = _ppos select 1;
private _pZ = _ppos select 2;

//--- Adjust height if below sea level
private _pHeight = getTerrainHeightASL [_pX, _pY];
if (_pHeight < 0) then { _pZ = _pZ + _pHeight };

//--- Create camera slightly above target
private _local = "camconstruct" camCreate [_pX, _pY, _pZ + 2];

IDS_Logistics_Camera = _local;
IDS_Logistics_CameraActive = true;
_local camCommand "MANUAL ON";
_local cameraEffect ["INTERNAL", "BACK"];
showCinemaBorder false;
IDS_Logistics_Camera setDir direction (vehicle player);

// Store initial camera position for range limitation
IDS_Logistics_CameraInitialPos = [_pX, _pY, _pZ + 2];
IDS_Logistics_CameraMaxDistance = 50; // Maximum distance in meters
IDS_Logistics_CameraAtLimit = false;  // Flag to prevent spam notifications

// Add visual boundary system
IDS_Logistics_BoundaryEH = addMissionEventHandler ["EachFrame", {
    if (!isNil "IDS_Logistics_Camera" && {!isNull IDS_Logistics_Camera}) then {
        private _center = IDS_Logistics_CameraInitialPos;
        private _radius = IDS_Logistics_CameraMaxDistance;
        private _segments = 64; // Number of segments in the circle
        private _height = 0.5; // Height of the boundary lines

        // Draw the boundary circle
        for "_i" from 0 to (_segments - 1) do {
            private _angle1 = (_i / _segments) * 360;
            private _angle2 = ((_i + 1) / _segments) * 360;

            private _pos1 = [
                (_center select 0) + (_radius * sin _angle1),
                (_center select 1) + (_radius * cos _angle1),
                _height
            ];

            private _pos2 = [
                (_center select 0) + (_radius * sin _angle2),
                (_center select 1) + (_radius * cos _angle2),
                _height
            ];

            // Draw the line segment
            drawLine3D [_pos1, _pos2, [0.5, 0.1, 0.1, 0.5]];
        };

        // Draw vertical lines at cardinal points for better depth perception
        private _cardinalPoints = [0, 90, 180, 270];
        {
            private _angle = _x;
            private _pos = [
                (_center select 0) + (_radius * sin _angle),
                (_center select 1) + (_radius * cos _angle),
                _height
            ];
            drawLine3D [_pos, [_pos select 0, _pos select 1, 0], [0.5, 0.1, 0.1, 0.3]];
        } forEach _cardinalPoints;

        // Draw center cursor if enabled
        if (!isNil "IDS_Logistics_ShowCenterCursor" && { IDS_Logistics_ShowCenterCursor }) then {
            private _camPos = getPosASL IDS_Logistics_Camera;
            private _camDir = vectorDir IDS_Logistics_Camera;

            // If vectorDir fails, try other methods
            if (_camDir isEqualTo [0,0,0]) then {
                _camDir = getCameraViewDirection IDS_Logistics_Camera;
            };

            if (_camDir isEqualTo [0,0,0]) then {
                private _camDirection = getDir IDS_Logistics_Camera;
                _camDir = [sin _camDirection, cos _camDirection, 0];
            };

            private _targetPos = _camPos vectorAdd (_camDir vectorMultiply 200);
            private _intersections = lineIntersectsSurfaces [
                _camPos,
                _targetPos,
                IDS_Logistics_Camera,
                objNull,
                true,
                1,
                "VIEW",
                "FIRE"
            ];

            if (_intersections isNotEqualTo []) then {
                private _intersectPos = (_intersections select 0) select 0;
                private _intersectObj = (_intersections select 0) select 2;
                private _color = [1, 1, 1, 0.8]; // White cursor by default

                // Change color if looking at a placeable entity
                if (!isNull _intersectObj && {_intersectObj getVariable ["IDS_Logistics_isPlacedEntity", false]}) then {
                    _color = [0, 1, 0, 0.8]; // Green for placeable entities
                };

                // Create cursor arrow only if it doesn't exist
                if (isNil "IDS_Logistics_CursorArrow") then {
                    IDS_Logistics_CursorArrow = "Sign_Arrow_F" createVehicleLocal [0,0,0];
                };

                // Update cursor arrow position and color
                IDS_Logistics_CursorArrow setPosASL _intersectPos;
                IDS_Logistics_CursorArrow setVectorUp ((_intersections select 0) select 1);

                // Set material color based on whether looking at placeable entity
                if (_color isEqualTo [0, 1, 0, 0.8]) then {
                    IDS_Logistics_CursorArrow setObjectTexture [0, "#(rgb,8,8,3)color(0,1,0,0.8)"];
                } else {
                    IDS_Logistics_CursorArrow setObjectTexture [0, "#(rgb,8,8,3)color(1,1,1,0.8)"];
                };
            } else {
                // Delete cursor arrow if it exists and cursor is disabled
                if (!isNil "IDS_Logistics_CursorArrow") then {
                    deleteVehicle IDS_Logistics_CursorArrow;
                    IDS_Logistics_CursorArrow = nil;
                };
            };
        };

        // Create or update cardinal direction arrows
        private _cardinalDirections = [0, 90, 180, 270];

        {
            private _angle = _x;
            private _arrowPos = [
                (_center select 0) + (_radius * sin _angle),
                (_center select 1) + (_radius * cos _angle),
                0.5
            ];

            // Create arrow if it doesn't exist
            if (isNil format ["IDS_Logistics_BoundaryArrow_%1", _angle]) then {
                private _arrow = "Sign_Arrow_Direction_F" createVehicleLocal _arrowPos;
                missionNamespace setVariable [format ["IDS_Logistics_BoundaryArrow_%1", _angle], _arrow];
            };

            // Update arrow position and direction
            private _arrow = missionNamespace getVariable format ["IDS_Logistics_BoundaryArrow_%1", _angle];
            _arrow setPosASL [_arrowPos select 0, _arrowPos select 1, getTerrainHeightASL [_arrowPos select 0, _arrowPos select 1] + 0.5];
            _arrow setDir _angle; // Point outward (removed the +180)
            _arrow setObjectTexture [0, "#(rgb,8,8,3)color(0.5,0.1,0.1,0.5)"];
        } forEach _cardinalDirections;
    };
}];

// Add range limitation check (50 meter radius from initial position)
IDS_Logistics_DistanceCheckEH = addMissionEventHandler ["EachFrame", {
    if (!isNil "IDS_Logistics_Camera" && {!isNull IDS_Logistics_Camera}) then {
        private _currentPos = getPosASL IDS_Logistics_Camera;
        private _initialPos = IDS_Logistics_CameraInitialPos;

        // Calculate 2D distance manually using x and y coordinates only
        private _deltaX = (_currentPos select 0) - (_initialPos select 0);
        private _deltaY = (_currentPos select 1) - (_initialPos select 1);
        private _distance = sqrt(_deltaX^2 + _deltaY^2);

        // If camera exceeds the limit, move it back to the boundary
        if (_distance > IDS_Logistics_CameraMaxDistance) then {
            // Calculate direction vector from initial position to current position (2D only)
            private _dir = [_deltaX, _deltaY, 0];

            // Normalize the direction vector
            private _dirLength = sqrt((_dir select 0)^2 + (_dir select 1)^2);
            if (_dirLength > 0) then {
                _dir = [(_dir select 0) / _dirLength, (_dir select 1) / _dirLength, 0];

                // Calculate new position at the boundary
                private _newPos = [
                    (_initialPos select 0) + (_dir select 0) * IDS_Logistics_CameraMaxDistance,
                    (_initialPos select 1) + (_dir select 1) * IDS_Logistics_CameraMaxDistance,
                    _currentPos select 2
                ];

                // Move camera to the boundary
                IDS_Logistics_Camera setPosASL _newPos;

                // Show notification if not already at limit
                if (!IDS_Logistics_CameraAtLimit) then {
                    ["<t color='#FF8844'>Maximum camera distance reached (50m)</t>", 2] call IDS_Logistics_fnc_cameraHint;
                    IDS_Logistics_CameraAtLimit = true;
                };
            }
        } else {
            // Reset the limit flag when back within bounds
            if (IDS_Logistics_CameraAtLimit && _distance < (IDS_Logistics_CameraMaxDistance - 1)) then { IDS_Logistics_CameraAtLimit = false; };
        };
    };
}];

// Add mouse click handlers for the camera
IDS_Logistics_MouseClicks pushBack ((findDisplay 46) displayAddEventHandler ["MouseButtonDown", {
    params ["_display", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    // Left click - place entity or delete if shift is pressed
    if (_button == 0) then {
        // Use proper camera direction vector calculation
        private _camPos = getPosASL IDS_Logistics_Camera;

        // Get camera direction using vectorDir instead of getCameraViewDirection
        private _camDir = vectorDir IDS_Logistics_Camera;

        // If that's still zero, calculate from camera angles
        if (_camDir isEqualTo [0,0,0]) then {
            private _camDirection = getDir IDS_Logistics_Camera;
            _camDir = [sin _camDirection, cos _camDirection, 0];
        };

        private _targetPos = _camPos vectorAdd (_camDir vectorMultiply 200);

        if (isNil "IDS_Logistics_Camera") exitWith {};
        private _intersections = lineIntersectsSurfaces [
            _camPos,
            _targetPos,
            IDS_Logistics_Camera,
            objNull,
            true,
            1,
            "VIEW",
            "FIRE"
        ];

        private _centerObj = objNull;
        private _intersectPos = [];

        if (_intersections isNotEqualTo []) then {
            _centerObj = (_intersections select 0) select 2;
            _intersectPos = (_intersections select 0) select 0;
        };

        // Function to check if any players are on the object
        private _hasPlayersOnObject = {
            params ["_object"];
            if (isNull _object) exitWith { false };

            private _objectPos = getPosASL _object;
            private _objectSize = boundingBoxReal _object;
            private _minZ = (_objectSize select 0) select 2;
            private _maxZ = (_objectSize select 1) select 2;
            private _height = _maxZ - _minZ;

            // Check all players within 10m radius (optimization)
            private _nearPlayers = _objectPos nearEntities ["CAManBase", 10];

            private _playersOnObject = false;
            {
                if (isPlayer _x) then {
                    private _playerPos = getPosASL _x;
                    private _relativeZ = (_playerPos select 2) - (_objectPos select 2);

                    // Check if player is above the object and within its height bounds
                    if (_relativeZ > _minZ && _relativeZ <= (_maxZ + 2)) then {
                        // Check if player is within the object's 2D bounds
                        private _playerPosASL = getPosASL _x;
                        private _intersectASL = lineIntersectsSurfaces [
                            _playerPosASL vectorAdd [0,0,0.1],
                            _playerPosASL vectorAdd [0,0,-2],
                            _x,
                            objNull,
                            true,
                            1,
                            "GEOM",
                            "NONE"
                        ];

                        if (_intersectASL isNotEqualTo []) then {
                            if ((_intersectASL select 0) select 2 == _object) then {
                                _playersOnObject = true;
                            };
                        };
                    };
                };
                if (_playersOnObject) exitWith {};
            } forEach _nearPlayers;

            _playersOnObject
        };

        // SHIFT + Left click = Delete entity under center of screen
        if (_shift) then {
            if (!isNull _centerObj) then {
                private _isPlaced = _centerObj getVariable ["IDS_Logistics_isPlacedEntity", false];
                private _type = typeOf _centerObj;

                if (_isPlaced) then {
                    // Check if delete entity is disabled
                    if (IDS_Logistics_BuildMenuDisabled) then {
                        ["Delete entity is disabled in this mode", 2] call IDS_Logistics_fnc_cameraHint;
                    } else {
                        // Check for players on the object
                        if ([_centerObj] call _hasPlayersOnObject) then {
                            ["Cannot delete: Players are on the object", 2] call IDS_Logistics_fnc_cameraHint;
                        } else {
                            deleteVehicle _centerObj;
                            ["Entity removed: " + _type, 2] call IDS_Logistics_fnc_cameraHint;
                        };
                    };
                } else {
                    ["Found object but not placeable: " + _type, 2] call IDS_Logistics_fnc_cameraHint;
                };
            } else {
                ["No object found at center of screen", 2] call IDS_Logistics_fnc_cameraHint;
            };
        } else {
            // CTRL + Left click = Pick up entity
            if (_ctrl) then {
                // Check if looking at a placed entity to pick it up
                if (!isNull _centerObj && { _centerObj getVariable ["IDS_Logistics_isPlacedEntity", false] }) then {
                    // Check for players on the object
                    if ([_centerObj] call _hasPlayersOnObject) then {
                        ["Cannot pick up: Players are on the object", 2] call IDS_Logistics_fnc_cameraHint;
                    } else {
                        [_centerObj] call IDS_Logistics_fnc_pickupEntity;
                    };
                };
            } else {
                // Normal left click - place entity
                if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then { [] call IDS_Logistics_fnc_placeEntity; };
            };
        };
        true;
    };

    // Right click releases both preview and handlers, including a missing preview.
    if (_button == 1) then {
        if ([true] call IDS_Logistics_fnc_cleanupPlacement) then {
            ["Placement cancelled", 2] call IDS_Logistics_fnc_cameraHint;
        };
        true;
    };
    false;
}]);

// Add escape key handler for exiting build mode
IDS_Logistics_cameraKeyDownHandler = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];

    if (_key == 1) exitWith {
        [IDS_Logistics_CameraSession] call IDS_Logistics_fnc_closeBuildCamera;
        true
    };

    if (_key in (actionKeys 'nightvision')) then {
        IDS_Logistics_CameraVision = IDS_Logistics_CameraVision + 1;
        _vision = IDS_Logistics_CameraVision % 2;
        switch (_vision) do {
            case 0: {
                camUseNVG false;
                ['Normal Vision', 2] call IDS_Logistics_fnc_cameraHint;
            };
            case 1: {
                camUseNVG true;
                ['Night Vision', 2] call IDS_Logistics_fnc_cameraHint;
            };
        };
    };

    if (_key == 83 && !isNil 'IDS_Logistics_CameraLastPos') then { IDS_Logistics_Camera setPos IDS_Logistics_CameraLastPos; };
    if (_key == 48) then {
        if (!IDS_Logistics_BuildMenuDisabled) then {
            [] call IDS_Logistics_fnc_openBuildMenu;
        } else {
            ["Build menu is disabled in this mode", 2] call IDS_Logistics_fnc_cameraHint;
        };
    };
    if (_key == 20) then {
        IDS_Logistics_CameraTerrainSnap = !IDS_Logistics_CameraTerrainSnap;
        if (IDS_Logistics_CameraTerrainSnap) then {
            ['Terrain snapping: ENABLED', 2] call IDS_Logistics_fnc_cameraHint;
        } else {
            ['Terrain snapping: DISABLED', 2] call IDS_Logistics_fnc_cameraHint;
        };
    };

    // Add cursor toggle (C key)
    if (_key == 46) then {
        IDS_Logistics_ShowCenterCursor = !IDS_Logistics_ShowCenterCursor;

        // If disabling cursor, ensure it's deleted
        if (!IDS_Logistics_ShowCenterCursor && !isNil "IDS_Logistics_CursorArrow") then {
            deleteVehicle IDS_Logistics_CursorArrow;
            IDS_Logistics_CursorArrow = nil;
        };

        if (IDS_Logistics_ShowCenterCursor) then {
            ['Center cursor: ENABLED', 2] call IDS_Logistics_fnc_cameraHint;
        } else {
            ['Center cursor: DISABLED', 2] call IDS_Logistics_fnc_cameraHint;
        };
    };

    false;
}];

// The worker captures its owner; cleanup from an older session cannot touch a new one.
[_local, _session, player] spawn {
    params ["_camera", "_session", "_player"];
    waitUntil {
        isNull _camera || {!alive _player} || {player isNotEqualTo _player} || {isNull findDisplay 46}
    };
    [_session] call IDS_Logistics_fnc_closeBuildCamera;
};

// Keep the complete controls guide legible without repeating key/type labels.
private _buildText = ["B  Build menu disabled", "B  Open build menu"] select (!IDS_Logistics_BuildMenuDisabled);
private _deleteText = ["Shift + click  Delete disabled", "Shift + click  Delete object"] select (!IDS_Logistics_BuildMenuDisabled);
private _controlsInfo = format [
    "<t font='PuristaBold'>Build controls</t><br/>" +
    "%1<br/>N  Normal / night vision<br/>T  Terrain snapping<br/>C  3D cursor<br/>" +
    "Q / Z  Raise / lower camera<br/>Click  Place object<br/>Ctrl + click  Pick up object<br/>" +
    "%2<br/>Right click  Cancel placement<br/>Esc  Exit build mode<br/>" +
    "Ctrl + scroll  Height<br/>Shift + scroll  Rotation<br/>Alt + scroll  Distance",
    _buildText, _deleteText
];

[_controlsInfo, 0] call IDS_Logistics_fnc_cameraHint;

if (!isNull (findDisplay 9500)) exitWith { false };
