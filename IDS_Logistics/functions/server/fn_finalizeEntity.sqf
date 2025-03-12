/**
 * @name IDS_Logistics_fnc_finalizeEntity
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.1
 * @date 2025-03-10
 * 
 * @description
 * Finalizes entity placement on the server. Handles both new entity creation
 * and updating existing entities that have been repositioned.
 *
 * @param {String} _originalNetId - NetId of the original entity (empty if new)
 * @param {String} _className - Class name of the entity
 * @param {Array} _finalPos - Final position as ASL coordinates
 * @param {Number} _finalDir - Final direction/rotation 
 * @param {Array} _vectorUp - Vector up for non-standard orientation
 * @param {Object} _player - Player who placed the entity
 *
 * @return {Nothing}
 *
 * @example
 * [_netId, _className, _finalPos, _finalDir, _vectorUp, player] remoteExec ["IDS_Logistics_fnc_finalizeEntity", 2]
 */

// This function should run on the server only
if (!isServer) exitWith {
    diag_log "IDS_Logistics_fnc_finalizeEntity: Must be executed on server";
};

params [
    ["_originalNetId", "", [""]],
    ["_className", "", [""]],
    ["_finalPos", [0,0,0], [[]]],
    ["_finalDir", 0, [0]],
    ["_vectorUp", [0,0,1], [[]]],
    ["_player", objNull, [objNull]]
];

diag_log format ["IDS_Logistics_fnc_finalizeEntity called: NetID: %1, Class: %2, Pos: %3", _originalNetId, _className, _finalPos];

// Check if this is a reposition of an existing entity
if (_originalNetId != "") then {
    private _existingEntity = objectFromNetId _originalNetId;
    
    if (!isNull _existingEntity) then {
        // Set new position - note: using setPosWorld to ensure precise positioning
        _existingEntity setPosWorld _finalPos;
        _existingEntity setDir _finalDir;
        _existingEntity setVectorUp _vectorUp;
        
        // Re-enable collisions and simulation
        [_player, _existingEntity] remoteExecCall ["enableCollisionWith", 0];
        _existingEntity enableSimulationGlobal true;
        
        // Make entity visible again
        [_originalNetId, false] call IDS_Logistics_fnc_toggleEntityVisibility;
        
        diag_log format ["IDS Logistics: Entity %1 repositioned by %2", _originalNetId, name _player];
    } else {
        diag_log format ["IDS Logistics: Error - Could not find entity with NetID %1", _originalNetId];
    };
} else {
    // Create a new entity
    private _entity = createVehicle [_className, [0,0,0], [], 0, "CAN_COLLIDE"];
    _entity setPosWorld _finalPos;
    _entity setDir _finalDir;
    _entity setVectorUp _vectorUp;
    
    // Mark as a placed entity for future operations
    _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];
    _entity setVariable ["IDS_Logistics_PlacedBy", name _player, true];
    
    diag_log format ["IDS Logistics: New entity %1 created by %2", _className, name _player];
};