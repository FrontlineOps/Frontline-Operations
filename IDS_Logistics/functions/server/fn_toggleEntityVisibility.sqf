/**
 * @name IDS_Logistics_fnc_toggleEntityVisibility
 * @category Logistics_Server
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Server-side function to hide or show an entity during manipulation.
 * Used when an entity is being picked up or placement is cancelled.
 *
 * @param {String} _netId - The netId of the entity to manipulate
 * @param {Boolean} _hide - True to hide entity, false to show
 *
 * @return {Nothing}
 */

params [
    ["_netId", "", [""]],
    ["_hide", true, [true]]
];

if (_netId == "") exitWith { diag_log "IDS Logistics Error: Attempted to toggle visibility with empty netId"; };

// Find entity by netId
private _entity = objectFromNetId _netId;

if (isNull _entity) exitWith { diag_log format ["IDS Logistics Error: Entity with netId %1 not found", _netId]; };

if (_hide) then {
    // Just hide it, don't delete (keeps all the entity properties intact)
    [_entity, true] remoteExecCall ["hideObject", 0, true];
    [_entity, false] remoteExecCall ["enableSimulationGlobal", 0, true];
} else {
    // Restore visibility
    [_entity, false] remoteExecCall ["hideObject", 0, true];
    [_entity, true] remoteExecCall ["enableSimulationGlobal", 0, true];
};