/**
 * @name IDS_Logistics_fnc_startPlacement
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Initiates the placement process for a new entity.
 * Creates a local preview entity and sets up interactive controls for
 * positioning, rotating, and adjusting height before final placement.
 * This function is typically called from the build menu when selecting an item.
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
if (_className == "") exitWith { hint "Error: No entity class specified."; };
if (IDS_Logistics_isHolding) exitWith { hint "You are already placing an entity."; };

// Get entity configuration
private _entityConfig = [_className] call IDS_Logistics_fnc_getEntityConfig;
if (count _entityConfig == 0) exitWith {
    hint format ["Error: Entity '%1' not found in configuration.", _className];
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
IDS_Logistics_entityRotation = 0; // Additional rotation offset from player direction
IDS_Logistics_entityDistance = 5; // Initial distance from player (in meters)

// Attach to player with initial offset
private _baseHeight = ((boundingBoxReal _entity) select 1 select 2) - ((boundingBoxReal _entity) select 0 select 2);
_entity attachTo [player, [0, IDS_Logistics_entityDistance, (_baseHeight / 2) + IDS_Logistics_entityHeight]];

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
        private _playerDir = getDir player;
        private _finalDir = (_playerDir + IDS_Logistics_entityRotation) % 360;

        hintSilent format ["Player Direction: %1°\nRotation Offset: %2°\nFinal Direction: %3°", round _playerDir, round IDS_Logistics_entityRotation, round _finalDir];
    } else {
        if (_ctrl) then {
            // Ctrl + Scroll = Height
            IDS_Logistics_entityHeight = IDS_Logistics_entityHeight + (_scroll * 0.1); // 0.1 meter per scroll tick
            
            // Update UI
            hintSilent format ["Entity Height: %1m", (round(IDS_Logistics_entityHeight * 10))/10];
        } else {
            if (_alt) then {
                // Alt + Scroll = Distance
                IDS_Logistics_entityDistance = IDS_Logistics_entityDistance + (_scroll * 0.5); // 0.5 meter per scroll tick
                
                // Limit distance between 1 and 10 meters
                IDS_Logistics_entityDistance = (IDS_Logistics_entityDistance max 1) min 10;
                
                // Update UI
                hintSilent format ["Distance from player: %1m", (round(IDS_Logistics_entityDistance * 10))/10];
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
    
    false
}];

IDS_Logistics_keyUpHandler = (findDisplay 46) displayAddEventHandler ["KeyUp", {
    params ["_display", "_key", "_shift", "_ctrl", "_alt"];
    
    if (_key == 42 || _key == 54) then { uiNamespace setVariable ["IDS_Logistics_shiftPressed", false]; };
    if (_key == 29 || _key == 157) then { uiNamespace setVariable ["IDS_Logistics_ctrlPressed", false]; };
    if (_key == 56 || _key == 184) then { uiNamespace setVariable ["IDS_Logistics_altPressed", false]; };
    
    false
}];

// Add action menu options
IDS_Logistics_placeActionId = player addAction ["<t color='#4CAF50'>Place Entity</t>", {
    call IDS_Logistics_fnc_placeEntity;
}, nil, 10, false, true, "", "IDS_Logistics_isHolding"];

IDS_Logistics_cancelActionId = player addAction ["<t color='#FF5252'>Cancel Placement</t>", {
    if (!isNull IDS_Logistics_currentEntity) then {
        deleteVehicle IDS_Logistics_currentEntity;
    };
    
    // Remove event handlers
    (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler];
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler];
    (findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler];
    removeMissionEventHandler ["EachFrame", IDS_Logistics_dirUpdateEH];
    
    player removeAction IDS_Logistics_placeActionId;
    player removeAction IDS_Logistics_cancelActionId;
    
    IDS_Logistics_isHolding = false;
    IDS_Logistics_currentEntity = objNull;
    
    // Clear hint
    hintSilent "";
    hint "Placement cancelled.";
}, nil, 8, false, true, "", "IDS_Logistics_isHolding"];

// Provide user instructions
hint format ["Placing: %1\nThe entity follows your facing direction\nUse CTRL + scroll wheel to adjust height\nUse SHIFT + scroll wheel for fine rotation\nUse ALT + scroll wheel to adjust distance (1-10m)\nUse the actions menu to place or cancel.", _entityConfig select 1];