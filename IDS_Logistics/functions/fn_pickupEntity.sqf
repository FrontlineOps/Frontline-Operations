/**
 * @name IDS_Logistics_fnc_pickupEntity
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.2
 * @date 2025-03-10
 * 
 * @description
 * Handles entity pickup with improved network handling.
 * Camera-based building system only - player-based functionality removed.
 * Creates a local preview for manipulation before finalizing on the server.
 *
 * @param {Object} _entity - The server-side entity to pick up
 *
 * @return {Nothing}
 *
 * @example
 * [cursorObject] call IDS_Logistics_fnc_pickupEntity
 */

params [["_entity", objNull, [objNull]]];

if (isNull _entity) exitWith {};
if (IDS_Logistics_isHolding) exitWith {
    ["You are already holding an entity.", 2] call IDS_Logistics_fnc_cameraHint;
};

// Ensure camera mode is active
if (isNil "IDS_LOGISTICS_CAM" || { isNull IDS_LOGISTICS_CAM }) exitWith {
    ["Camera mode is not active.", 2] call IDS_Logistics_fnc_cameraHint;
};

// Store entity information before deletion
private _className = typeOf _entity;
private _netId = netId _entity;
private _originalPos = getPosASL _entity;
private _originalDir = getDir _entity;
private _originalVectorUp = vectorUp _entity;

// Tell server to temporarily remove the entity from the global array
[_netId, true] remoteExecCall ["IDS_Logistics_fnc_toggleEntityVisibility", 2];

// Create local preview entity for manipulation
private _localEntity = createVehicleLocal [_className, [0,0,0], [], 0, "CAN_COLLIDE"];
_localEntity setPosASL _originalPos;
_localEntity setDir _originalDir;
_localEntity setVectorUp _originalVectorUp;

// Store the original netId for later server updates
_localEntity setVariable ["IDS_Logistics_OriginalNetId", _netId];

// Disable simulation and collision
_localEntity enableSimulationGlobal false;
[player, _localEntity] remoteExecCall ["disableCollisionWith", 0, true]; // JIP compatible

// Setup holding state
IDS_Logistics_isHolding = true;
IDS_Logistics_currentEntity = _localEntity;

["Entity picked up: " + _className, 2] call IDS_Logistics_fnc_cameraHint;

// Check if using camera mode or player mode
private _useCameraMode = !isNil "IDS_LOGISTICS_CAM" && { !isNull IDS_LOGISTICS_CAM };

// Calculate initial placement variables
if (_useCameraMode) then {
    // Get camera view direction
    private _camDir = getCameraViewDirection IDS_LOGISTICS_CAM;
    private _cameraDir = (_camDir select 0) atan2 (_camDir select 1);

    if (_cameraDir < 0) then { _cameraDir = _cameraDir + 360; };

    // Calculate rotation offset from camera direction
    IDS_Logistics_entityRotation = (_originalDir - _cameraDir) % 360;
    if (IDS_Logistics_entityRotation < 0) then { IDS_Logistics_entityRotation = IDS_Logistics_entityRotation + 360; };

    // Calculate distance from camera to entity
    private _cameraPos = getPosASL IDS_LOGISTICS_CAM;
    private _distanceVector = [
        (_originalPos select 0) - (_cameraPos select 0),
        (_originalPos select 1) - (_cameraPos select 1),
        0 // Ignore vertical distance
    ];
    IDS_Logistics_entityDistance = vectorMagnitude _distanceVector;
    IDS_Logistics_entityDistance = (IDS_Logistics_entityDistance max 1) min 25; // Ensure within valid range

    // Calculate height offset
    private _groundLevel = getTerrainHeightASL [_originalPos select 0, _originalPos select 1];
    IDS_Logistics_entityHeight = (_originalPos select 2) - _groundLevel;
};

// Add EachFrame event handler for continuous update
IDS_Logistics_dirUpdateEH = addMissionEventHandler ["EachFrame", {
    if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
        [] call IDS_Logistics_fnc_updateEntityPlacement;
    };
}];

// Add scroll wheel handler for adjustments
IDS_Logistics_scrollHandler = (findDisplay 46) displayAddEventHandler ["MouseZChanged", {
    params ["_display", "_scroll"];

    if (!IDS_Logistics_isHolding || isNull IDS_Logistics_currentEntity) exitWith {};

    private _shift = uiNamespace getVariable ["IDS_Logistics_shiftPressed", false];
    private _ctrl = uiNamespace getVariable ["IDS_Logistics_ctrlPressed", false];
    private _alt = uiNamespace getVariable ["IDS_Logistics_altPressed", false];

    if (_shift) then {
        // Shift + Scroll = Rotation
        IDS_Logistics_entityRotation = IDS_Logistics_entityRotation + (_scroll * 5);

        if (IDS_Logistics_entityRotation < 0) then { IDS_Logistics_entityRotation = IDS_Logistics_entityRotation + 360; };
        if (IDS_Logistics_entityRotation >= 360) then { IDS_Logistics_entityRotation = IDS_Logistics_entityRotation - 360; };

        // Get reference direction (camera or player)
        private _refDir = 0;
        private _refName = "Player";

        if (!isNil "IDS_LOGISTICS_CAM" && {!isNull IDS_LOGISTICS_CAM}) then {
            private _camDir = getCameraViewDirection IDS_LOGISTICS_CAM;
            _refDir = (_camDir select 0) atan2 (_camDir select 1);

            if (_refDir < 0) then { _refDir = _refDir + 360; };

            _refName = "Camera";
        } else {
            _refDir = getDir player;
        };

        private _finalDir = (_refDir + IDS_Logistics_entityRotation) % 360;
        private _message = format ["<t color='#44AAFF' size='1.0'>ROTATION</t><br/><t align='left'>Camera Direction: <t color='#FFFFFF'>%1°</t><br/>Rotation Offset: <t color='#FFFFFF'>%2°</t><br/>Final Direction: <t color='#FFFFFF'>%3°</t></t>", 
                            round _refDir, round IDS_Logistics_entityRotation, round _finalDir];
        
        [_message, 1] call IDS_Logistics_fnc_cameraHint;
    } else {
        if (_ctrl) then {
            // Ctrl + Scroll = Height
            IDS_Logistics_entityHeight = IDS_Logistics_entityHeight + (_scroll * 0.1);

            // Update UI
            private _message = format ["<t color='#44FF44' size='1.0'>HEIGHT</t><br/><t align='left'>Current Value: <t color='#FFFFFF'>%1m</t></t>", 
                                (round(IDS_Logistics_entityHeight * 10))/10];
            [_message, 1] call IDS_Logistics_fnc_cameraHint;
        } else {
            if (_alt) then {
                // Alt + Scroll = Distance
                IDS_Logistics_entityDistance = IDS_Logistics_entityDistance + (_scroll * 0.5);
                IDS_Logistics_entityDistance = (IDS_Logistics_entityDistance max 1) min 20;

                // Update UI
                private _message = format ["<t color='#FFAA44' size='1.0'>DISTANCE</t><br/><t align='left'>Current Value: <t color='#FFFFFF'>%1m</t></t>", 
                                    (round(IDS_Logistics_entityDistance * 10))/10];
                [_message, 1] call IDS_Logistics_fnc_cameraHint;
            };
        };
    };
}];

// Track key states
IDS_Logistics_keyDownHandler = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];
    if (_key == 42 || _key == 54) then { uiNamespace setVariable ["IDS_Logistics_shiftPressed", true]; };
    if (_key == 29 || _key == 157) then { uiNamespace setVariable ["IDS_Logistics_ctrlPressed", true]; };
    if (_key == 56 || _key == 184) then { uiNamespace setVariable ["IDS_Logistics_altPressed", true]; };

    false
}];

IDS_Logistics_keyUpHandler = (findDisplay 46) displayAddEventHandler ["KeyUp", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];

    if (_key == 42 || _key == 54) then { uiNamespace setVariable ["IDS_Logistics_shiftPressed", false]; };
    if (_key == 29 || _key == 157) then { uiNamespace setVariable ["IDS_Logistics_ctrlPressed", false]; };
    if (_key == 56 || _key == 184) then { uiNamespace setVariable ["IDS_Logistics_altPressed", false]; };

    false
}];