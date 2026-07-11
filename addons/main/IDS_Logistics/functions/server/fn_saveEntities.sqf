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
 * Captures class name, position, direction, orientation, and damage for each entity.
 *
 * @param {None}
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_saveEntites
 */

// Create an array for the entities data
private _saveData = [];

{    
    // Create a HashMap for each entity
    private _entityData = createHashMapFromArray [
        ["class", typeOf _x],
        ["position", getPosASL _x],
        ["direction", getDir _x],
        ["vectorUp", vectorUp _x],
        ["damage", damage _x]
    ];

    // Add to entities array
    _saveData pushBack _entityData;
} forEach IDS_Logistics_PlacedEntities;

missionProfileNamespace setVariable ["IDS_Logistics_SavedEntities", _saveData];
saveMissionProfileNamespace;
