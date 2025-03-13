/**
 * @name IDS_Logistics_fnc_startPlacement
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.3
 * @date 2025-03-10
 * 
 * @description
 * Initiates the placement process for a new entity.
 * Camera-based building system only - player-based functionality removed.
 * The entity follows the camera view for positioning.
 *
 * @param {String} _className - The class name of the entity to place
 *
 * @return {Nothing}
 *
 * @example
 * ["Land_BagFence_Long_F"] call IDS_Logistics_fnc_startPlacement
 */

params [
    ["_className", "", [""]]
];

// Debug log
diag_log format ["Starting placement for entity: %1", _className];

// Validate inputs and state
if (_className == "") exitWith { 
    ["<t color='#FF4444'>ERROR</t><br/>No entity class specified.", 2] call IDS_Logistics_fnc_cameraHint; 
};

if (IDS_Logistics_isHolding) exitWith { 
    ["<t color='#FFAA44'>NOTICE</t><br/>You are already placing an entity.", 2] call IDS_Logistics_fnc_cameraHint; 
};

// Ensure camera mode is active
if (isNil "IDS_LOGISTICS_CAM" || { isNull IDS_LOGISTICS_CAM }) exitWith {
    diag_log "IDS_Logistics: Camera not active, placement canceled";
    hint "Camera mode is required for building. Activate camera first.";
};

// Get entity configuration
private _entityConfig = [_className] call IDS_Logistics_fnc_getEntityConfig;
if (count _entityConfig == 0) exitWith {
    ["<t color='#FF4444'>ERROR</t><br/>Entity '" + _className + "' not found in configuration.", 2] call IDS_Logistics_fnc_cameraHint;
};

// Create the entity locally (preview only)
private _entity = createVehicleLocal [_className, [0,0,0], [], 0, "CAN_COLLIDE"];

// Disable simulation and collision
_entity enableSimulationGlobal false;
[player, _entity] remoteExecCall ["disableCollisionWith", 0, true]; // JIP compatible

// Set holding state
IDS_Logistics_isHolding = true;
IDS_Logistics_currentEntity = _entity;

// Initialize placement variables
IDS_Logistics_entityHeight = 0; // Initial height offset
IDS_Logistics_entityRotation = 0; // Additional rotation offset from reference direction
IDS_Logistics_entityDistance = 5; // Initial distance from reference (in meters)

// Initial placement using the update function
[] call IDS_Logistics_fnc_updateEntityPlacement;

// Add EachFrame event handler for continuous update
IDS_Logistics_dirUpdateEH = addMissionEventHandler ["EachFrame", {
    if (IDS_Logistics_isHolding && !isNull IDS_Logistics_currentEntity) then {
        [] call IDS_Logistics_fnc_updateEntityPlacement;
    };
}];

// Add scroll wheel handler for height/rotation/distance adjustment
IDS_Logistics_scrollHandler = (findDisplay 46) displayAddEventHandler ["MouseZChanged", {
    params ["_display", "_scroll"];
    
    if (!IDS_Logistics_isHolding || isNull IDS_Logistics_currentEntity) exitWith {};
    
    private _shift = uiNamespace getVariable ["IDS_Logistics_shiftPressed", false];
    private _ctrl = uiNamespace getVariable ["IDS_Logistics_ctrlPressed", false];
    private _alt = uiNamespace getVariable ["IDS_Logistics_altPressed", false];
    
    if (_shift) then {
        // Shift + Scroll = Additional Rotation
        IDS_Logistics_entityRotation = IDS_Logistics_entityRotation + (_scroll * 5); // 5 degrees per scroll tick
        
        // Keep rotation in 0-360 range
        if (IDS_Logistics_entityRotation < 0) then { IDS_Logistics_entityRotation = IDS_Logistics_entityRotation + 360; };
        if (IDS_Logistics_entityRotation >= 360) then { IDS_Logistics_entityRotation = IDS_Logistics_entityRotation - 360; };
        
        // Update UI
        private _camDir = getCameraViewDirection IDS_LOGISTICS_CAM;
        private _refDir = (_camDir select 0) atan2 (_camDir select 1);
        if (_refDir < 0) then { _refDir = _refDir + 360; };
        
        private _finalDir = (_refDir + IDS_Logistics_entityRotation) % 360;
        private _message = format ["<t color='#44AAFF' size='1.0'>ROTATION</t><br/><t align='left'>Camera Direction: <t color='#FFFFFF'>%1°</t><br/>Rotation Offset: <t color='#FFFFFF'>%2°</t><br/>Final Direction: <t color='#FFFFFF'>%3°</t></t>", 
                          round _refDir, round IDS_Logistics_entityRotation, round _finalDir];
        
        [_message, 1] call IDS_Logistics_fnc_cameraHint;
    } else {
        if (_ctrl) then {
            // Ctrl + Scroll = Height
            IDS_Logistics_entityHeight = IDS_Logistics_entityHeight + (_scroll * 0.1); // 0.1 meter per scroll tick
            
            // Update UI
            private _message = format ["<t color='#44FF44' size='1.0'>HEIGHT</t><br/><t align='left'>Current Value: <t color='#FFFFFF'>%1m</t></t>", 
                                     (round(IDS_Logistics_entityHeight * 10))/10];
            [_message, 1] call IDS_Logistics_fnc_cameraHint;
        } else {
            if (_alt) then {
                // Alt + Scroll = Distance
                IDS_Logistics_entityDistance = IDS_Logistics_entityDistance + (_scroll * 0.5); // 0.5 meter per scroll tick
                
                // Limit distance between 1 and 10 meters
                IDS_Logistics_entityDistance = (IDS_Logistics_entityDistance max 1) min 10;
                
                // Update UI
                private _message = format ["<t color='#FFAA44' size='1.0'>DISTANCE</t><br/><t align='left'>Current Value: <t color='#FFFFFF'>%1m</t></t>", 
                                         (round(IDS_Logistics_entityDistance * 10))/10];
                [_message, 1] call IDS_Logistics_fnc_cameraHint;
            };
        };
    }
}];

// Track key states
IDS_Logistics_keyDownHandler = (findDisplay 46) displayAddEventHandler ["KeyDown", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];
    
    if (_key == 42 || _key == 54) then { uiNamespace setVariable ["IDS_Logistics_shiftPressed", true]; };
    if (_key == 29 || _key == 157) then { uiNamespace setVariable ["IDS_Logistics_ctrlPressed", true]; };
    if (_key == 56 || _key == 184) then { uiNamespace setVariable ["IDS_Logistics_altPressed", true]; };
    
    // Add ESC key handler for cancellation
    if (_key == 1 && IDS_Logistics_isHolding) then {
        if (!isNull IDS_Logistics_currentEntity) then {
            deleteVehicle IDS_Logistics_currentEntity;
        };
        
        // Remove event handlers
        (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler];
        (findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler];
        (findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler];
        removeMissionEventHandler ["EachFrame", IDS_Logistics_dirUpdateEH];
        
        IDS_Logistics_isHolding = false;
        IDS_Logistics_currentEntity = objNull;
        
        // Provide feedback
        ["<t color='#FF8844' size='1.0'>CANCELLED</t><br/>Placement aborted", 2] call IDS_Logistics_fnc_cameraHint;
        
        true // Handled
    } else {
        false // Not handled
    };
}];

IDS_Logistics_keyUpHandler = (findDisplay 46) displayAddEventHandler ["KeyUp", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];
    
    if (_key == 42 || _key == 54) then { uiNamespace setVariable ["IDS_Logistics_shiftPressed", false]; };
    if (_key == 29 || _key == 157) then { uiNamespace setVariable ["IDS_Logistics_ctrlPressed", false]; };
    if (_key == 56 || _key == 184) then { uiNamespace setVariable ["IDS_Logistics_altPressed", false]; };
    
    false
}];