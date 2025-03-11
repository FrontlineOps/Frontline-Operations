/**
 * @name IDS_Logistics_fnc_saveEntites
 * @category Logistics
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Saves all placed logistics entities to the profileNamespace for persistence.
 * Captures class name, position, direction, and orientation for each entity.
 *
 * @param {None}
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_saveEntites
 */

// Create a HashMap for the entities data
private _saveData = createHashMap;

// Create array for entities
_saveData set ["entities", []];

{
    // Extract entity data
    private _className = typeOf _x;
    private _position = getPosWorld _x;
    private _direction = getDir _x;
    private _vectorUp = vectorUp _x;
    
    // Create a HashMap for each entity
    private _entityData = createHashMap;
    _entityData set ["class", _className];
    _entityData set ["position", _position];
    _entityData set ["direction", _direction];
    _entityData set ["vectorUp", _vectorUp];
    
    // Add to entities array
    (_saveData get "entities") pushBack _entityData;
} forEach IDS_Logistics_PlacedEntities;

// Save to profileNamespace
profileNamespace setVariable ["IDS_Logistics_SavedEntities", _saveData];
saveProfileNamespace;