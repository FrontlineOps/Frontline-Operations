/**
 * @name IDS_Logistics_fnc_placeEntity
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.1
 * @date 2025-03-10
 * 
 * @description
 * Confirms placement of the currently held entity and finalizes it on the server.
 * Works with both new placements and repositioning of existing entities.
 * Handles cleanup of temporary objects, event handlers, and action menu items.
 *
 * @param {None} - Uses globally stored IDS_Logistics_currentEntity
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_placeEntity
 */

// Validate current holding state
if (!IDS_Logistics_isHolding || isNull IDS_Logistics_currentEntity) exitWith { 
    hint "No entity to place."; 
};

// Extract entity properties before deletion
private _entity = IDS_Logistics_currentEntity;
private _className = typeOf _entity;
private _finalPos = getPosASL _entity;
private _finalDir = getDir _entity;
private _vectorUp = vectorUp _entity;

// Get original netId if this was a picked-up entity
private _originalNetId = _entity getVariable ["IDS_Logistics_OriginalNetId", ""];

// Remove the local preview entity
deleteVehicle _entity;

// Finalize entity on the server - works for both new and existing entities
[_originalNetId, _className, _finalPos, _finalDir, _vectorUp, player] remoteExecCall ["IDS_Logistics_fnc_finalizeEntity", 2];

// Clean up event handlers
(findDisplay 46) displayRemoveEventHandler ["MouseZChanged", IDS_Logistics_scrollHandler];
(findDisplay 46) displayRemoveEventHandler ["KeyDown", IDS_Logistics_keyDownHandler];
(findDisplay 46) displayRemoveEventHandler ["KeyUp", IDS_Logistics_keyUpHandler];
removeMissionEventHandler ["EachFrame", IDS_Logistics_dirUpdateEH];

// Remove action menu items
player removeAction IDS_Logistics_placeActionId;
player removeAction IDS_Logistics_cancelActionId;

// Reset global state variables
IDS_Logistics_isHolding = false;
IDS_Logistics_currentEntity = objNull;

// Provide user feedback
hintSilent "";
hint "Entity placed.";