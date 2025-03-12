/**
 * @name IDS_Logistics_fnc_pickupEntity
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.1
 * @date 2025-03-10
 * 
 * @description
 * Handles entity pickup with improved network handling.
 * Deletes the server-side entity and creates a local preview for manipulation,
 * avoiding network ownership and synchronization issues.
 *
 * @param {Object} _entity - The server-side entity to pick up
 *
 * @return {Nothing}
 *
 * @example
 * [cursorObject] call IDS_Logistics_fnc_pickupEntity
 */

params [
    ["_entity", objNull, [objNull]]
];

if (isNull _entity) exitWith {};
if (IDS_Logistics_isHolding) exitWith { hint "You are already holding an entity."; };

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

// Setup holding state
IDS_Logistics_isHolding = true;
IDS_Logistics_currentEntity = _localEntity;

// Get current player direction
private _playerDir = getDir player;

// Calculate rotation offset from player direction
IDS_Logistics_entityHeight = 0; 
IDS_Logistics_entityRotation = (_originalDir - _playerDir) % 360;
IDS_Logistics_entityDistance = 5; 

// Ensure rotation is in 0-360 range
if (IDS_Logistics_entityRotation < 0) then { IDS_Logistics_entityRotation = IDS_Logistics_entityRotation + 360; };

// Perform one-time height check to ensure player is grounded
private _playerPos = getPosASL player;
private _groundLevel = getTerrainHeightASL [_playerPos select 0, _playerPos select 1];
private _heightAboveGround = (_playerPos select 2) - _groundLevel;

if (_heightAboveGround > 1.5) then {
    player setPosASL [_playerPos select 0, _playerPos select 1, _groundLevel + 0.1];
};

// Disable physics
_localEntity enableSimulationGlobal false;
[player, _localEntity] remoteExecCall ["disableCollisionWith", 0, player];

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
        
        private _playerDir = getDir player;
        private _finalDir = (_playerDir + IDS_Logistics_entityRotation) % 360;
        hintSilent format ["Player Direction: %1°\nRotation Offset: %2°\nFinal Direction: %3°", round _playerDir, round IDS_Logistics_entityRotation, round _finalDir];
    } else {
        if (_ctrl) then {
            // Ctrl + Scroll = Height
            IDS_Logistics_entityHeight = IDS_Logistics_entityHeight + (_scroll * 0.1);
            hintSilent format ["Entity Height: %1m", (round(IDS_Logistics_entityHeight * 10))/10];
        } else {
            if (_alt) then {
                // Alt + Scroll = Distance
                IDS_Logistics_entityDistance = IDS_Logistics_entityDistance + (_scroll * 0.5);
                IDS_Logistics_entityDistance = (IDS_Logistics_entityDistance max 1) min 10;
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

// Add placement/cancel actions
IDS_Logistics_placeActionId = player addAction ["<t color='#4CAF50'>Place Entity</t>", {
    private _entity = IDS_Logistics_currentEntity;
    private _originalNetId = _entity getVariable ["IDS_Logistics_OriginalNetId", ""];
    private _className = typeOf _entity;
    private _finalPos = getPosASL _entity;
    private _finalDir = getDir _entity;
    private _vectorUp = vectorUp _entity;
    
    // Clean up local entity
    deleteVehicle _entity;

    // Tell server to restore original entity
    [_originalNetId, false] remoteExecCall ["IDS_Logistics_fnc_toggleEntityVisibility", 2];
    
    // Tell server to update or create entity
    [_originalNetId, _className, _finalPos, _finalDir, _vectorUp, player] remoteExecCall ["IDS_Logistics_fnc_finalizeEntity", 2];
    
    // Clean up event handlers
    (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler];
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler];
    (findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler];
    removeMissionEventHandler ["EachFrame", IDS_Logistics_dirUpdateEH];
    
    player removeAction IDS_Logistics_placeActionId;
    player removeAction IDS_Logistics_cancelActionId;
    
    IDS_Logistics_isHolding = false;
    IDS_Logistics_currentEntity = objNull;
    
    hintSilent "";
    hint "Entity placed.";
}, nil, 10, false, true, "", "IDS_Logistics_isHolding"];

IDS_Logistics_cancelActionId = player addAction ["<t color='#FF5252'>Cancel Placement</t>", {
    private _entity = IDS_Logistics_currentEntity;
    private _originalNetId = _entity getVariable ["IDS_Logistics_OriginalNetId", ""];
    
    // Clean up local entity
    deleteVehicle _entity;
    
    // Tell server to restore original entity
    [_originalNetId, false] remoteExecCall ["IDS_Logistics_fnc_toggleEntityVisibility", 2];
    
    // Clean up event handlers
    (findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler];
    (findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler];
    (findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler];
    removeMissionEventHandler ["EachFrame", IDS_Logistics_dirUpdateEH];
    
    player removeAction IDS_Logistics_placeActionId;
    player removeAction IDS_Logistics_cancelActionId;
    
    IDS_Logistics_isHolding = false;
    IDS_Logistics_currentEntity = objNull;
    
    hintSilent "";
    hint "Placement cancelled.";
}, nil, 8, false, true, "", "IDS_Logistics_isHolding"];

hint "Entity picked up. The entity follows your facing direction.\nUse CTRL + scroll wheel to adjust height\nUse SHIFT + scroll wheel for fine rotation\nUse ALT + scroll wheel to adjust distance (1-10m)\nUse the actions menu to place or cancel.";