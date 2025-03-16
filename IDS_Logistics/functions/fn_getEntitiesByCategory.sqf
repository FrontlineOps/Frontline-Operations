/**
 * @name IDS_Logistics_fnc_getEntitiesByCategory
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-15
 * 
 * @description
 * Retrieves all entities belonging to a specific category.
 * Can work with either the cached entities array or directly from config.
 *
 * @param {String} _category - The category to filter by
 * @param {Boolean} _useConfig - (Optional) Whether to fetch directly from config
 *
 * @return {Array} - Array of entity configurations matching the category
 *
 * @example
 * _fortifications = ["Fortification"] call IDS_Logistics_fnc_getEntitiesByCategory;
 * _fortifications = ["Fortification", true] call IDS_Logistics_fnc_getEntitiesByCategory;
 */

params [
    ["_category", "", [""]],
    ["_useConfig", false, [false]]
];

// Return empty array if no valid category provided
if (_category == "") exitWith {[]};

private _entities = [];

// If direct config lookup is requested
if (_useConfig) then {
    private _missionConfig = missionConfigFile >> "CfgLogistics" >> "Entities";
    
    // Iterate through all entity classes in the config
    for "_i" from 0 to (count _missionConfig - 1) do {
        private _entityClass = _missionConfig select _i;
        
        if (isClass _entityClass) then {
            private _entityCategory = getText (_entityClass >> "category");
            
            // If category matches, add to result array
            if (_entityCategory == _category) then {
                private _className = configName _entityClass;
                private _cost = getNumber (_entityClass >> "cost");
                
                _entities pushBack [_className, _entityCategory, _cost];
            };
        };
    };
} else {
    // Use the cached entities array
    {
        _x params ["_className", "_entityCategory", "_cost"];
        
        // If category matches, add to result array
        if (_entityCategory == _category) then {
            _entities pushBack _x;
        };
    } forEach IDS_Logistics_Entities;
};

// Return the filtered entities array
_entities 