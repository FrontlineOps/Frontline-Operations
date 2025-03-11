/**
 * @name IDS_Logistics_fnc_finalizeEntity
 * @category Logistics_Server
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Server-side function to update or create an entity after placement.
 * Uses netId to determine if this is a repositioning or new entity.
 *
 * @param {String} _originalNetId - The original netId (empty for new entities)
 * @param {String} _className - Entity class name
 * @param {Array} _position - ASL position [x,y,z]
 * @param {Number} _direction - Direction in degrees
 * @param {Array} _vectorUp - Vector up [x,y,z]
 * @param {Object} _player - Player who placed the entity
 *
 * @return {Nothing}
 */

params [
    ["_originalNetId", "", [""]],
    ["_className", "", [""]],
    ["_position", [0,0,0], [[]]],
    ["_direction", 0, [0]],
    ["_vectorUp", [0,0,1], [[]]],
    ["_player", objNull, [objNull]]
];

if (_className == "") exitWith {
    diag_log "IDS Logistics Error: Empty class name in finalizeEntity";
};

// Check if this is an existing entity or new one
if (_originalNetId != "") then {
    // Find existing entity
    private _entity = objectFromNetId _originalNetId;
    
    if (!isNull _entity) then {
        // Update existing entity
        _entity setPosASL _position;
        _entity setDir _direction;
        _entity setVectorUp _vectorUp;
        _entity hideObject false;
        _entity enableSimulationGlobal true;
        
        // Success log
        diag_log format ["IDS Logistics: Entity %1 repositioned by %2", _originalNetId, name _player];
    } else {
        // Entity not found, create new
        [_className, _position, _direction, _player] call IDS_Logistics_fnc_createEntity;
        diag_log format ["IDS Logistics: Original entity %1 not found, created new", _originalNetId];
    };
} else {
    // Create new entity
    [_className, _position, _direction, _player] call IDS_Logistics_fnc_createEntity;
    diag_log format ["IDS Logistics: New entity %1 created by %2", _className, name _player];
};