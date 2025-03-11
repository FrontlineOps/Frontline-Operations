/**
 * @name IDS_Logistics_fnc_onEntityKilled
 * @category Logistics
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Handles cleanup when a logistics entity is destroyed.
 * Removes the entity from the global tracking array.
 *
 * @param {Object} _entity - The entity that was killed
 * @param {Object} _killer - The entity that killed the unit (can be objNull)
 * @param {Object} _instigator - The person who caused the damage (can be objNull)
 * @param {Boolean} _useEffects - True if death effects should be shown
 *
 * @return {Nothing}
 *
 * @example
 * [_damagedEntity, _killer, _instigator, true] call IDS_Logistics_fnc_onEntityKilled
 */

params [
    ["_entity", objNull, [objNull]],
    ["_killer", objNull, [objNull]],
    ["_instigator", objNull, [objNull]],
    ["_useEffects", false, [false]]
];

// Remove from tracking array
IDS_Logistics_PlacedEntities = IDS_Logistics_PlacedEntities - [_entity];

// Delete entity
deleteVehicle _entity;

// Log destruction with netID
diag_log format ["IDS Logistics: Entity destroyed - NetID: %1, By: %2", 
    netId _entity, if (isNull _killer) then {"Unknown"} else {name _killer}];