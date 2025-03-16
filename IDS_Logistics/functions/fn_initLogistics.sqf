/**
 * @name IDS_Logistics_fnc_initLogistics
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Initializes the IDS Logistics system.
 * Sets up global variables used throughout the logistics framework
 * and prepares the system for operation.
 *
 * @param {None}
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_initLogistics
 */

// Initialize the array for tracking placed entities
if (isNil "IDS_Logistics_PlacedEntities") then { IDS_Logistics_PlacedEntities = []; };

// Initialize entity holding state flag
if (isNil "IDS_Logistics_isHolding") then { IDS_Logistics_isHolding = false; };

// Initialize currently manipulated entity reference
if (isNil "IDS_Logistics_currentEntity") then { IDS_Logistics_currentEntity = objNull; };

// Initialize UI variables
uiNamespace setVariable ["IDS_Logistics_shiftPressed", false];
uiNamespace setVariable ["IDS_Logistics_ctrlPressed", false];
uiNamespace setVariable ["IDS_Logistics_altPressed", false];

// Initialize entities array from config
IDS_Logistics_Entities = [];
private _entitiesConfig = missionConfigFile >> "CfgLogistics" >> "Entities";

// Iterate through all entity classes in the config
for "_i" from 0 to (count _entitiesConfig - 1) do {
    private _entityClass = _entitiesConfig select _i;
    
    if (isClass _entityClass) then {
        private _className = configName _entityClass;
        private _category = getText (_entityClass >> "category");
        private _cost = getNumber (_entityClass >> "cost");
        
        // Add to entities array in the same format as before: [className, category, cost]
        IDS_Logistics_Entities pushBack [_className, _category, _cost];
    };
};

// Debug logging
diag_log "=== IDS Logistics Initialization ===";
diag_log format ["Loaded %1 buildable entities", count IDS_Logistics_Entities];
diag_log "IDS Logistics initialized.";