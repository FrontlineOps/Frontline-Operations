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
 * Can also fetch directly from the config if needed.
 *
 * @param {String} _className - The class name of the entity to look up
 * @param {Boolean} _useConfigDirect - (Optional) Whether to fetch directly from config
 *
 * @return {Array} - Entity configuration array [className, category, cost]
 *                   Empty array if entity not found
 *
 * @example
 * _config = ["Land_BagFence_Long_F"] call IDS_Logistics_fnc_getEntityConfig;
 * _config = ["Land_BagFence_Long_F", true] call IDS_Logistics_fnc_getEntityConfig;
 */

params [
    ["_className", "", [""]],
    ["_useConfigDirect", false, [false]]
];

// Return empty array if no valid class name provided
if (_className == "") exitWith {[]};

// If direct config lookup is requested
if (_useConfigDirect) then {
    private _missionConfig = missionConfigFile >> "CfgLogistics" >> "Entities" >> _className;
    
    if (isClass _missionConfig) then {
        private _category = getText (_missionConfig >> "category");
        private _cost = getNumber (_missionConfig >> "cost");
        
        // Return in the same format as the array-based lookup
        _entityConfig = [_className, _category, _cost];
    } else {
        _entityConfig = [];
    };
} else {
    // Default to empty configuration
    private _entityConfig = [];

    // Search for matching entity in buildable entities array
    {
        if (_x select 0 == _className) exitWith { _entityConfig = _x; };
    } forEach IDS_Logistics_Entities;
    
    // Return the configuration (will be empty array if not found)
    _entityConfig
};