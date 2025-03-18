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
 * - B: Open build menu
 *
 * @param {Object} [_this] - The object to center the camera on (defaults to player vehicle if undefined)
 *
 * @return {Nothing}
 *
 * @example
 * [player] call IDS_Logistics_fnc_initBuildCamera
 */

// ---- CAMERA CONFIGURATION SETUP ----

//--- Is FLIR available
if (isnil "IDS_LOGISTICS_BUILD_CAM_ISFLIR") then { IDS_LOGISTICS_BUILD_CAM_ISFLIR = isClass (configFile >> "CfgPatches" >> "A3_Data_F"); };

IDS_LOGISTICS_CAM_VISION = 0;
IDS_LOGISTICS_CAM_COLOR = ppEffectCreate ["colorCorrections", 1600];

// Initialize terrain snap variable only if it doesn't exist
if (isNil "IDS_Logistics_CameraTerrainSnap") then { IDS_Logistics_CameraTerrainSnap = false; };

// Initialize center cursor variable
if (isNil "IDS_Logistics_ShowCenterCursor") then { IDS_Logistics_ShowCenterCursor = false; };

IDS_Logistics_MouseClicks = [];

// ---- CAMERA INITIALIZATION ----

//--- Use provided object or default to player's vehicle
if (typeName _this != typeName objNull) then { _this = cameraOn };

//--- Ensure simulation runs at minimum speed (camera needs time to advance)
setAccTime (accTime max (1 / 128));

private _ppos = getPosASL _this;
private _pX = _ppos select 0;
private _pY = _ppos select 1;
private _pZ = _ppos select 2;

//--- Adjust height if below sea level
private _pHeight = getTerrainHeightASL [_pX, _pY];
if (_pHeight < 0) then { _pZ = _pZ + _pHeight };

//--- Create camera slightly above target
private _local = "camconstruct" camCreate [_pX, _pY, _pZ + 2];

IDS_LOGISTICS_CAM = _local;
_local camCommand "MANUAL ON";
_local cameraEffect ["INTERNAL", "BACK"];
showCinemaBorder false;
IDS_LOGISTICS_CAM setDir direction (vehicle player);

// Store initial camera position for range limitation
IDS_LOGISTICS_CAM_INITIAL_POS = [_pX, _pY, _pZ + 2];
IDS_LOGISTICS_CAM_MAX_DISTANCE = 50; // Maximum distance in meters
IDS_LOGISTICS_CAM_AT_LIMIT = false;  // Flag to prevent spam notifications

// Add visual boundary system
IDS_Logistics_BoundaryEH = addMissionEventHandler ["EachFrame", {
    if (!isNil "IDS_LOGISTICS_CAM" && {!isNull IDS_LOGISTICS_CAM}) then {
        private _center = IDS_LOGISTICS_CAM_INITIAL_POS;
        private _radius = IDS_LOGISTICS_CAM_MAX_DISTANCE;
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
            private _camPos = getPosASL IDS_LOGISTICS_CAM;
            private _camDir = vectorDir IDS_LOGISTICS_CAM;
            
            // If vectorDir fails, try other methods
            if (_camDir isEqualTo [0,0,0]) then {
                _camDir = getCameraViewDirection IDS_LOGISTICS_CAM;
            };
            
            if (_camDir isEqualTo [0,0,0]) then {
                private _camDirection = getDir IDS_LOGISTICS_CAM;
                _camDir = [sin _camDirection, cos _camDirection, 0];
            };
            
            private _targetPos = _camPos vectorAdd (_camDir vectorMultiply 200);
            private _intersections = lineIntersectsSurfaces [
                _camPos, 
                _targetPos, 
                IDS_LOGISTICS_CAM, 
                objNull, 
                true, 
                1, 
                "VIEW", 
                "FIRE"
            ];
            
            if (count _intersections > 0) then {
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
    if (!isNil "IDS_LOGISTICS_CAM" && {!isNull IDS_LOGISTICS_CAM}) then {
        private _currentPos = getPosASL IDS_LOGISTICS_CAM;
        private _initialPos = IDS_LOGISTICS_CAM_INITIAL_POS;

        // Calculate 2D distance manually using x and y coordinates only
        private _deltaX = (_currentPos select 0) - (_initialPos select 0);
        private _deltaY = (_currentPos select 1) - (_initialPos select 1);
        private _distance = sqrt(_deltaX^2 + _deltaY^2);

        // If camera exceeds the limit, move it back to the boundary
        if (_distance > IDS_LOGISTICS_CAM_MAX_DISTANCE) then {
            // Calculate direction vector from initial position to current position (2D only)
            private _dir = [_deltaX, _deltaY, 0];

            // Normalize the direction vector
            private _dirLength = sqrt((_dir select 0)^2 + (_dir select 1)^2);
            if (_dirLength > 0) then {
                _dir = [(_dir select 0) / _dirLength, (_dir select 1) / _dirLength, 0];

                // Calculate new position at the boundary
                private _newPos = [
                    (_initialPos select 0) + (_dir select 0) * IDS_LOGISTICS_CAM_MAX_DISTANCE,
                    (_initialPos select 1) + (_dir select 1) * IDS_LOGISTICS_CAM_MAX_DISTANCE,
                    _currentPos select 2
                ];

                // Move camera to the boundary
                IDS_LOGISTICS_CAM setPosASL _newPos;

                // Show notification if not already at limit
                if (!IDS_LOGISTICS_CAM_AT_LIMIT) then {
                    ["<t color='#FF8844'>Maximum camera distance reached (50m)</t>", 2] call IDS_Logistics_fnc_cameraHint;
                    IDS_LOGISTICS_CAM_AT_LIMIT = true;
                };
            }
        } else {
            // Reset the limit flag when back within bounds
            if (IDS_LOGISTICS_CAM_AT_LIMIT && _distance < (IDS_LOGISTICS_CAM_MAX_DISTANCE - 1)) then { IDS_LOGISTICS_CAM_AT_LIMIT = false; };
        };
    };
}];

// Add mouse click handlers for the camera
IDS_Logistics_MouseClicks pushBack ((findDisplay 46) displayAddEventHandler ["MouseButtonDown", {
    params ["_display", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];

    // Left click - place entity or delete if shift is pressed
    if (_button == 0) then {
        // Use proper camera direction vector calculation
        private _camPos = getPosASL IDS_LOGISTICS_CAM;

        // Get camera direction using vectorDir instead of getCameraViewDirection
        private _camDir = vectorDir IDS_LOGISTICS_CAM;

        // If that's still zero, calculate from camera angles
        if (_camDir isEqualTo [0,0,0]) then {
            private _camDirection = getDir IDS_LOGISTICS_CAM;
            _camDir = [sin _camDirection, cos _camDirection, 0];
        };

        private _targetPos = _camPos vectorAdd (_camDir vectorMultiply 200);

        if (isNil "IDS_LOGISTICS_CAM") exitWith {};
        private _intersections = lineIntersectsSurfaces [
            _camPos, 
            _targetPos, 
            IDS_LOGISTICS_CAM, 
            objNull, 
            true, 
            1, 
            "VIEW", 
            "FIRE"
        ];

        private _centerObj = objNull;
        private _intersectPos = [];

        if (count _intersections > 0) then {
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
                        
                        if (count _intersectASL > 0) then {
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
                    // Check for players on the object
                    if ([_centerObj] call _hasPlayersOnObject) then {
                        ["Cannot delete: Players are on the object", 2] call IDS_Logistics_fnc_cameraHint;
                    } else {
                        deleteVehicle _centerObj;
                        ["Entity removed: " + _type, 2] call IDS_Logistics_fnc_cameraHint;
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

    // Right click - Cancel placement or return picked up entity
    if (_button == 1) then {
        if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
            // Check if this is a picked up entity
            private _isPickedUp = false;
            private _originalNetId = "";
            
            // Safely get variables with default values
            {
                private _var = IDS_Logistics_currentEntity getVariable [_x, nil];
                if (!isNil "_var") then {
                    switch (_x) do {
                        case "IDS_Logistics_isPickedUp": { _isPickedUp = _var };
                        case "IDS_Logistics_OriginalNetId": { _originalNetId = _var };
                    };
                };
            } forEach ["IDS_Logistics_isPickedUp", "IDS_Logistics_OriginalNetId"];

            if (_isPickedUp && {_originalNetId != ""}) then {
                // Tell server to restore the original entity
                [_originalNetId, false] remoteExecCall ["IDS_Logistics_fnc_toggleEntityVisibility", 2];

                // Delete the local preview
                deleteVehicle IDS_Logistics_currentEntity;
                IDS_Logistics_currentEntity = objNull;
                IDS_Logistics_isHolding = false;

                ["Entity returned to original position", 2] call IDS_Logistics_fnc_cameraHint;
            } else {
                // This is a new entity being placed, delete it
                deleteVehicle IDS_Logistics_currentEntity;
                IDS_Logistics_currentEntity = objNull;
                IDS_Logistics_isHolding = false;
                ["Placement cancelled", 2] call IDS_Logistics_fnc_cameraHint;
            };
        };
        true;
    };
    false;
}]);

// Add escape key handler for exiting build mode
_keyDown = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];

    // Escape key - Exit build mode
    if (_key == 1) then {
        if (!isNull IDS_LOGISTICS_CAM) then {
            // Temporarily disable user input to prevent escape menu
            disableUserInput true;
            
            // Store last position before cleanup
            IDS_LOGISTICS_CAM_LASTPOS = position IDS_LOGISTICS_CAM;
            
            // Clean up any held entity
            if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
                deleteVehicle IDS_Logistics_currentEntity;
                IDS_Logistics_currentEntity = objNull;
                IDS_Logistics_isHolding = false;
            };

            // Clean up cursor arrow
            if (!isNil "IDS_Logistics_CursorArrow") then {
                deleteVehicle IDS_Logistics_CursorArrow;
                IDS_Logistics_CursorArrow = nil;
            };

            // Clean up boundary arrows
            {
                private _arrow = missionNamespace getVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], objNull];
                if (!isNull _arrow) then {
                    deleteVehicle _arrow;
                    missionNamespace setVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], nil];
                };
            } forEach [0, 90, 180, 270];

            // Remove event handlers
            if (!isNil "IDS_Logistics_DistanceCheckEH") then { 
                removeMissionEventHandler ["EachFrame", IDS_Logistics_DistanceCheckEH];
                IDS_Logistics_DistanceCheckEH = nil;
            };
            if (!isNil "IDS_Logistics_BoundaryEH") then { 
                removeMissionEventHandler ["EachFrame", IDS_Logistics_BoundaryEH];
                IDS_Logistics_BoundaryEH = nil;
            };
            
            // Clean up camera and effects
            player cameraEffect ["TERMINATE", "BACK"];
            if (!isNil "IDS_LOGISTICS_CAM_COLOR") then { 
                ppEffectDestroy IDS_LOGISTICS_CAM_COLOR;
                IDS_LOGISTICS_CAM_COLOR = nil;
            };
            camDestroy IDS_LOGISTICS_CAM;
            
            // Reset all global variables
            IDS_LOGISTICS_CAM = nil;
            IDS_LOGISTICS_CAM_VISION = nil;
            IDS_LOGISTICS_HINT_VISIBLE = nil;
            IDS_Logistics_isHolding = false;
            IDS_Logistics_currentEntity = objNull;
            IDS_Logistics_lastViewDir = nil;
            IDS_Logistics_ShowCenterCursor = nil;
            IDS_Logistics_CameraTerrainSnap = nil;

            ["Build mode exited", 2] call IDS_Logistics_fnc_cameraHint;
            
            // Re-enable user input
            disableUserInput false;
            true;
        };
        true;
    };

    if (_key in (actionkeys 'nightvision')) then {
        IDS_LOGISTICS_CAM_VISION = IDS_LOGISTICS_CAM_VISION + 1;
        _vision = IDS_LOGISTICS_CAM_VISION % 2;
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

    if (_key == 83 && !isNil 'IDS_LOGISTICS_CAM_LASTPOS') then { IDS_LOGISTICS_CAM setPos IDS_LOGISTICS_CAM_LASTPOS; };
    if (_key == 48) then { [] call IDS_Logistics_fnc_openBuildMenu; };
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

// ---- CAMERA CLEANUP HANDLER ----

//--- Wait until destroy is forced or camera auto-destroyed
[_local, _keyDown] spawn {
    params ["_local", "_keyDown"];
    
    waitUntil { isNull _local };

    // Store last position before cleanup
    if (!isNil "IDS_LOGISTICS_CAM") then {
        IDS_LOGISTICS_CAM_LASTPOS = position IDS_LOGISTICS_CAM;
    };

    // Clean up any held entity
    if (!isNull IDS_Logistics_currentEntity) then { 
        deleteVehicle IDS_Logistics_currentEntity;
        IDS_Logistics_currentEntity = objNull;
    };

    // Clean up cursor arrow
    if (!isNil "IDS_Logistics_CursorArrow") then {
        deleteVehicle IDS_Logistics_CursorArrow;
        IDS_Logistics_CursorArrow = nil;
    };

    // Clean up boundary arrows
    {
        private _arrow = missionNamespace getVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], objNull];
        if (!isNull _arrow) then {
            deleteVehicle _arrow;
            missionNamespace setVariable [format ["IDS_Logistics_BoundaryArrow_%1", _x], nil];
        };
    } forEach [0, 90, 180, 270];

    // Remove all event handlers
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", _keyDown];
    
    if (!isNil "IDS_Logistics_MouseClicks") then {
        {
            (findDisplay 46) displayRemoveEventHandler ["MouseButtonDown", _x];
        } forEach IDS_Logistics_MouseClicks;
        IDS_Logistics_MouseClicks = nil;
    };

    if (!isNil "IDS_Logistics_scrollHandler") then { 
        (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler];
        IDS_Logistics_scrollHandler = nil;
    };
    if (!isNil "IDS_Logistics_keyDownHandler") then { 
        (findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler];
        IDS_Logistics_keyDownHandler = nil;
    };
    if (!isNil "IDS_Logistics_keyUpHandler") then { 
        (findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler];
        IDS_Logistics_keyUpHandler = nil;
    };
    if (!isNil "IDS_Logistics_dirUpdateEH") then { 
        removeMissionEventHandler ["EachFrame", IDS_Logistics_dirUpdateEH];
        IDS_Logistics_dirUpdateEH = nil;
    };
    if (!isNil "IDS_Logistics_DistanceCheckEH") then { 
        removeMissionEventHandler ["EachFrame", IDS_Logistics_DistanceCheckEH];
        IDS_Logistics_DistanceCheckEH = nil;
    };
    if (!isNil "IDS_Logistics_BoundaryEH") then { 
        removeMissionEventHandler ["EachFrame", IDS_Logistics_BoundaryEH];
        IDS_Logistics_BoundaryEH = nil;
    };

    // Clean up camera and effects
    player cameraEffect ["TERMINATE", "BACK"];
    if (!isNil "IDS_LOGISTICS_CAM_COLOR") then { 
        ppEffectDestroy IDS_LOGISTICS_CAM_COLOR;
        IDS_LOGISTICS_CAM_COLOR = nil;
    };
    camDestroy _local;

    // Reset all global variables
    IDS_LOGISTICS_CAM = nil;
    IDS_LOGISTICS_CAM_VISION = nil;
    IDS_LOGISTICS_HINT_VISIBLE = nil;
    IDS_Logistics_isHolding = false;
    IDS_Logistics_currentEntity = objNull;
    IDS_Logistics_lastViewDir = nil;
    IDS_Logistics_ShowCenterCursor = nil;
    IDS_Logistics_CameraTerrainSnap = nil;
};

// Display camera controls info
private _controlsInfo = format [
    "<t color='#AAFFAA' size='1.0'>CONTROLS</t><br/><t align='left'>" +
    "<t>• <t color='#DDDDDD'>N key</t> - Toggle normal/night vision</t><br/>" +
    "<t>• <t color='#DDDDDD'>B key</t> - Open build menu</t><br/>" +
    "<t>• <t color='#DDDDDD'>T key</t> - Toggle terrain snapping</t><br/>" +
    "<t>• <t color='#DDDDDD'>C key</t> - Toggle 3d cursor</t><br/>" +
    "<t>• <t color='#DDDDDD'>Q/Z key</t> - Raise/Lower camera</t><br/>" +
    "<t>• <t color='#DDDDDD'>Left click</t> - Place entity</t><br/>" +
    "<t>• <t color='#DDDDDD'>CTRL + Left click</t> - Pick up entity</t><br/>" +
    "<t>• <t color='#DDDDDD'>SHIFT + Left click</t> - Delete entity under cursor</t><br/>" +
    "<t>• <t color='#DDDDDD'>Right click</t> - Cancel placement</t><br/>" +
    "<t>• <t color='#DDDDDD'>ESC key</t> - Exit build mode</t><br/>" +
    "<t>• <t color='#DDDDDD'>CTRL + scroll</t> - Adjust height</t><br/>" +
    "<t>• <t color='#DDDDDD'>SHIFT + scroll</t> - Rotate entity</t><br/>" +
    "<t>• <t color='#DDDDDD'>ALT + scroll</t> - Adjust distance</t>"
];

[_controlsInfo, 0] call IDS_Logistics_fnc_cameraHint;

if (!isNull (findDisplay 9500)) exitWith { false };