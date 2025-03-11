/**
 * @name IDS_Logistics_fnc_updateEntityPlacement
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Updates the position and rotation of the currently held entity
 * based on player position, direction, and placement settings.
 * Used during both initial placement and repositioning workflows.
 *
 * @param {None} - Uses global variables for entity state and positioning
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_updateEntityPlacement
 */

if (!IDS_Logistics_isHolding || isNull IDS_Logistics_currentEntity) exitWith {};

// Calculate base height
private _baseHeight = ((boundingBoxReal IDS_Logistics_currentEntity) select 1 select 2) - ((boundingBoxReal IDS_Logistics_currentEntity) select 0 select 2);

// Get player's position and direction vector
private _playerPos = getPosASL player;
private _playerDir = getDir player;

// Calculate the offset position based on player's direction and the distance
private _relPos = [sin(_playerDir) * IDS_Logistics_entityDistance, cos(_playerDir) * IDS_Logistics_entityDistance, 0];

// Calculate final position
private _finalPos = [
    (_playerPos select 0) + (_relPos select 0),
    (_playerPos select 1) + (_relPos select 1),
    (_playerPos select 2) + (_baseHeight / 2) + IDS_Logistics_entityHeight
];

// Calculate final direction (player direction + rotation offset)
private _finalDir = (_playerDir + IDS_Logistics_entityRotation) % 360;

// Update entity position and rotation
IDS_Logistics_currentEntity setPosASL _finalPos;
IDS_Logistics_currentEntity setDir _finalDir;