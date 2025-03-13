/**
 * @name IDS_Logistics_fnc_getEntityConfig
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Retrieves configuration data for an entity by its class name.
 * Searches through the global buildable entities array and returns
 * the complete configuration entry for the requested entity.
 *
 * @param {String} _className - The class name of the entity to look up
 *
 * @return {Array} - Entity configuration array [className, displayName, category, subCategory, cost]
 *                   Empty array if entity not found
 *
 * @example
 * _config = ["Land_BagFence_Long_F"] call IDS_Logistics_fnc_getEntityConfig;
 */

params [["_className", "", [""]]];

// Return empty array if no valid class name provided
if (_className == "") exitWith {[]};

// Default to empty configuration
private _entityConfig = [];

// Search for matching entity in buildable entities array
{
    if (_x select 0 == _className) exitWith {
        _entityConfig = _x;
    };
} forEach IDS_Logistics_buildableEntities;

// Return the configuration (will be empty array if not found)
_entityConfig