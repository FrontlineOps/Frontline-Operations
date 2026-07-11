/**
 * @name IDS_Logistics_fnc_loadEntities
 * @category Logistics
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Loads all saved logistics entities from the profileNamespace.
 * Recreates entities based on saved class name, position, direction, orientation, and damage.
 *
 * @param {None}
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_loadEntities
 */

// This function should run on the server only
if (!isServer) exitWith {
    diag_log "IDS_Logistics_fnc_loadEntities: Must be executed on server";
};

private _savedData = missionProfileNamespace getVariable ["IDS_Logistics_SavedEntities", []];

// Check if we have any saved data
if (_savedData isEqualTo []) exitWith {
    diag_log "IDS_Logistics_fnc_loadEntities: No saved entities found";
};

// Clear any existing placed entities
{
    deleteVehicle _x;
} forEach (IDS_Logistics_PlacedEntities + []);
IDS_Logistics_PlacedEntities = [];

// Load and recreate entities
{
    private _className = _x getOrDefault ["class", ""];
    private _position = _x getOrDefault ["position", [0,0,0]];
    private _direction = _x getOrDefault ["direction", 0];
    private _vectorUp = _x getOrDefault ["vectorUp", [0,0,1]];
    private _damage = _x getOrDefault ["damage", 0];
    
    // Skip if className is empty
    if (_className != "") then {
        // Create entity
        private _entity = createVehicle [_className, [0,0,0], [], 0, "CAN_COLLIDE"];
        
        // Set position and orientation
        _entity setPosASL _position;
        _entity setDir _direction;
        _entity setVectorUp _vectorUp;
        _entity setDamage _damage;
        
        // Mark as a placed entity
        _entity setVariable ["IDS_Logistics_isPlacedEntity", true, true];
        
        // Get entity configuration and set variables
        private _entityConfig = [_className] call IDS_Logistics_fnc_getEntityConfig;
        _entityConfig params ["_entityClassName", "_entityCategory", "_entityCost"];
        _entity setVariable ["IDS_Logistics_EntityCost", _entityCost, true];
        
        // Add to placed entities array
        IDS_Logistics_PlacedEntities pushBack _entity;
    };
} forEach _savedData;

diag_log format ["IDS_Logistics_fnc_loadEntities: Loaded %1 entities", count IDS_Logistics_PlacedEntities];
