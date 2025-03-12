/**
 * @name IDS_Logistics_fnc_initBuildCamera
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.1
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
 * - Grave (`): Disable post-processing
 * - B: Open build menu
 * - 1-0: Apply different visual filters
 *
 * @param {Object} [_this] - The object to center the camera on (defaults to player vehicle if undefined)
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_initBuildCamera
 */

// ---- CAMERA CONFIGURATION SETUP ----

//--- Is FLIR available
if (isnil "IDS_LOGISTICS_BUILD_CAM_ISFLIR") then {
	IDS_LOGISTICS_BUILD_CAM_ISFLIR = isClass (configFile >> "CfgPatches" >> "A3_Data_F");
};

IDS_LOGISTICS_CAM_VISION = 0;
IDS_LOGISTICS_CAM_COLOR = ppEffectCreate ["colorCorrections", 1600];
IDS_Logistics_CameraTerrainSnap = false; // Default: no terrain snapping
IDS_Logistics_MouseClicks = []; // Will store our mouse event handlers

if (isnil "IDS_LOGISTICS_CAM_PPEFFECTS") then {
	IDS_LOGISTICS_CAM_PPEFFECTS = [
		[1, 1, -0.01, [1.0, 0.6, 0.0, 0.005], [1.0, 0.96, 0.66, 0.55], [0.95, 0.95, 0.95, 0.0]],
		[1, 1.02, -0.005, [0.0, 0.0, 0.0, 0.0], [1, 0.8, 0.6, 0.65],  [0.199, 0.587, 0.114, 0.0]],
		[1, 1.15, 0, [0.0, 0.0, 0.0, 0.0], [0.5, 0.8, 1, 0.5],  [0.199, 0.587, 0.114, 0.0]],
		[1, 1.06, -0.01, [0.0, 0.0, 0.0, 0.0], [0.44, 0.26, 0.078, 0],  [0.199, 0.587, 0.114, 0.0]]
	];
};

// ---- CAMERA INITIALIZATION ----

//--- Use provided object or default to player's vehicle
if (typeName _this != typeName objNull) then {_this = cameraOn};

//--- Ensure simulation runs at minimum speed (camera needs time to advance)
setAccTime (accTime max (1 / 128));

private _ppos = getPosATL _this;
private _pX = _ppos select 0;
private _pY = _ppos select 1;
private _pZ = _ppos select 2;

//--- Adjust height if below sea level
private _pHeight = getTerrainHeightASL [_pX, _pY];
if (_pHeight < 0) then {_pZ = _pZ + _pHeight};

//--- Create camera slightly above target
private _local = "camera" camCreate [_pX, _pY, _pZ + 2];

IDS_LOGISTICS_CAM = _local;
_local camCommand "MANUAL ON";      // Allow manual control
_local camCommand "INERTIA OFF";    // Disable camera movement inertia 
_local cameraEffect ["INTERNAL", "BACK"];
showCinemaBorder false;              // Hide cinema borders
IDS_LOGISTICS_CAM setDir direction (vehicle player);

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
        
        // Debug message for camera position and direction
        diag_log format ["Camera Pos: %1, Dir: %2, Target: %3", _camPos, _camDir, _targetPos];
        
        // Method 1: lineIntersectsSurfaces with the fixed direction
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
            diag_log format ["Found object: %1 at pos %2", _centerObj, _intersectPos];
        };
        
        // SHIFT + Left click = Delete entity under center of screen
        if (_shift) then {
            if (!isNull _centerObj) then {
                private _isPlaced = _centerObj getVariable ["IDS_Logistics_isPlacedEntity", false];
                private _type = typeOf _centerObj;
                
                if (_isPlaced) then {
                    deleteVehicle _centerObj;
                    ["Entity removed: " + _type, 2] call IDS_Logistics_fnc_cameraHint;
                } else {
                    ["Found object but not placeable: " + _type, 2] call IDS_Logistics_fnc_cameraHint;
                };
            } else {
                ["No object found at center of screen", 2] call IDS_Logistics_fnc_cameraHint;
            };
        } else {
            // Normal left click - place or pick up entity
            if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
                [] call IDS_Logistics_fnc_placeEntity;
            } else {
                // Check if looking at a placed entity to pick it up
                if (!isNull _centerObj && {_centerObj getVariable ["IDS_Logistics_isPlacedEntity", false]}) then {
                    [_centerObj] call IDS_Logistics_fnc_pickupEntity;
                };
            };
        };
        true; // Return true to indicate we handled this event
    };
    
    false; // Return false for other buttons to let them pass through
}]);

// ---- KEY BINDINGS SETUP ----

//--- Key Down handler
_keyDown = (findDisplay 46) displayAddEventHandler ["keydown","
	params ['_displayOrControl', '_key', '_shift', '_ctrl', '_alt'];

	if (_key in (actionkeys 'nightvision')) then {
		IDS_LOGISTICS_CAM_VISION = IDS_LOGISTICS_CAM_VISION + 1;
		if (IDS_LOGISTICS_BUILD_CAM_ISFLIR) then {
			_vision = IDS_LOGISTICS_CAM_VISION % 4;
			switch (_vision) do {
				case 0: {
					camUseNVG false;
					call compile 'false SetCamUseTi 0';
					['Normal Vision', 2] call IDS_Logistics_fnc_cameraHint;
				};
				case 1: {
					camUseNVG true;
					call compile 'false SetCamUseTi 0';
					['Night Vision', 2] call IDS_Logistics_fnc_cameraHint;
				};
				case 2: {
					camUseNVG false;
					call compile 'true SetCamUseTi 0';
					['Thermal - White Hot', 2] call IDS_Logistics_fnc_cameraHint;
				};
				case 3: {
					camUseNVG false;
					call compile 'true SetCamUseTi 1';
					['Thermal - Black Hot', 2] call IDS_Logistics_fnc_cameraHint;
				};
			};
		} else {
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
	};

	if (_key == 83 && !isNil 'IDS_LOGISTICS_CAM_LASTPOS') then {
		IDS_LOGISTICS_CAM setPos IDS_LOGISTICS_CAM_LASTPOS;
	};

    if (_key == 48) then {
        [] call IDS_Logistics_fnc_openBuildMenu;
    };

    if (_key == 35) then {
        if (IDS_LOGISTICS_HINT_VISIBLE) then {
            IDS_LOGISTICS_CAM_HINT_LAYER cutFadeOut 0.5;
            IDS_LOGISTICS_HINT_VISIBLE = false;
            ['Help hidden. Press H to show again.', 2] call IDS_Logistics_fnc_cameraHint;
        } else {
            [IDS_LOGISTICS_TOGGLEABLE_HINT, 0] call IDS_Logistics_fnc_cameraHint;
            IDS_LOGISTICS_HINT_VISIBLE = true;
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
"];

// ---- CAMERA CLEANUP HANDLER ----

//--- Wait until destroy is forced or camera auto-destroyed
[_local, _keyDown] spawn {
	private ["_local", "_keyDown", "_lastpos"];

	_local = _this select 0;
	_keyDown = _this select 1;

	waitUntil {
		if (!isNull IDS_LOGISTICS_CAM) then { _lastpos = position IDS_LOGISTICS_CAM };
		isNull IDS_LOGISTICS_CAM
	};

	player cameraEffect ["TERMINATE", "BACK"];

	IDS_LOGISTICS_CAM = nil;
	IDS_LOGISTICS_CAM_VISION = nil;
	IDS_LOGISTICS_HINT_VISIBLE = nil;
    IDS_LOGISTICS_TOGGLEABLE_HINT = nil;

	camDestroy _local;
	IDS_LOGISTICS_CAM_LASTPOS = _lastpos;

	ppEffectDestroy IDS_LOGISTICS_CAM_COLOR;
	(findDisplay 46) displayRemoveEventHandler ["keydown", _keyDown];
};