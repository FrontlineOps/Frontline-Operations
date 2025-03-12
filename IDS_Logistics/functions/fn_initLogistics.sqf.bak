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

// Load configurations directly - not using execVM which is asynchronous
call compile preprocessFileLineNumbers "IDS_Logistics\config\categoryConfig.sqf";
call compile preprocessFileLineNumbers "IDS_Logistics\config\entitiesConfig.sqf";

// Debug logging
diag_log "=== IDS Logistics Initialization ===";
diag_log format ["Loaded %1 building categories", count IDS_Logistics_buildingCategories];
diag_log format ["Loaded %1 buildable entities", count IDS_Logistics_buildableEntities];
diag_log "IDS Logistics initialized.";