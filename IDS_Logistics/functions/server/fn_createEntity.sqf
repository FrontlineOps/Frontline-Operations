/**
 * @name IDS_Logistics_fnc_createEntityServer
 * @category Logistics_Server
 * 
 * @author IDSolutions
 * @version 1.1
 * @date 2025-03-10
 * 
 * @description
 * Server-side function to create a persistent entity.
 * Handles entity creation, tracking, and adds the pickup action.
 *
 * @param {String} _className - Class name of the entity to create
 * @param {Array} _position - ASL position for placement
 * @param {Number} _direction - Direction in degrees
 * @param {Object} _player - Player who created the entity
 *
 * @return {Object} - Created entity
 */

params [
    ["_className", "", [""]],
    ["_position", [0,0,0], [[]]],
    ["_direction", 0, [0]],
    ["_player", objNull, [objNull]]
];

if (_className == "") exitWith {
    diag_log "IDS Logistics Error: Attempted to create entity with empty class name";
    objNull
};

// Create the entity
private _entity = createVehicle [_className, [0,0,0], [], 0, "CAN_COLLIDE"];
_entity setPosASL _position;
_entity setDir _direction;

// Enable physics
_entity enableSimulationGlobal true;
[_player, _entity] remoteExecCall ["enableCollisionWith", 0, true]; // JIP compatible

// Add to tracking array with netID reference
IDS_Logistics_PlacedEntities pushBack _entity;
publicVariable "IDS_Logistics_PlacedEntities";

// Log creation with netID
diag_log format ["IDS Logistics: Entity created - Class: %1, NetID: %2, By: %3", 
    _className, netId _entity, if (isNull _player) then {"Server"} else {name _player}];

// Add pickup action that uses our netID-based system
[
    _entity,
    [
        "<t color='#00BFFF'>Pick Up</t>",
        {
            params ["_target", "_caller"];
            [_target] call IDS_Logistics_fnc_pickupEntity;
        },
        nil,
        1.5,
        true,
        true,
        "",
        "_this distance _target < 5 && !IDS_Logistics_isHolding"
    ]
] remoteExecCall ["addAction", 0, true]; // JIP compatible

// Add event handler for damage/destruction tracking
_entity addEventHandler ["Killed", {
    params ["_entity", "_killer", "_instigator", "_useEffects"];

    // Call server-side function to handle destruction
    [_entity, _killer, _instigator, _useEffects] call IDS_Logistics_fnc_onEntityKilled;
}];

// Return the entity
_entity